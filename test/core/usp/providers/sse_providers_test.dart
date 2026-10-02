import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import '../mocks.dart';

class _MockAuthNotifier extends AsyncNotifier<AuthState>
    with Mock
    implements AuthNotifier {
  @override
  Future<AuthState> build() async => AuthState(loginType: LoginType.remote);
}

void main() {
  late MockUspClient mockUsp;
  late MockUspBridgeClient mockBridge;
  late MockSseManager mockManager;

  setUp(() {
    mockUsp = MockUspClient();
    mockBridge = MockUspBridgeClient();
    mockManager = MockSseManager();
    // #1578: `SseOperationAwaiter`'s constructor registers a reconcile listener on
    // the manager and keeps the remover, so the mock has to hand one back — an
    // unstubbed call returns null and `ref.onDispose` would reject it.
    when(() => mockManager.addStreamOpenedListener(any())).thenReturn(() {});
  });

  /// Creates a container with optional overrides for all three providers.
  ProviderContainer createContainer({
    MockUspClient? usp,
    MockUspBridgeClient? bridge,
    MockSseManager? manager,
  }) {
    return ProviderContainer(
      overrides: [
        uspClientProvider.overrideWithValue(usp),
        uspBridgeClientProvider.overrideWithValue(bridge),
        sseManagerProvider.overrideWithValue(manager),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // sseConnectionStateProvider
  // ---------------------------------------------------------------------------
  group('sseConnectionStateProvider', () {
    test('emits disconnected when manager is null', () async {
      final container = createContainer();

      final sub = container.listen(sseConnectionStateProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      expect(sub.read().value, SseConnectionState.disconnected);
      container.dispose();
    });

    test('emits initial value from ValueNotifier', () async {
      final connection = SseConnectionManager(mockBridge);

      when(() => mockManager.connection).thenReturn(connection);

      final container = createContainer(manager: mockManager);
      final states = <SseConnectionState>[];
      container.listen(sseConnectionStateProvider, (_, next) {
        if (next.hasValue) states.add(next.value!);
      });
      await Future.delayed(Duration.zero);

      expect(states, contains(SseConnectionState.disconnected));

      connection.dispose();
      container.dispose();
    });

    test('emits on connectionState changes via ValueNotifier listener',
        () async {
      final connection = SseConnectionManager(mockBridge);

      when(() => mockManager.connection).thenReturn(connection);

      final container = createContainer(manager: mockManager);
      final states = <SseConnectionState>[];
      container.listen(sseConnectionStateProvider, (_, next) {
        if (next.hasValue) states.add(next.value!);
      });
      await Future.delayed(Duration.zero);

      // Initial state emitted
      expect(states.last, SseConnectionState.disconnected);

      // Change the ValueNotifier value to trigger the listener callback
      connection.connectionState.value = SseConnectionState.connected;
      await Future.delayed(Duration.zero);

      expect(states.last, SseConnectionState.connected);

      connection.dispose();
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // sseOperationAwaiterProvider
  // ---------------------------------------------------------------------------
  group('sseOperationAwaiterProvider', () {
    test('returns null when manager is null', () {
      final container = createContainer(usp: mockUsp);

      expect(container.read(sseOperationAwaiterProvider), isNull);
      container.dispose();
    });

    test('returns null when usp is null', () {
      final container = createContainer(manager: mockManager);

      expect(container.read(sseOperationAwaiterProvider), isNull);
      container.dispose();
    });

    test('returns SseOperationAwaiter when both available', () {
      when(() => mockUsp.onSseSubscribe = any(that: anything)).thenReturn(null);
      when(() => mockUsp.onTokenRefreshed = any(that: anything))
          .thenReturn(null);

      final container = createContainer(
        usp: mockUsp,
        manager: mockManager,
      );

      expect(container.read(sseOperationAwaiterProvider), isNotNull);
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // sseBootstrapProvider
  // ---------------------------------------------------------------------------
  group('sseBootstrapProvider', () {
    test('does nothing when manager is null', () async {
      final container = createContainer(usp: mockUsp, bridge: mockBridge);

      await container.read(sseBootstrapProvider.future);

      verifyNever(() => mockBridge.health());
      container.dispose();
    });

    test('does nothing when usp is null', () async {
      final container = createContainer(
        manager: mockManager,
        bridge: mockBridge,
      );

      await container.read(sseBootstrapProvider.future);

      verifyNever(() => mockBridge.health());
      container.dispose();
    });

    test('does nothing when not authenticated', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);

      final container = createContainer(
        usp: mockUsp,
        manager: mockManager,
        bridge: mockBridge,
      );

      await container.read(sseBootstrapProvider.future);

      verifyNever(() => mockBridge.health());
      container.dispose();
    });

    test('does nothing when bridge is null', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(true);

      final container = createContainer(
        usp: mockUsp,
        manager: mockManager,
      );

      await container.read(sseBootstrapProvider.future);

      verifyNever(() => mockManager.setCoreSubscriptions(any()));
      container.dispose();
    });

    test(
        'happy path: health → connect (subscriptions deferred to orchestrator)',
        () async {
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      when(() => mockBridge.health()).thenAnswer((_) async => {'status': 'ok'});
      when(() => mockManager.connect()).thenAnswer((_) async {});

      final container = createContainer(
        usp: mockUsp,
        manager: mockManager,
        bridge: mockBridge,
      );

      await container.read(sseBootstrapProvider.future);

      verifyInOrder([
        () => mockBridge.health(),
        () => mockManager.connect(),
      ]);
      // setCoreSubscriptions is deferred to dashboard orchestrator
      verifyNever(() => mockManager.setCoreSubscriptions(any()));
      container.dispose();
    });

    test('runs under the REMOTE profile too (#1576)', () async {
      // The deleted gate. Until #1576 this read was wrapped in
      // `if (!GlobalConfig.remote.isActive)`, on the recorded grounds that
      // `BridgeEndpoints.remote()`'s `health` path was invented and Guardian would
      // answer a 404. Guardian's own OpenAPI spec serves it, at exactly that path.
      //
      // Asserted through `appModeProfileProvider` rather than by trusting that the
      // bootstrap no longer mentions the mode: "the `if` is gone" is a claim about
      // source, and this is a claim about behaviour. It fails if the gate comes back
      // in any spelling.
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      when(() => mockBridge.health()).thenAnswer((_) async => {'status': 'ok'});
      when(() => mockManager.connect()).thenAnswer((_) async {});

      final container = ProviderContainer(overrides: [
        appModeProfileProvider.overrideWithValue(const RemoteModeProfile()),
        uspClientProvider.overrideWithValue(mockUsp),
        uspBridgeClientProvider.overrideWithValue(mockBridge),
        sseManagerProvider.overrideWithValue(mockManager),
      ]);

      await container.read(sseBootstrapProvider.future);

      verifyInOrder([
        () => mockBridge.health(),
        () => mockManager.connect(),
      ]);
      container.dispose();
    });

    test(
        'a Remote Assistance session connects although isAuthenticated is false',
        () async {
      // Measured on the real wasm client (2026-10-01): a `UspClient` built with
      // `UspClientBuilder.authToken(...)` answers `isAuthenticated() == false`,
      // because that flag tracks a password login and RA never performs one.
      // Gated on it, the shell's bootstrap returned without connecting in every
      // RA session, and SSE waited for the orchestrator's fallback `connect()`
      // after domain ready and the throttler draining — 26 s on the QA router,
      // all of it with a "Disconnected" banner over a stream that had never been
      // asked to open. Selected through `appModeProfileProvider` alone, because
      // the answer is now `CredentialStrategy.holdsCredential`'s: no login state
      // is involved, and none is overridden.
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockBridge.health()).thenAnswer((_) async => {'status': 'ok'});
      when(() => mockManager.connect()).thenAnswer((_) async {});

      final container = ProviderContainer(overrides: [
        appModeProfileProvider.overrideWithValue(const RemoteModeProfile()),
        uspClientProvider.overrideWithValue(mockUsp),
        uspBridgeClientProvider.overrideWithValue(mockBridge),
        sseManagerProvider.overrideWithValue(mockManager),
      ]);
      addTearDown(container.dispose);

      await container.read(sseBootstrapProvider.future);

      verify(() => mockManager.connect()).called(1);
    });

    test('health check fails → still calls connect', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      when(() => mockBridge.health()).thenThrow(Exception('503'));
      when(() => mockManager.connect()).thenAnswer((_) async {});

      final container = createContainer(
        usp: mockUsp,
        manager: mockManager,
        bridge: mockBridge,
      );

      await container.read(sseBootstrapProvider.future);

      verifyNever(() => mockManager.setCoreSubscriptions(any()));
      verify(() => mockManager.connect()).called(1);
      container.dispose();
    });

    test('health check timeout → still calls connect', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      when(() => mockBridge.health()).thenAnswer(
        (_) => Future.delayed(
          const Duration(seconds: 10),
          () => {'status': 'ok'},
        ),
      );
      when(() => mockManager.connect()).thenAnswer((_) async {});

      final container = createContainer(
        usp: mockUsp,
        manager: mockManager,
        bridge: mockBridge,
      );

      await container.read(sseBootstrapProvider.future);

      verifyNever(() => mockManager.setCoreSubscriptions(any()));
      verify(() => mockManager.connect()).called(1);
      container.dispose();
    });

    test('setCoreSubscriptions not called in bootstrap (deferred)', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      when(() => mockBridge.health()).thenAnswer((_) async => {'status': 'ok'});
      when(() => mockManager.connect()).thenAnswer((_) async {});

      final container = createContainer(
        usp: mockUsp,
        manager: mockManager,
        bridge: mockBridge,
      );

      await container.read(sseBootstrapProvider.future);

      verifyNever(() => mockManager.setCoreSubscriptions(any()));
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // sseManagerProvider — what a 401 does under each profile (#1627)
  // ---------------------------------------------------------------------------
  //
  // The real provider, not an override, on a real `UspClient` over a transport
  // that answers 401: this is the only test that sees the whole chain — the
  // profile's `AuthBehavior` reaching the client, the client's gate, and the
  // gate's `onForceLogout` reaching `authProvider`. The client's own suite pins
  // the gate with the behaviour assigned by hand, so it stays green if nothing
  // in the app ever assigns it.
  group('sseManagerProvider - a 401 under each profile (#1627)', () {
    const path = 'Device.DeviceInfo.SerialNumber';
    late UnauthenticatedTransport transport;
    late UspClient client;
    late _MockAuthNotifier auth;

    setUpAll(() {
      // `logout({EndCause cause = …})` has a default, so `verifyNever` needs
      // `any(named: 'cause')` to match a call that passed one — see
      // recovery_flow_test.dart.
      registerFallbackValue(EndCause.sessionLost);
    });

    setUp(() {
      transport = UnauthenticatedTransport();
      client = UspClient.withTransport(transport);
      auth = _MockAuthNotifier();
      when(() => auth.logout(cause: any(named: 'cause')))
          .thenAnswer((_) async {});
      when(() => mockBridge.abortSse()).thenReturn(null);
    });

    ProviderContainer wire(AppModeProfile profile) {
      final container = ProviderContainer(overrides: [
        appModeProfileProvider.overrideWithValue(profile),
        uspClientProvider.overrideWithValue(client),
        uspBridgeClientProvider.overrideWithValue(mockBridge),
        authProvider.overrideWith(() => auth),
      ]);
      addTearDown(container.dispose);
      expect(container.read(sseManagerProvider), isNotNull);
      return container;
    }

    test('remote: the session ends as a lost one, with no refresh or retry',
        () async {
      wire(const RemoteModeProfile());

      await expectLater(client.get([path]), throwsA(isA<Exception>()));

      verify(() => auth.logout(cause: EndCause.sessionLost)).called(1);
      expect(transport.refreshCalls, 0);
      expect(transport.requests, 1);
    });

    // The client outlives the manager: it is a stable singleton, and a Remote
    // Assistance re-activation disposes the manager before the new one is
    // built. A command that 401s in that gap must still not reach the local
    // reauth, which is why the provider sets the value without resetting it.
    test('remote: the answer outlives the manager that set it', () async {
      wire(const RemoteModeProfile()).dispose();

      await expectLater(client.get([path]), throwsA(isA<Exception>()));

      expect(transport.refreshCalls, 0,
          reason: 'a reset on dispose would put the default, local, back');
      expect(transport.requests, 1);
    });

    test('local: the token is refreshed, the call retried, the session kept',
        () async {
      wire(const LocalModeProfile());

      await client.get([path]);

      verifyNever(() => auth.logout(cause: any(named: 'cause')));
      expect(transport.refreshCalls, 1);
      expect(transport.requests, 2);
    });
  });
}
