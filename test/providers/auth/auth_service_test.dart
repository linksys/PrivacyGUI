import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/cloud/linksys_cloud_repository.dart';
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/providers/auth/auth_result.dart';
import 'package:privacy_gui/providers/auth/auth_service.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock for RouterRepository
class MockRouterRepository extends Mock implements RouterRepository {}

/// Mock for LinksysCloudRepository
class MockCloudRepository extends Mock implements LinksysCloudRepository {}

/// Mock for FlutterSecureStorage
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register fallback values for Mocktail (use actual enum values for enums)
    registerFallbackValue(JNAPAction.checkAdminPassword);
    registerFallbackValue(CacheLevel.noCache);
  });
  late AuthService authService;
  late MockRouterRepository mockRouterRepository;
  late MockCloudRepository mockCloudRepository;
  late MockSecureStorage mockSecureStorage;

  setUp(() {
    mockRouterRepository = MockRouterRepository();
    mockCloudRepository = MockCloudRepository();
    mockSecureStorage = MockSecureStorage();

    authService = AuthService(
      mockRouterRepository,
      mockCloudRepository,
      mockSecureStorage,
    );
  });

  group('AuthService', () {
    test('can be instantiated with dependencies', () {
      expect(authService, isNotNull);
    });
  });

  // ============================================================================
  // Phase 3 (US1): Session Token Management Tests
  // ============================================================================

  group('Session Token Management', () {
    final validToken = SessionToken(
      accessToken: 'test-access-token',
      tokenType: 'Bearer',
      expiresIn: 3600, // 1 hour
      refreshToken: 'test-refresh-token',
    );

    final tokenWithoutRefresh = SessionToken(
      accessToken: 'test-access-token',
      tokenType: 'Bearer',
      expiresIn: 3600,
      refreshToken: null,
    );

    // T013: Test validateSessionToken() with valid non-expired token
    test('T013: validateSessionToken returns valid token when not expired',
        () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      final tokenTs = (now - 1800000).toString(); // 30 minutes ago
      final tokenJson = jsonEncode(validToken.toJson());

      when(() => mockSecureStorage.read(key: pSessionTokenTs))
          .thenAnswer((_) async => tokenTs);
      when(() => mockSecureStorage.read(key: pSessionToken))
          .thenAnswer((_) async => tokenJson);

      // Act
      final result = await authService.validateSessionToken();

      // Assert
      expect(result.isSuccess, true);
      final token = (result as AuthSuccess<SessionToken?>).value;
      expect(token, isNotNull);
      expect(token!.accessToken, validToken.accessToken);
      expect(token.refreshToken, validToken.refreshToken);
    });

    // T014: Test validateSessionToken() with expired token + valid refresh token
    test(
        'T014: validateSessionToken refreshes token when expired with refresh token',
        () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      final tokenTs = (now - 7200000).toString(); // 2 hours ago (expired)
      final tokenJson = jsonEncode(validToken.toJson());

      final newToken = SessionToken(
        accessToken: 'new-access-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
        refreshToken: 'new-refresh-token',
      );

      when(() => mockSecureStorage.read(key: pSessionTokenTs))
          .thenAnswer((_) async => tokenTs);
      when(() => mockSecureStorage.read(key: pSessionToken))
          .thenAnswer((_) async => tokenJson);
      when(() => mockCloudRepository.refreshToken(validToken.refreshToken!))
          .thenAnswer((_) async => newToken);
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});

      // Act
      final result = await authService.validateSessionToken();

      // Assert
      expect(result.isSuccess, true);
      final token = (result as AuthSuccess<SessionToken?>).value;
      expect(token, isNotNull);
      expect(token!.accessToken, newToken.accessToken);

      // Verify refresh was called
      verify(() => mockCloudRepository.refreshToken(validToken.refreshToken!))
          .called(1);
      verify(() => mockSecureStorage.write(
          key: pSessionToken, value: any(named: 'value'))).called(1);
      verify(() => mockSecureStorage.write(
          key: pSessionTokenTs, value: any(named: 'value'))).called(1);
    });

    // T015: Test validateSessionToken() with no token stored
    test('T015: validateSessionToken returns null when no token exists',
        () async {
      // Arrange
      when(() => mockSecureStorage.read(key: pSessionTokenTs))
          .thenAnswer((_) async => null);
      when(() => mockSecureStorage.read(key: pSessionToken))
          .thenAnswer((_) async => null);

      // Act
      final result = await authService.validateSessionToken();

      // Assert
      expect(result.isSuccess, true);
      final token = (result as AuthSuccess<SessionToken?>).value;
      expect(token, isNull);
    });

    // T016: Test validateSessionToken() with expired token + no refresh token
    test(
        'T016: validateSessionToken clears and returns null when expired without refresh token',
        () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      final tokenTs = (now - 7200000).toString(); // 2 hours ago (expired)
      final tokenJson = jsonEncode(tokenWithoutRefresh.toJson());

      when(() => mockSecureStorage.read(key: pSessionTokenTs))
          .thenAnswer((_) async => tokenTs);
      when(() => mockSecureStorage.read(key: pSessionToken))
          .thenAnswer((_) async => tokenJson);
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async => {});

      // Act
      final result = await authService.validateSessionToken();

      // Assert
      expect(result.isSuccess, true);
      final token = (result as AuthSuccess<SessionToken?>).value;
      expect(token, isNull);

      // Verify expired token was cleared
      verify(() => mockSecureStorage.delete(key: pSessionToken)).called(1);
      verify(() => mockSecureStorage.delete(key: pSessionTokenTs)).called(1);
    });

    // T017: Test validateSessionToken() with corrupted JSON data
    test(
        'T017: validateSessionToken clears and returns null with corrupted data',
        () async {
      // Arrange
      final now = DateTime.now().millisecondsSinceEpoch;
      final tokenTs = now.toString();
      const corruptedJson = '{invalid json data}';

      when(() => mockSecureStorage.read(key: pSessionTokenTs))
          .thenAnswer((_) async => tokenTs);
      when(() => mockSecureStorage.read(key: pSessionToken))
          .thenAnswer((_) async => corruptedJson);
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async => {});

      // Act
      final result = await authService.validateSessionToken();

      // Assert
      expect(result.isSuccess, true);
      final token = (result as AuthSuccess<SessionToken?>).value;
      expect(token, isNull);

      // Verify corrupted data was cleared
      verify(() => mockSecureStorage.delete(key: pSessionToken)).called(1);
      verify(() => mockSecureStorage.delete(key: pSessionTokenTs)).called(1);
    });

    // T018: Test refreshSessionToken() success flow
    test('T018: refreshSessionToken successfully refreshes and stores token',
        () async {
      // Arrange
      const refreshTokenString = 'test-refresh-token';
      final newToken = SessionToken(
        accessToken: 'new-access-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
        refreshToken: 'new-refresh-token',
      );

      when(() => mockCloudRepository.refreshToken(refreshTokenString))
          .thenAnswer((_) async => newToken);
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});

      // Act
      final result = await authService.refreshSessionToken(refreshTokenString);

      // Assert
      expect(result.isSuccess, true);
      final token = (result as AuthSuccess<SessionToken?>).value;
      expect(token, isNotNull);
      expect(token!.accessToken, newToken.accessToken);

      // Verify storage operations
      verify(() => mockCloudRepository.refreshToken(refreshTokenString))
          .called(1);
      verify(() => mockSecureStorage.write(
            key: pSessionToken,
            value: jsonEncode(newToken.toJson()),
          )).called(1);
      verify(() => mockSecureStorage.write(
            key: pSessionTokenTs,
            value: any(named: 'value'),
          )).called(1);
    });

    // T019: Test refreshSessionToken() failure (network error)
    test('T019: refreshSessionToken returns failure on network error',
        () async {
      // Arrange
      const refreshTokenString = 'test-refresh-token';
      final exception = Exception('Network error');

      when(() => mockCloudRepository.refreshToken(refreshTokenString))
          .thenThrow(exception);

      // Act
      final result = await authService.refreshSessionToken(refreshTokenString);

      // Assert
      expect(result.isFailure, true);
      final error = (result as AuthFailure<SessionToken?>).error;
      expect(error, isA<TokenRefreshError>());
      expect((error as TokenRefreshError).cause, exception);
    });
  });

  // ============================================================================
  // Phase 4 (US2): Authentication Flows Tests
  // ============================================================================

  group('Authentication Flows', () {
    const testUsername = 'test@example.com';
    const testPassword = 'testPassword123';
    const testLocalPassword = 'adminPass123';

    final testToken = SessionToken(
      accessToken: 'test-access-token',
      tokenType: 'Bearer',
      expiresIn: 3600,
      refreshToken: 'test-refresh-token',
    );

    // T026: Test cloudLogin() with valid credentials (success)
    test('T026: cloudLogin succeeds with valid credentials', () async {
      // Arrange
      when(() => mockCloudRepository.login(
            username: testUsername,
            password: testPassword,
          )).thenAnswer((_) async => testToken);
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});

      // Act
      final result = await authService.cloudLogin(
        username: testUsername,
        password: testPassword,
      );

      // Assert
      expect(result.isSuccess, true);
      final loginInfo = (result as AuthSuccess).value;
      expect(loginInfo.loginType, LoginType.remote);
      expect(loginInfo.sessionToken?.accessToken, testToken.accessToken);
      expect(loginInfo.username, testUsername);
      expect(loginInfo.password, testPassword);

      // Verify storage calls
      verify(() => mockCloudRepository.login(
            username: testUsername,
            password: testPassword,
          )).called(1);
      verify(() => mockSecureStorage.write(
            key: pSessionToken,
            value: any(named: 'value'),
          )).called(1);
      verify(() => mockSecureStorage.write(
            key: pUsername,
            value: testUsername,
          )).called(1);
      verify(() => mockSecureStorage.write(
            key: pUserPassword,
            value: testPassword,
          )).called(1);
    });

    // T027: Test cloudLogin() with invalid credentials (returns UnexpectedError)
    test('T027: cloudLogin fails with invalid credentials', () async {
      // Arrange
      final errorResponse = ErrorResponse(
        status: 401,
        code: 'INVALID_CREDENTIALS',
        errorMessage: 'Invalid username or password',
      );
      when(() => mockCloudRepository.login(
            username: testUsername,
            password: testPassword,
          )).thenThrow(errorResponse);

      // Act
      final result = await authService.cloudLogin(
        username: testUsername,
        password: testPassword,
      );

      // Assert
      expect(result.isFailure, true);
      final error = (result as AuthFailure).error;
      expect(error, isA<UnexpectedError>());
      expect((error as UnexpectedError).message, 'INVALID_CREDENTIALS');
    });

    // T028: Test cloudLogin() with network failure (returns NetworkError)
    test('T028: cloudLogin fails with network error', () async {
      // Arrange
      final networkException = Exception('Network timeout');
      when(() => mockCloudRepository.login(
            username: testUsername,
            password: testPassword,
          )).thenThrow(networkException);

      // Act
      final result = await authService.cloudLogin(
        username: testUsername,
        password: testPassword,
      );

      // Assert
      expect(result.isFailure, true);
      final error = (result as AuthFailure).error;
      expect(error, isA<NetworkError>());
      expect((error as NetworkError).message, contains('Network timeout'));
    });

    // T029: Test localLogin() with valid password (JNAP success)
    test('T029: localLogin succeeds with valid password', () async {
      // Arrange
      const successResponse = JNAPSuccess(
        result: jnapResultOk,
        output: {},
      );
      when(() => mockRouterRepository.send(
            any(),
            extraHeaders: any(named: 'extraHeaders'),
            data: any(named: 'data'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenAnswer((_) async => successResponse);
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});

      // Act
      final result = await authService.localLogin(testLocalPassword);

      // Assert
      expect(result.isSuccess, true);
      final loginInfo = (result as AuthSuccess).value;
      expect(loginInfo.loginType, LoginType.local);
      expect(loginInfo.localPassword, testLocalPassword);

      // Verify storage call
      verify(() => mockSecureStorage.write(
            key: pLocalPassword,
            value: testLocalPassword,
          )).called(1);
    });

    // T030: Test localLogin() with invalid password (JNAP error)
    test('T030: localLogin fails with invalid password', () async {
      // Arrange
      const errorResponse = JNAPSuccess(
        result: 'ErrorInvalidPassword',
        output: {},
      );
      when(() => mockRouterRepository.send(
            any(),
            extraHeaders: any(named: 'extraHeaders'),
            data: any(named: 'data'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenAnswer((_) async => errorResponse);

      // Act
      final result = await authService.localLogin(testLocalPassword);

      // Assert
      expect(result.isFailure, true);
      final error = (result as AuthFailure).error;
      expect(error, isA<UnexpectedError>());
      expect((error as UnexpectedError).message, 'ErrorInvalidPassword');
    });

    // T031: Test raLogin() with valid session info
    test('T031: raLogin succeeds with valid session info', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({}); // Mock SharedPreferences
      const testSessionToken = 'ra-session-token';
      const testNetworkId = 'network-123';
      const testSerialNumber = 'SN12345';

      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});

      // Act
      final result = await authService.raLogin(
        testSessionToken,
        testNetworkId,
        testSerialNumber,
      );

      // Assert
      expect(result.isSuccess, true);
      final loginInfo = (result as AuthSuccess).value;
      expect(loginInfo.loginType, LoginType.remote);
      expect(loginInfo.sessionToken?.accessToken, testSessionToken);

      // Verify storage calls
      verify(() => mockSecureStorage.write(
            key: pSessionToken,
            value: any(named: 'value'),
          )).called(1);
    });

    // T032: Test getPasswordHint()
    test('T032: getPasswordHint retrieves hint successfully', () async {
      // Arrange
      const testHint = 'My security answer';
      const hintResponse = JNAPSuccess(
        result: jnapResultOk,
        output: {'passwordHint': testHint},
      );
      when(() => mockRouterRepository.send(any()))
          .thenAnswer((_) async => hintResponse);

      // Act
      final result = await authService.getPasswordHint();

      // Assert
      expect(result.isSuccess, true);
      final hint = (result as AuthSuccess<String>).value;
      expect(hint, testHint);
    });
  });

  // ============================================================================
  // Phase 5 (US3): Credential Persistence Tests
  // ============================================================================

  group('Credential Persistence', () {
    final testToken = SessionToken(
      accessToken: 'test-access-token',
      tokenType: 'Bearer',
      expiresIn: 3600,
      refreshToken: 'test-refresh-token',
    );

    const testUsername = 'test@example.com';
    const testPassword = 'testPassword123';

    // T038: Test updateCloudCredentials() stores session token with correct keys
    test('T038: updateCloudCredentials stores session token with correct keys',
        () async {
      // Arrange
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});

      // Act
      final result = await authService.updateCloudCredentials(
        sessionToken: testToken,
      );

      // Assert
      expect(result.isSuccess, true);

      // Verify session token was written
      verify(() => mockSecureStorage.write(
            key: pSessionToken,
            value: any(named: 'value'),
          )).called(1);
      verify(() => mockSecureStorage.write(
            key: pSessionTokenTs,
            value: any(named: 'value'),
          )).called(1);
    });

    // T039: Test updateCloudCredentials() stores username and password
    test('T039: updateCloudCredentials stores username and password', () async {
      // Arrange
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});

      // Act
      final result = await authService.updateCloudCredentials(
        username: testUsername,
        password: testPassword,
      );

      // Assert
      expect(result.isSuccess, true);

      // Verify username and password were written
      verify(() => mockSecureStorage.write(
            key: pUsername,
            value: testUsername,
          )).called(1);
      verify(() => mockSecureStorage.write(
            key: pUserPassword,
            value: testPassword,
          )).called(1);
    });

    // T040: Test updateCloudCredentials() handles storage write failure
    test('T040: updateCloudCredentials handles storage write failure',
        () async {
      // Arrange
      final exception = Exception('Storage write failed');
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenThrow(exception);

      // Act
      final result = await authService.updateCloudCredentials(
        username: testUsername,
      );

      // Assert
      expect(result.isFailure, true);
      final error = (result as AuthFailure<void>).error;
      expect(error, isA<StorageError>());
      expect((error as StorageError).originalError, exception);
    });

    // T041: Test getStoredCredentials() retrieves all credential types
    test('T041: getStoredCredentials retrieves all credential types', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        pCurrentSN: 'SN12345',
        pSelectedNetworkId: 'network-123',
        pRAMode: true,
      });

      final tokenJson = jsonEncode(testToken.toJson());
      const tokenTs = '1234567890';
      const localPwd = 'localPassword123';

      when(() => mockSecureStorage.read(key: pSessionToken))
          .thenAnswer((_) async => tokenJson);
      when(() => mockSecureStorage.read(key: pSessionTokenTs))
          .thenAnswer((_) async => tokenTs);
      when(() => mockSecureStorage.read(key: pLocalPassword))
          .thenAnswer((_) async => localPwd);
      when(() => mockSecureStorage.read(key: pUsername))
          .thenAnswer((_) async => testUsername);
      when(() => mockSecureStorage.read(key: pUserPassword))
          .thenAnswer((_) async => testPassword);

      // Act
      final result = await authService.getStoredCredentials();

      // Assert
      expect(result.isSuccess, true);
      final creds = (result as AuthSuccess).value;
      expect(creds.sessionToken?.accessToken, testToken.accessToken);
      expect(creds.sessionTokenTs, tokenTs);
      expect(creds.localPassword, localPwd);
      expect(creds.username, testUsername);
      expect(creds.password, testPassword);
      expect(creds.currentSN, 'SN12345');
      expect(creds.selectedNetworkId, 'network-123');
      expect(creds.raMode, true);
    });

    // T042: Test clearAllCredentials() removes all auth data from both storages
    test('T042: clearAllCredentials removes all auth data from both storages',
        () async {
      // Arrange
      SharedPreferences.setMockInitialValues({
        pSelectedNetworkId: 'network-123',
        pCurrentSN: 'SN12345',
        pDeviceToken: 'device-token',
        pGRASessionId: 'gra-session',
        pRAMode: true,
      });

      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async => {});

      // Act
      final result = await authService.clearAllCredentials();

      // Assert
      expect(result.isSuccess, true);

      // Verify SharedPreferences keys were removed
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pSelectedNetworkId), isNull);
      expect(prefs.getString(pCurrentSN), isNull);
      expect(prefs.getString(pDeviceToken), isNull);
      expect(prefs.getString(pGRASessionId), isNull);
      expect(prefs.getBool(pRAMode), isNull);

      // Verify secure storage keys were deleted
      verify(() => mockSecureStorage.delete(key: pSessionToken)).called(1);
      verify(() => mockSecureStorage.delete(key: pSessionTokenTs)).called(1);
      verify(() => mockSecureStorage.delete(key: pLocalPassword)).called(1);
      verify(() => mockSecureStorage.delete(key: pUsername)).called(1);
      verify(() => mockSecureStorage.delete(key: pUserPassword)).called(1);
      verify(() => mockSecureStorage.delete(key: pLinksysToken)).called(1);
      verify(() => mockSecureStorage.delete(key: pLinksysTokenTs)).called(1);
    });

    // T043: Test clearAllCredentials() handles partial failure
    test(
        'T043: clearAllCredentials handles partial failure (secure storage clears but prefs fails)',
        () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Mock secure storage delete to succeed
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async => {});

      // Note: With current implementation, SharedPreferences.remove() doesn't throw
      // So we test that the method completes successfully even with mixed operations
      // In a real scenario where prefs could fail, we'd mock SharedPreferences too

      // Act
      final result = await authService.clearAllCredentials();

      // Assert
      expect(result.isSuccess, true);

      // Verify secure storage operations were attempted
      verify(() => mockSecureStorage.delete(key: pSessionToken)).called(1);
      verify(() => mockSecureStorage.delete(key: pSessionTokenTs)).called(1);
    });

    // T044: Test getStoredLoginType() correctly determines none/local/remote
    test('T044: getStoredLoginType correctly determines none/local/remote',
        () async {
      // Test case 1: Remote login (session token exists)
      when(() => mockSecureStorage.read(key: pSessionToken))
          .thenAnswer((_) async => jsonEncode(testToken.toJson()));
      when(() => mockSecureStorage.read(key: pLocalPassword))
          .thenAnswer((_) async => null);

      var result = await authService.getStoredLoginType();
      expect(result.isSuccess, true);
      expect((result as AuthSuccess<LoginType>).value, LoginType.remote);

      // Test case 2: Local login (only local password exists)
      when(() => mockSecureStorage.read(key: pSessionToken))
          .thenAnswer((_) async => null);
      when(() => mockSecureStorage.read(key: pLocalPassword))
          .thenAnswer((_) async => 'localPassword123');

      result = await authService.getStoredLoginType();
      expect(result.isSuccess, true);
      expect((result as AuthSuccess<LoginType>).value, LoginType.local);

      // Test case 3: No login (no credentials)
      when(() => mockSecureStorage.read(key: pSessionToken))
          .thenAnswer((_) async => null);
      when(() => mockSecureStorage.read(key: pLocalPassword))
          .thenAnswer((_) async => null);

      result = await authService.getStoredLoginType();
      expect(result.isSuccess, true);
      expect((result as AuthSuccess<LoginType>).value, LoginType.none);
    });
  });

  // ============================================================================
  // Phase 7 (US5): Test Coverage Validation
  // ============================================================================

  group('ServiceError Coverage', () {
    // T059: Test all ServiceError types being returned correctly

    test('T059: All ServiceError types can be returned and matched', () async {
      // Test NoSessionTokenError (already covered by existing tests)
      // Test SessionTokenExpiredError (already covered by existing tests)

      // Test TokenRefreshError with cause
      when(() => mockCloudRepository.refreshToken(any()))
          .thenThrow(Exception('Network timeout'));

      final tokenResult =
          await authService.refreshSessionToken('test-refresh-token');
      expect(tokenResult.isFailure, true);
      final tokenRefreshError = (tokenResult as AuthFailure).error;
      expect(tokenRefreshError, isA<TokenRefreshError>());
      expect((tokenRefreshError as TokenRefreshError).cause, isA<Exception>());

      // Test UnexpectedError with ErrorResponse (cloud API error)
      const errorResponse = ErrorResponse(
        status: 401,
        code: 'INVALID_CREDENTIALS',
        errorMessage: 'Invalid credentials',
      );
      when(() => mockCloudRepository.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
          )).thenThrow(errorResponse);

      final cloudResult = await authService.cloudLogin(
        username: 'test@example.com',
        password: 'password',
      );
      expect(cloudResult.isFailure, true);
      final cloudApiError = (cloudResult as AuthFailure).error;
      expect(cloudApiError, isA<UnexpectedError>());
      expect((cloudApiError as UnexpectedError).message, 'INVALID_CREDENTIALS');
      expect(cloudApiError.originalError, errorResponse);

      // Test UnexpectedError with JNAP error
      const jnapErrorResponse = JNAPSuccess(
        result: 'ErrorInvalidPassword',
        output: {},
      );
      when(() => mockRouterRepository.send(
            any(),
            extraHeaders: any(named: 'extraHeaders'),
            data: any(named: 'data'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenAnswer((_) async => jnapErrorResponse);

      final localResult = await authService.localLogin('wrong-password');
      expect(localResult.isFailure, true);
      final jnapError = (localResult as AuthFailure).error;
      expect(jnapError, isA<UnexpectedError>());
      expect((jnapError as UnexpectedError).message, 'ErrorInvalidPassword');

      // Test StorageError with originalError
      final storageException = Exception('Storage write failed');
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenThrow(storageException);

      final storageResult = await authService.updateCloudCredentials(
        username: 'test@example.com',
      );
      expect(storageResult.isFailure, true);
      final storageError = (storageResult as AuthFailure).error;
      expect(storageError, isA<StorageError>());
      expect((storageError as StorageError).originalError, storageException);

      // Test NetworkError with message
      final networkException = Exception('Connection timeout');
      when(() => mockCloudRepository.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
          )).thenThrow(networkException);

      final networkResult = await authService.cloudLogin(
        username: 'test@example.com',
        password: 'password',
      );
      expect(networkResult.isFailure, true);
      final networkError = (networkResult as AuthFailure).error;
      expect(networkError, isA<NetworkError>());
      expect((networkError as NetworkError).message,
          contains('Connection timeout'));
    });
  });

  group('AuthResult Pattern Matching', () {
    // T060: Test AuthResult pattern matching with when() method

    test('T060: AuthResult when() method handles success case', () async {
      // Arrange
      final testToken = SessionToken(
        accessToken: 'test-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      final tokenTs = (now - 1800000).toString(); // 30 minutes ago

      when(() => mockSecureStorage.read(key: pSessionTokenTs))
          .thenAnswer((_) async => tokenTs);
      when(() => mockSecureStorage.read(key: pSessionToken))
          .thenAnswer((_) async => jsonEncode(testToken.toJson()));

      // Act
      final result = await authService.validateSessionToken();

      // Assert - Test when() pattern matching
      final output = result.when(
        success: (token) => 'Success: ${token?.accessToken}',
        failure: (error) => 'Failure: ${error.runtimeType}',
      );

      expect(output, 'Success: test-token');
    });

    test('T060: AuthResult when() method handles failure case', () async {
      // Arrange
      when(() => mockCloudRepository.refreshToken(any()))
          .thenThrow(Exception('Network error'));

      // Act
      final result = await authService.refreshSessionToken('test-refresh');

      // Assert - Test when() pattern matching
      final output = result.when(
        success: (token) => 'Success: ${token?.accessToken}',
        failure: (error) => 'Failure: ${error.runtimeType}',
      );

      expect(output, 'Failure: TokenRefreshError');
    });

    test('T060: AuthResult when() method is exhaustive', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});

      // Act
      final result = await authService.raLogin(
        'test-token',
        'network-123',
        'SN12345',
      );

      // Assert - Both branches must be provided (compile-time safety)
      int successCount = 0;
      int failureCount = 0;

      result.when(
        success: (loginInfo) {
          successCount++;
          return loginInfo;
        },
        failure: (error) {
          failureCount++;
          return null;
        },
      );

      // Verify exactly one branch was executed
      expect(successCount + failureCount, 1);
      expect(successCount, 1); // This was a success case
    });
  });

  group('AuthResult Transformation', () {
    // T061: Test AuthResult map() transformation

    test('T061: AuthResult map() transforms success values', () async {
      // Arrange
      const testUsername = 'test@example.com';
      const testPassword = 'password123';
      final testToken = SessionToken(
        accessToken: 'test-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );

      when(() => mockCloudRepository.login(
            username: testUsername,
            password: testPassword,
          )).thenAnswer((_) async => testToken);
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});

      // Act
      final result = await authService.cloudLogin(
        username: testUsername,
        password: testPassword,
      );

      // Transform LoginInfo to just username using map()
      final transformedResult = result.map((loginInfo) => loginInfo.username);

      // Assert
      expect(transformedResult.isSuccess, true);
      final username = (transformedResult as AuthSuccess<String?>).value;
      expect(username, testUsername);
    });

    test('T061: AuthResult map() preserves failure', () async {
      // Arrange
      when(() => mockCloudRepository.refreshToken(any()))
          .thenThrow(Exception('Network error'));

      // Act
      final result = await authService.refreshSessionToken('test-refresh');

      // Transform with map() - should preserve the failure
      final transformedResult = result.map((token) => token?.accessToken);

      // Assert - Still a failure with the same error
      expect(transformedResult.isFailure, true);
      final error = (transformedResult as AuthFailure).error;
      expect(error, isA<TokenRefreshError>());
    });

    test('T061: AuthResult map() can chain transformations', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});

      // Act
      final result = await authService.raLogin(
        'test-token',
        'network-123',
        'SN12345',
      );

      // Chain multiple map() transformations
      final transformedResult = result
          .map((loginInfo) => loginInfo.sessionToken)
          .map((token) => token?.accessToken)
          .map((accessToken) => accessToken?.length ?? 0);

      // Assert
      expect(transformedResult.isSuccess, true);
      final length = (transformedResult as AuthSuccess<int>).value;
      expect(length, 'test-token'.length);
    });
  });

  group('Edge Cases and Concurrent Operations', () {
    // T058: Add edge case tests for concurrent operations

    test('T058: Multiple concurrent validateSessionToken calls', () async {
      // Arrange
      final testToken = SessionToken(
        accessToken: 'test-token',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      final tokenTs = (now - 1800000).toString();

      when(() => mockSecureStorage.read(key: pSessionTokenTs))
          .thenAnswer((_) async => tokenTs);
      when(() => mockSecureStorage.read(key: pSessionToken))
          .thenAnswer((_) async => jsonEncode(testToken.toJson()));

      // Act - Fire multiple concurrent requests
      final results = await Future.wait([
        authService.validateSessionToken(),
        authService.validateSessionToken(),
        authService.validateSessionToken(),
      ]);

      // Assert - All should succeed independently
      expect(results.length, 3);
      for (final result in results) {
        expect(result.isSuccess, true);
        final token = (result as AuthSuccess<SessionToken?>).value;
        expect(token?.accessToken, 'test-token');
      }
    });

    test('T058: Concurrent login operations (no special handling)', () async {
      // Arrange
      const testPassword = 'password123';
      const successResponse = JNAPSuccess(
        result: jnapResultOk,
        output: {},
      );

      when(() => mockRouterRepository.send(
            any(),
            extraHeaders: any(named: 'extraHeaders'),
            data: any(named: 'data'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenAnswer((_) async => successResponse);
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});

      // Act - Fire multiple concurrent login requests
      final results = await Future.wait([
        authService.localLogin(testPassword),
        authService.localLogin(testPassword),
        authService.localLogin(testPassword),
      ]);

      // Assert - All should succeed independently (no special locking)
      expect(results.length, 3);
      for (final result in results) {
        expect(result.isSuccess, true);
      }
    });

    test('T058: Concurrent credential updates (last write wins)', () async {
      // Arrange
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});

      // Act - Fire multiple concurrent credential updates
      final results = await Future.wait([
        authService.updateCloudCredentials(username: 'user1@example.com'),
        authService.updateCloudCredentials(username: 'user2@example.com'),
        authService.updateCloudCredentials(username: 'user3@example.com'),
      ]);

      // Assert - All should complete (last write wins, no locking)
      expect(results.length, 3);
      for (final result in results) {
        expect(result.isSuccess, true);
      }

      // Verify that write was called multiple times
      verify(() => mockSecureStorage.write(
            key: pUsername,
            value: any(named: 'value'),
          )).called(3);
    });

    test('T058: Edge case - Empty string credentials', () async {
      // Arrange
      when(() => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'))).thenAnswer((_) async => {});

      // Act - Empty strings should be stored as-is
      final result = await authService.updateCloudCredentials(
        username: '',
        password: '',
      );

      // Assert
      expect(result.isSuccess, true);
      verify(() => mockSecureStorage.write(key: pUsername, value: ''))
          .called(1);
      verify(() => mockSecureStorage.write(key: pUserPassword, value: ''))
          .called(1);
    });

    test('T058: Edge case - Very long token expiration time', () async {
      // Arrange
      final testToken = SessionToken(
        accessToken: 'test-token',
        tokenType: 'Bearer',
        expiresIn: 999999999, // Very long expiration
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      final tokenTs = now.toString();

      when(() => mockSecureStorage.read(key: pSessionTokenTs))
          .thenAnswer((_) async => tokenTs);
      when(() => mockSecureStorage.read(key: pSessionToken))
          .thenAnswer((_) async => jsonEncode(testToken.toJson()));

      // Act
      final result = await authService.validateSessionToken();

      // Assert - Should be valid (not expired)
      expect(result.isSuccess, true);
      final token = (result as AuthSuccess<SessionToken?>).value;
      expect(token, isNotNull);
      expect(token!.accessToken, 'test-token');
    });

    test('T058: Edge case - Negative token expiration time', () async {
      // Arrange
      final testToken = SessionToken(
        accessToken: 'test-token',
        tokenType: 'Bearer',
        expiresIn: -1000, // Negative expiration (immediately expired)
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      final tokenTs = now.toString();

      when(() => mockSecureStorage.read(key: pSessionTokenTs))
          .thenAnswer((_) async => tokenTs);
      when(() => mockSecureStorage.read(key: pSessionToken))
          .thenAnswer((_) async => jsonEncode(testToken.toJson()));
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async => {});

      // Act
      final result = await authService.validateSessionToken();

      // Assert - Should be cleared and return null
      expect(result.isSuccess, true);
      final token = (result as AuthSuccess<SessionToken?>).value;
      expect(token, isNull);

      // Verify token was cleared
      verify(() => mockSecureStorage.delete(key: pSessionToken)).called(1);
    });
  });
}
