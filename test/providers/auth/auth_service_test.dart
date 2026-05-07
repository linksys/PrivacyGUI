import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/providers/auth/auth_service.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage mockStorage;
  late AuthService service;

  setUp(() {
    mockStorage = MockSecureStorage();
    service = AuthService(mockStorage);
  });

  // ---------------------------------------------------------------------------
  // getStoredLocalPassword
  // ---------------------------------------------------------------------------

  group('AuthService — getStoredLocalPassword', () {
    test('returns stored password when present', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'myPassword');

      final result = await service.getStoredLocalPassword();

      expect(result.isSuccess, isTrue);
      result.when(
        success: (value) => expect(value, 'myPassword'),
        failure: (_) => fail('expected success'),
      );
    });

    test('returns null when no password stored', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final result = await service.getStoredLocalPassword();

      expect(result.isSuccess, isTrue);
      result.when(
        success: (value) => expect(value, isNull),
        failure: (_) => fail('expected success'),
      );
    });

    test('returns failure on storage exception', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenThrow(Exception('disk error'));

      final result = await service.getStoredLocalPassword();

      expect(result.isFailure, isTrue);
      result.when(
        success: (_) => fail('expected failure'),
        failure: (error) => expect(error, isA<StorageError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getStoredLoginType
  // ---------------------------------------------------------------------------

  group('AuthService — getStoredLoginType', () {
    test('returns LoginType.local when password exists', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'somePass');

      final result = await service.getStoredLoginType();

      expect(result.isSuccess, isTrue);
      result.when(
        success: (value) => expect(value, LoginType.local),
        failure: (_) => fail('expected success'),
      );
    });

    test('returns LoginType.none when no password', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final result = await service.getStoredLoginType();

      expect(result.isSuccess, isTrue);
      result.when(
        success: (value) => expect(value, LoginType.none),
        failure: (_) => fail('expected success'),
      );
    });

    test('returns failure on storage exception', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenThrow(Exception('corrupted'));

      final result = await service.getStoredLoginType();

      expect(result.isFailure, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // saveLocalPassword
  // ---------------------------------------------------------------------------

  group('AuthService — saveLocalPassword', () {
    test('writes password to secure storage', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async {});

      final result = await service.saveLocalPassword('newPass');

      expect(result.isSuccess, isTrue);
      verify(() => mockStorage.write(key: 'LocalPassword', value: 'newPass'))
          .called(1);
    });

    test('returns failure on storage exception', () async {
      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenThrow(Exception('write fail'));

      final result = await service.saveLocalPassword('pass');

      expect(result.isFailure, isTrue);
      result.when(
        success: (_) => fail('expected failure'),
        failure: (error) => expect(error, isA<StorageError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // clearAllCredentials
  // ---------------------------------------------------------------------------

  group('AuthService — clearAllCredentials', () {
    test('deletes password from secure storage', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      final result = await service.clearAllCredentials();

      expect(result.isSuccess, isTrue);
      verify(() => mockStorage.delete(key: 'LocalPassword')).called(1);
    });

    test('returns failure on storage exception', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenThrow(Exception('delete fail'));

      final result = await service.clearAllCredentials();

      expect(result.isFailure, isTrue);
    });
  });
}
