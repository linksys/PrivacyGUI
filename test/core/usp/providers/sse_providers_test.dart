import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import '../mocks.dart';

void main() {
  late MockUspService mockUsp;
  late MockUspBridgeClient mockBridge;
  late MockSseManager mockManager;

  setUp(() {
    mockUsp = MockUspService();
    mockBridge = MockUspBridgeClient();
    mockManager = MockSseManager();
  });

  /// Creates a container with optional overrides for all three providers.
  ProviderContainer createContainer({
    MockUspService? usp,
    MockUspBridgeClient? bridge,
    MockSseManager? manager,
  }) {
    return ProviderContainer(
      overrides: [
        uspServiceProvider.overrideWithValue(usp),
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

    test('happy path: health → connect (subscriptions deferred to orchestrator)',
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
}
