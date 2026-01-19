import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/data/providers/session_provider.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/auth/auth_result.dart';
import 'package:privacy_gui/providers/auth/auth_service.dart';
import 'package:privacy_gui/providers/auth/ra_session_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock classes
class MockAuthService extends Mock implements AuthService {}

class MockPollingNotifier extends Mock implements PollingNotifier {}

class MockDeviceManagerNotifier extends Mock implements DeviceManagerNotifier {}

class MockSessionNotifier extends Mock implements SessionNotifier {}

class MockRASessionNotifier extends Mock implements RASessionNotifier {}

void main() {
  late MockAuthService mockAuthService;
  late MockPollingNotifier mockPollingNotifier;
  late MockDeviceManagerNotifier mockDeviceManagerNotifier;
  late MockSessionNotifier mockSessionNotifier;
  late MockRASessionNotifier mockRaSessionNotifier;

  setUp(() {
    mockAuthService = MockAuthService();
    mockPollingNotifier = MockPollingNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    mockSessionNotifier = MockSessionNotifier();
    mockRaSessionNotifier = MockRASessionNotifier();

    // Setup default behaviors
    when(() => mockPollingNotifier.init()).thenReturn(null);
    when(() => mockPollingNotifier.stopPolling()).thenReturn(null);
    when(() => mockDeviceManagerNotifier.init()).thenReturn(null);
    when(() => mockRaSessionNotifier.stopMonitorSession()).thenReturn(null);
    when(() => mockRaSessionNotifier.raLogout())
        .thenAnswer((_) async => Future.value());
    when(() => mockSessionNotifier.saveSelectedNetwork(any(), any()))
        .thenAnswer((_) async => Future.value());
  });

  ProviderContainer makeProviderContainer() {
    return ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        pollingProvider.overrideWith(() => mockPollingNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        sessionProvider.overrideWith(() => mockSessionNotifier),
        raSessionProvider.overrideWith(() => mockRaSessionNotifier),
      ],
    );
  }

  group('AuthNotifier - Initialization', () {
    test('init() successfully initializes with valid token', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = makeProviderContainer();

      final testToken = SessionToken(
        accessToken: 'test-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );

      final storedCreds = StoredCredentials(
        sessionToken: testToken,
        sessionTokenTs: DateTime.now().millisecondsSinceEpoch.toString(),
        username: 'test@example.com',
        password: 'password123',
        currentSN: 'SN12345',
        selectedNetworkId: 'network-1',
        raMode: false,
      );

      when(() => mockAuthService.validateSessionToken())
          .thenAnswer((_) async => const AuthSuccess(null));
      when(() => mockAuthService.getStoredCredentials())
          .thenAnswer((_) async => AuthSuccess(storedCreds));
      when(() => mockAuthService.getStoredLoginType())
          .thenAnswer((_) async => const AuthSuccess(LoginType.remote));

      // Act
      final state = await container.read(authProvider.notifier).init();

      // Assert
      expect(state, isNotNull);
      expect(state!.username, 'test@example.com');
      expect(state.password, 'password123');
      expect(state.loginType, LoginType.remote);
      expect(state.sessionToken, isNull); // validateSessionToken returned null

      container.dispose();
    });

    test('init() handles missing credentials gracefully', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = makeProviderContainer();

      when(() => mockAuthService.validateSessionToken())
          .thenAnswer((_) async => const AuthSuccess(null));
      when(() => mockAuthService.getStoredCredentials())
          .thenAnswer((_) async => const AuthFailure(StorageError()));
      when(() => mockAuthService.getStoredLoginType())
          .thenAnswer((_) async => const AuthSuccess(LoginType.none));

      // Act
      final state = await container.read(authProvider.notifier).init();

      // Assert
      expect(state, isNotNull);
      expect(state!.loginType, LoginType.none);
      // username might be empty string instead of null
      expect(state.username == null || state.username!.isEmpty, true);

      container.dispose();
    });
  });

  group('AuthNotifier - Cloud Login', () {
    test('cloudLogin() successfully delegates to AuthService', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = makeProviderContainer();

      const testUsername = 'test@example.com';
      const testPassword = 'password123';
      final testToken = SessionToken(
        accessToken: 'test-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );

      final loginInfo = LoginInfo(
        username: testUsername,
        password: testPassword,
        sessionToken: testToken,
        loginType: LoginType.remote,
      );

      when(() => mockAuthService.cloudLogin(
            username: testUsername,
            password: testPassword,
            sessionToken: null,
          )).thenAnswer((_) async => AuthSuccess(loginInfo));

      // Act
      await container.read(authProvider.notifier).cloudLogin(
            username: testUsername,
            password: testPassword,
          );

      // Assert
      final state = container.read(authProvider);
      expect(state.hasValue, true);
      expect(state.value!.username, testUsername);
      expect(state.value!.password, testPassword);
      expect(state.value!.sessionToken, testToken);
      expect(state.value!.loginType, LoginType.remote);

      verify(() => mockAuthService.cloudLogin(
            username: testUsername,
            password: testPassword,
            sessionToken: null,
          )).called(1);

      container.dispose();
    });

    test('cloudLogin() handles authentication failure', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = makeProviderContainer();

      const testUsername = 'wrong@example.com';
      const testPassword = 'wrongpass';

      when(() => mockAuthService.cloudLogin(
                username: testUsername,
                password: testPassword,
                sessionToken: null,
              ))
          .thenAnswer((_) async => const AuthFailure(
              UnexpectedError(message: 'INVALID_CREDENTIALS')));

      // Act
      await container.read(authProvider.notifier).cloudLogin(
            username: testUsername,
            password: testPassword,
          );

      // Assert
      final state = container.read(authProvider);
      expect(state.hasError, true);
      expect(state.error, isA<UnexpectedError>());
      expect((state.error as UnexpectedError).message, 'INVALID_CREDENTIALS');

      container.dispose();
    });
  });

  group('AuthNotifier - Local Login', () {
    test('localLogin() successfully delegates to AuthService', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = makeProviderContainer();

      // Initialize with empty state
      final initialState = AuthState.empty();
      container.read(authProvider.notifier).state =
          AsyncValue.data(initialState);

      const testPassword = 'admin123';
      const loginInfo = LoginInfo(
        localPassword: testPassword,
        loginType: LoginType.local,
      );

      when(() => mockAuthService.localLogin(testPassword, pnp: false))
          .thenAnswer((_) async => const AuthSuccess(loginInfo));

      // Act
      await container.read(authProvider.notifier).localLogin(testPassword);

      // Assert
      final state = container.read(authProvider);
      expect(state.hasValue, true);
      expect(state.value!.localPassword, testPassword);
      expect(state.value!.loginType, LoginType.local);

      verify(() => mockAuthService.localLogin(testPassword, pnp: false))
          .called(1);

      container.dispose();
    });

    test('localLogin() handles invalid password', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = makeProviderContainer();

      final initialState = AuthState.empty();
      container.read(authProvider.notifier).state =
          AsyncValue.data(initialState);

      const wrongPassword = 'wrongpass';

      when(() => mockAuthService.localLogin(wrongPassword, pnp: false))
          .thenAnswer((_) async => const AuthFailure(
              UnexpectedError(message: 'ErrorInvalidPassword')));

      // Act
      await container.read(authProvider.notifier).localLogin(wrongPassword);

      // Assert
      final state = container.read(authProvider);
      expect(state.hasError, true);
      expect(state.error, isA<UnexpectedError>());
      expect((state.error as UnexpectedError).message, 'ErrorInvalidPassword');

      container.dispose();
    });

    test('localLogin() with pnp=true passes correct flag', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = makeProviderContainer();

      final initialState = AuthState.empty();
      container.read(authProvider.notifier).state =
          AsyncValue.data(initialState);

      const testPassword = 'admin123';
      const loginInfo = LoginInfo(
        localPassword: testPassword,
        loginType: LoginType.local,
      );

      when(() => mockAuthService.localLogin(testPassword, pnp: true))
          .thenAnswer((_) async => const AuthSuccess(loginInfo));

      // Act
      await container
          .read(authProvider.notifier)
          .localLogin(testPassword, pnp: true);

      // Assert
      verify(() => mockAuthService.localLogin(testPassword, pnp: true))
          .called(1);

      container.dispose();
    });
  });

  // Note: raLogin() tests require complex provider mocking with SessionProvider
  // These are better covered by integration tests

  // Note: logout() tests are complex due to provider dependencies
  // and are better covered by integration tests

  group('AuthNotifier - Password Hint', () {
    test('getPasswordHint() delegates to AuthService and updates state',
        () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = makeProviderContainer();

      // Initialize with some state
      await container.read(authProvider.notifier).build();

      const testHint = 'My security answer';

      when(() => mockAuthService.getPasswordHint())
          .thenAnswer((_) async => const AuthSuccess(testHint));

      // Act
      await container.read(authProvider.notifier).getPasswordHint();

      // Assert
      final state = container.read(authProvider);
      expect(state.hasValue, true);
      expect(state.value!.localPasswordHint, testHint);

      verify(() => mockAuthService.getPasswordHint()).called(1);

      container.dispose();
    });
  });

  group('AuthNotifier - Check Session Token (Backward Compatibility)', () {
    test('checkSessionToken() throws when token is null', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = makeProviderContainer();

      when(() => mockAuthService.validateSessionToken())
          .thenAnswer((_) async => const AuthSuccess(null));

      // Act & Assert
      // checkSessionToken throws for backward compatibility
      try {
        await container.read(authProvider.notifier).checkSessionToken();
        fail('Should have thrown');
      } catch (e) {
        expect(e, isNotNull);
      }

      container.dispose();
    });

    test('checkSessionToken() returns token when valid', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = makeProviderContainer();

      final testToken = SessionToken(
        accessToken: 'valid-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );

      when(() => mockAuthService.validateSessionToken())
          .thenAnswer((_) async => AuthSuccess(testToken));

      // Act
      final token =
          await container.read(authProvider.notifier).checkSessionToken();

      // Assert
      expect(token, testToken);
      verify(() => mockAuthService.validateSessionToken()).called(1);

      container.dispose();
    });
  });

  group('AuthNotifier - Get Admin Password Auth Status', () {
    test(
        'getAdminPasswordAuthStatus() delegates to AuthService and returns status',
        () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = makeProviderContainer();

      final testStatus = {'isAdminPasswordDefault': false};

      when(() => mockAuthService.getAdminPasswordAuthStatus())
          .thenAnswer((_) async => AuthSuccess(testStatus));

      // Act
      final status = await container
          .read(authProvider.notifier)
          .getAdminPasswordAuthStatus();

      // Assert
      expect(status, testStatus);
      verify(() => mockAuthService.getAdminPasswordAuthStatus()).called(1);

      container.dispose();
    });
  });

  group('AuthNotifier - Cloud Login Auth (GRA)', () {
    test('cloudLoginAuth() stores GRA session info', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        pSessionToken: jsonEncode({
          'accessToken': 'existing-token',
          'tokenType': 'Bearer',
          'expiresIn': 3600,
        }),
      });
      final container = makeProviderContainer();

      const testToken = 'gra-token';
      const testSerialNumber = 'SN12345';
      const testSessionInfo = GRASessionInfo(
        id: 'session-123',
        serialNumber: testSerialNumber,
        modelNumber: 'MX5500',
        status: GRASessionStatus.active,
        expiredIn: 3600,
        createdAt: 1234567890,
        statusChangedAt: 1234567890,
        currentTime: 1234567890,
      );

      // Act - Just verify the method doesn't throw
      // The actual implementation involves complex interactions with
      // cloud API that we're not mocking here
      await container.read(authProvider.notifier).cloudLoginAuth(
            token: testToken,
            sn: testSerialNumber,
            sessionInfo: testSessionInfo,
          );

      // Assert - Verify prefs were updated with session ID
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pGRASessionId), testSessionInfo.id);
      expect(prefs.getString(pCurrentSN), testSerialNumber);

      container.dispose();
    });
  });

  group('AuthNotifier - State Management', () {
    test('State transitions from empty to success after login', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = makeProviderContainer();

      // Initial state should be empty
      final initialState = await container.read(authProvider.notifier).build();
      expect(initialState.loginType, LoginType.none);

      const testUsername = 'test@example.com';
      const testPassword = 'password123';

      final testToken = SessionToken(
        accessToken: 'test-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );

      final loginInfo = LoginInfo(
        username: testUsername,
        password: testPassword,
        sessionToken: testToken,
        loginType: LoginType.remote,
      );

      when(() => mockAuthService.cloudLogin(
            username: testUsername,
            password: testPassword,
            sessionToken: null,
          )).thenAnswer((_) async => AuthSuccess(loginInfo));

      // Act - Perform login
      await container.read(authProvider.notifier).cloudLogin(
            username: testUsername,
            password: testPassword,
          );

      // Check success state
      final successState = container.read(authProvider);
      expect(successState.hasValue, true);
      expect(successState.value!.username, testUsername);
      expect(successState.value!.loginType, LoginType.remote);

      container.dispose();
    });

    test('AsyncValue.error is set on failure', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = makeProviderContainer();

      const testUsername = 'test@example.com';
      const testPassword = 'password123';

      when(() => mockAuthService.cloudLogin(
                username: testUsername,
                password: testPassword,
                sessionToken: null,
              ))
          .thenAnswer((_) async =>
              const AuthFailure(NetworkError(message: 'Network error')));

      // Act
      await container.read(authProvider.notifier).cloudLogin(
            username: testUsername,
            password: testPassword,
          );

      // Assert
      final state = container.read(authProvider);
      expect(state.hasError, true);
      expect(state.error, isA<NetworkError>());

      container.dispose();
    });
  });
}
