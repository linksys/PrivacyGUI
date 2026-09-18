import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/mode/app_mode.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/session/services/session_service.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_subscription_registry.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/framework/mode/credential_strategy.dart';
import 'package:privacy_gui/framework/mode/proximity_strategy.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/framework/mode/session_entry.dart';
import 'package:privacy_gui/framework/mode/session_request.dart';
import 'package:privacy_gui/framework/mode/session_strategy.dart';
import 'package:privacy_gui/framework/mode/transport_strategy.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUspAuthCoordinator extends Mock implements UspAuthCoordinator {}

class MockSseManager extends Mock implements SseManager {}

class MockSseSubscriptionRegistry extends Mock
    implements SseSubscriptionRegistry {}

class MockRouterFingerprintService extends Mock
    implements RouterFingerprintService {}

class MockSessionService extends Mock implements SessionService {}

class MockUspClient extends Mock implements UspClient {}

/// Records what `logout()` asked cause 3 for, and lets a test inject a failure.
///
/// Hand-written rather than a mocktail mock because the interesting assertion is
/// an *ordering* one — see 'runs the strategy BEFORE the credential is
/// invalidated' — and interleaving `verifyInOrder` across a mock and three other
/// mocks' `thenAnswer` side effects is harder to read than one shared list.
class _SpySessionStrategy implements SessionStrategy {
  final calls = <EndCause>[];
  void Function()? onEnd;

  @override
  SessionOutcome get destination => SessionOutcome.loginPage;

  @override
  Future<void> end(Ref ref, EndCause cause) async {
    calls.add(cause);
    onEnd?.call();
  }

  // The entry half of cause 3, added in #1474 phase 9. Throwing rather than
  // recording, for the same reason `_SpyModeProfile` throws for the other three
  // causes: these tests are about `logout()`, and ending a session must not reach
  // for the way *into* one. The `localLogin` group below deliberately does not
  // install this profile — it runs the real `LocalSessionStrategy` against
  // overridden services, which is what makes it the test that `start()` did not
  // change local behaviour.
  @override
  Future<void> start(Ref ref, SessionRequest request) =>
      throw StateError('logout() must not open a session');

  @override
  SessionEntry entryPoint(Ref ref, Uri location) =>
      throw StateError('logout() must not resolve a session entry point');

  @override
  SessionEntry guardEntry(Ref ref) =>
      throw StateError('logout() must not guard a session entry');
}

/// A profile that answers cause 3 with the spy and throws for the other three.
///
/// Throwing rather than returning the local strategies is the point: it asserts
/// that `logout()` reads *only* `session`. A profile that quietly handed back real
/// strategies would let a future edit reach `credential` or `transport` from here
/// with no test noticing — and cause 2's members in particular
/// (`reestablishAfterOutage`) belong to recovery, not to ending a session.
class _SpyModeProfile implements AppModeProfile {
  const _SpyModeProfile({required this.session});

  @override
  final SessionStrategy session;

  @override
  AppMode get mode => AppMode.local;

  @override
  TransportStrategy get transport =>
      throw StateError('logout() must not consult cause 1');

  @override
  CredentialStrategy get credential =>
      throw StateError('logout() must not consult cause 2');

  @override
  ProximityStrategy get proximity =>
      throw StateError('logout() must not consult cause 4');
}

const _testDeviceInfo = NodeDeviceInfo(
  modelNumber: 'M60TB',
  firmwareVersion: '1.0.16',
  description: '',
  firmwareDate: '',
  manufacturer: 'Linksys',
  serialNumber: 'ABC123',
  hardwareVersion: '1.0',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;
  late MockUspAuthCoordinator mockUspCoordinator;
  late MockSseManager mockSseManager;
  late MockSseSubscriptionRegistry mockRegistry;
  late MockRouterFingerprintService mockFingerprint;
  late MockSessionService mockSessionService;
  late MockUspClient mockUspClient;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuthService = MockAuthService();
    mockUspCoordinator = MockUspAuthCoordinator();
    mockSseManager = MockSseManager();
    mockRegistry = MockSseSubscriptionRegistry();
    mockFingerprint = MockRouterFingerprintService();
    mockSessionService = MockSessionService();
    mockUspClient = MockUspClient();

    when(() => mockSseManager.registry).thenReturn(mockRegistry);
    when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
    when(() => mockRegistry.unregisterAll()).thenAnswer((_) async {});
    when(() => mockUspCoordinator.syncAfterLogout()).thenAnswer((_) async {});
    when(() => mockUspCoordinator.restoreSession()).thenAnswer((_) async {});
    when(() => mockFingerprint.clear()).thenAnswer((_) async {});
    when(() => mockFingerprint.store(any())).thenAnswer((_) async {});
    when(() => mockAuthService.clearAllCredentials()).thenAnswer((_) async {});
    when(() => mockSessionService.fetchDeviceInfoAndInitializeServices())
        .thenAnswer((_) async => _testDeviceInfo);
    when(() => mockUspClient.isAuthenticated).thenReturn(false);
  });

  ProviderContainer createContainer({bool isAuthenticated = false}) {
    when(() => mockUspClient.isAuthenticated).thenReturn(isAuthenticated);
    return ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        uspAuthCoordinatorProvider.overrideWithValue(mockUspCoordinator),
        sseManagerProvider.overrideWithValue(mockSseManager),
        routerFingerprintServiceProvider.overrideWithValue(mockFingerprint),
        sessionServiceProvider.overrideWithValue(mockSessionService),
        uspClientProvider.overrideWithValue(mockUspClient),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // build
  // ---------------------------------------------------------------------------

  group('AuthNotifier — build', () {
    test('initial state is empty AuthState', () async {
      final container = createContainer();

      final state = await container.read(authProvider.future);

      expect(state.loginType, LoginType.none);
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // init
  // ---------------------------------------------------------------------------

  group('AuthNotifier — init', () {
    test('restores session and sets LoginType.local when authenticated',
        () async {
      final container = createContainer(isAuthenticated: true);
      container.read(authProvider); // trigger build
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.init();

      final state = container.read(authProvider).value;
      expect(state?.loginType, LoginType.local);
      verify(() => mockUspCoordinator.restoreSession()).called(1);
      container.dispose();
    });

    test('sets LoginType.none when not authenticated', () async {
      final container = createContainer(isAuthenticated: false);
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.init();

      final state = container.read(authProvider).value;
      expect(state?.loginType, LoginType.none);
      container.dispose();
    });

    test('concurrent init calls are coalesced — restoreSession called once',
        () async {
      // Slow restoreSession to ensure concurrent calls overlap
      when(() => mockUspCoordinator.restoreSession())
          .thenAnswer((_) => Future.delayed(const Duration(milliseconds: 50)));

      final container = createContainer(isAuthenticated: true);
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);

      final futures = [
        notifier.init(),
        notifier.init(),
        notifier.init(),
      ];
      await Future.wait(futures);

      // restoreSession should only be called once despite 3 concurrent inits
      verify(() => mockUspCoordinator.restoreSession()).called(1);
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // localLogin
  // ---------------------------------------------------------------------------

  group('AuthNotifier — localLogin', () {
    test('successful login sets state with LoginType.local', () async {
      when(() => mockUspCoordinator.tryUspLogin('pass123'))
          .thenAnswer((_) async => true);

      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.localLogin('pass123');

      final state = container.read(authProvider).value;
      expect(state?.loginType, LoginType.local);
      container.dispose();
    });

    test('successful login fetches device info before setting auth state',
        () async {
      when(() => mockUspCoordinator.tryUspLogin('pass123'))
          .thenAnswer((_) async => true);

      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.localLogin('pass123');

      verify(() => mockSessionService.fetchDeviceInfoAndInitializeServices())
          .called(1);
      container.dispose();
    });

    test('failed USP login sets error state when guardError is true', () async {
      when(() => mockUspCoordinator.tryUspLogin('wrong'))
          .thenThrow(const InvalidCredentialsError());

      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.localLogin('wrong', guardError: true);

      final state = container.read(authProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<UnexpectedError>());
      container.dispose();
    });

    test('failed USP login throws when guardError is false', () async {
      when(() => mockUspCoordinator.tryUspLogin('wrong'))
          .thenThrow(const InvalidCredentialsError());

      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      expect(
        () => notifier.localLogin('wrong', guardError: false),
        throwsA(isA<InvalidCredentialsError>()),
      );
      container.dispose();
    });

    test(
        'account-locked error is passed through to the view as '
        'errorAdminAccountLocked (not overwritten to errorUnexpected)',
        () async {
      when(() => mockUspCoordinator.tryUspLogin('locked')).thenThrow(
          UnexpectedError(
              originalError: Exception('Account is locked'),
              detail: errorAdminAccountLocked));

      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.localLogin('locked', guardError: true);

      final state = container.read(authProvider);
      expect(state.hasError, isTrue);
      final error = state.error;
      expect(error, isA<UnexpectedError>());
      expect((error as UnexpectedError).detail, errorAdminAccountLocked);
      container.dispose();
    });

    test('login does not call fetchDeviceInfo if USP fails', () async {
      when(() => mockUspCoordinator.tryUspLogin('wrong'))
          .thenThrow(const InvalidCredentialsError());

      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.localLogin('wrong');

      verifyNever(
          () => mockSessionService.fetchDeviceInfoAndInitializeServices());
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // logout
  // ---------------------------------------------------------------------------

  group('AuthNotifier — logout', () {
    test('disconnects SSE', () async {
      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.logout();

      verify(() => mockSseManager.disconnect()).called(1);
      container.dispose();
    });

    test('clears credentials', () async {
      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.logout();

      verify(() => mockAuthService.clearAllCredentials()).called(1);
      container.dispose();
    });

    test('sets state to empty AuthState', () async {
      when(() => mockUspCoordinator.tryUspLogin('pass'))
          .thenAnswer((_) async => true);

      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      // Login first
      await notifier.localLogin('pass');
      expect(container.read(authProvider).value?.loginType, LoginType.local);

      // Then logout
      await notifier.logout();

      final state = container.read(authProvider).value;
      expect(state?.loginType, LoginType.none);
      container.dispose();
    });

    test('clears session state', () async {
      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.logout();

      final sessionState = container.read(sessionProvider);
      expect(sessionState.deviceInfo, isNull);
      container.dispose();
    });

    test('performs cleanup (unregisterAll, USP logout, fingerprint)', () async {
      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.logout();

      verify(() => mockRegistry.unregisterAll()).called(1);
      verify(() => mockUspCoordinator.syncAfterLogout()).called(1);
      verify(() => mockFingerprint.clear()).called(1);
      container.dispose();
    });

    test('logout handles null SSE manager gracefully', () async {
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
          uspAuthCoordinatorProvider.overrideWithValue(mockUspCoordinator),
          sseManagerProvider.overrideWithValue(null),
          routerFingerprintServiceProvider.overrideWithValue(mockFingerprint),
          sessionServiceProvider.overrideWithValue(mockSessionService),
          uspClientProvider.overrideWithValue(mockUspClient),
        ],
      );
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.logout();

      // Should not throw, and still clear credentials
      verify(() => mockAuthService.clearAllCredentials()).called(1);
      container.dispose();
    });

    test('cleanup error results in error state', () async {
      when(() => mockUspCoordinator.syncAfterLogout())
          .thenThrow(Exception('network error'));

      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.logout();

      // Error in cleanup propagates via AsyncValue.guard.
      final authState = container.read(authProvider);
      expect(authState.hasError, isTrue);
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // logout — the mode's own teardown (#1323 phase 5)
  // ---------------------------------------------------------------------------

  // WHY THIS GROUP EXISTS AT ALL, given that eleven call sites were "fixed".
  //
  // They were fixed by editing one method. `logout()` was already this app's
  // session teardown funnel — SSE, subscriptions, USP logout, fingerprint,
  // credentials, and two RA prefs under a "legacy cleanup" comment — so the
  // remaining RA teardown belonged here and nowhere else. It was instead in
  // `remote_session_chip.dart`'s Disconnect handler, which is one of the eleven,
  // and the other ten therefore left `remoteAccessProvider` populated for
  // `router_provider.dart`'s `/usp*` guard to find (acceptance 3).
  //
  // So the seam under test is small and load-bearing: does `logout()` reach the
  // strategy, with the right cause, before it invalidates the credential the
  // strategy needs. The six tests above this group are the other half of the
  // claim — they are unedited, they run the *real* local strategy, and they still
  // pass, which is acceptance 8 in the strong form.
  group('AuthNotifier — logout reaches the mode strategy', () {
    late _SpySessionStrategy spy;

    setUp(() => spy = _SpySessionStrategy());

    ProviderContainer containerWithSpy() => ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
            uspAuthCoordinatorProvider.overrideWithValue(mockUspCoordinator),
            sseManagerProvider.overrideWithValue(mockSseManager),
            routerFingerprintServiceProvider.overrideWithValue(mockFingerprint),
            sessionServiceProvider.overrideWithValue(mockSessionService),
            uspClientProvider.overrideWithValue(mockUspClient),
            appModeProfileProvider
                .overrideWithValue(_SpyModeProfile(session: spy)),
          ],
        );

    test('calls SessionStrategy.end exactly once', () async {
      final container = containerWithSpy();
      addTearDown(container.dispose);
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      await container.read(authProvider.notifier).logout();

      expect(spy.calls, hasLength(1));
    });

    test('defaults to sessionLost', () async {
      // 8 of the 11 call sites are automatic, and the failure modes are
      // asymmetric: a missed `endSessionForCA` leaves a Guardian session to expire
      // on its own timer, whereas an *attempted* one on a rejected token is a
      // guaranteed failure on the commonest path. So the default is the safe one
      // and the three button handlers opt in.
      final container = containerWithSpy();
      addTearDown(container.dispose);
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      await container.read(authProvider.notifier).logout();

      expect(spy.calls.single, EndCause.sessionLost);
    });

    test('forwards an explicit userRequested', () async {
      final container = containerWithSpy();
      addTearDown(container.dispose);
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      await container
          .read(authProvider.notifier)
          .logout(cause: EndCause.userRequested);

      expect(spy.calls.single, EndCause.userRequested);
    });

    test('runs the strategy BEFORE the credential is invalidated', () async {
      // The ordering claim, and the one that is easy to get wrong by tidiness:
      // `end()` reads more naturally at the bottom of the method, next to the
      // state assignment. Remotely it would then call `endSessionForCA` with a
      // token `syncAfterLogout()` and `clearAllCredentials()` have already thrown
      // away — a call that can only fail, on the *deliberate* exit path where it
      // is the one thing worth doing.
      final container = containerWithSpy();
      addTearDown(container.dispose);
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final order = <String>[];
      spy.onEnd = () => order.add('end');
      when(() => mockSseManager.disconnect()).thenAnswer((_) async {
        order.add('sse.disconnect');
      });
      when(() => mockUspCoordinator.syncAfterLogout()).thenAnswer((_) async {
        order.add('usp.syncAfterLogout');
      });
      when(() => mockAuthService.clearAllCredentials()).thenAnswer((_) async {
        order.add('clearAllCredentials');
      });

      await container
          .read(authProvider.notifier)
          .logout(cause: EndCause.userRequested);

      expect(order, [
        'end',
        'sse.disconnect',
        'usp.syncAfterLogout',
        'clearAllCredentials',
      ]);
    });

    test(
        'a throwing strategy leaves the credential uncleared — so it must not '
        'throw', () async {
      // Not a requirement on `logout()`; a *demonstration* of why
      // `SessionStrategy.end` is documented as non-throwing and why both
      // implementations wrap their remote calls. `end()` runs inside the existing
      // `AsyncValue.guard`, so a throw short-circuits every subsequent step: the
      // user pressed Logout and stays logged in, with an error state nothing
      // renders. Pinned here so that anyone tempted to let a `ServiceError`
      // propagate out of a strategy sees the consequence spelled out.
      final container = containerWithSpy();
      addTearDown(container.dispose);
      container.read(authProvider);
      await Future.delayed(Duration.zero);
      spy.onEnd = () => throw Exception('Guardian returned 502');

      await container.read(authProvider.notifier).logout();

      expect(container.read(authProvider).hasError, isTrue);
      verifyNever(() => mockAuthService.clearAllCredentials());
    });
  });

  // ---------------------------------------------------------------------------
  // getPasswordHint / getAdminPasswordAuthStatus
  // ---------------------------------------------------------------------------

  group('AuthNotifier — no-op methods', () {
    test('getPasswordHint is a no-op', () async {
      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      await notifier.getPasswordHint();
      // No assertion needed — just verifying it doesn't throw.
      container.dispose();
    });

    test('getAdminPasswordAuthStatus returns null', () async {
      final container = createContainer();
      container.read(authProvider);
      await Future.delayed(Duration.zero);

      final notifier = container.read(authProvider.notifier);
      final result = await notifier.getAdminPasswordAuthStatus();
      expect(result, isNull);
      container.dispose();
    });
  });
}
