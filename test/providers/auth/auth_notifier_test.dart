import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/session/services/session_service.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_subscription_registry.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
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
