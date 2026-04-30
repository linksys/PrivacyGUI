import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/connection/services/router_fingerprint_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late RouterFingerprintService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = RouterFingerprintService(mockStorage);
  });

  group('RouterFingerprintService', () {
    test('store saves serial number to secure storage', () async {
      when(() => mockStorage.write(
            key: 'router_fingerprint_serial',
            value: 'ABC123',
          )).thenAnswer((_) async {});

      await service.store('ABC123');

      verify(() => mockStorage.write(
            key: 'router_fingerprint_serial',
            value: 'ABC123',
          )).called(1);
    });

    test('read returns stored serial number', () async {
      when(() => mockStorage.read(key: 'router_fingerprint_serial'))
          .thenAnswer((_) async => 'ABC123');

      final result = await service.read();

      expect(result, 'ABC123');
    });

    test('read returns null when no fingerprint stored', () async {
      when(() => mockStorage.read(key: 'router_fingerprint_serial'))
          .thenAnswer((_) async => null);

      final result = await service.read();

      expect(result, isNull);
    });

    test('clear deletes the stored fingerprint', () async {
      when(() => mockStorage.delete(key: 'router_fingerprint_serial'))
          .thenAnswer((_) async {});

      await service.clear();

      verify(() => mockStorage.delete(key: 'router_fingerprint_serial'))
          .called(1);
    });

    test('matches returns true when serial matches stored', () async {
      when(() => mockStorage.read(key: 'router_fingerprint_serial'))
          .thenAnswer((_) async => 'ABC123');

      final result = await service.matches('ABC123');

      expect(result, isTrue);
    });

    test('matches returns false when serial differs', () async {
      when(() => mockStorage.read(key: 'router_fingerprint_serial'))
          .thenAnswer((_) async => 'ABC123');

      final result = await service.matches('XYZ789');

      expect(result, isFalse);
    });

    test('matches returns false when no fingerprint stored', () async {
      when(() => mockStorage.read(key: 'router_fingerprint_serial'))
          .thenAnswer((_) async => null);

      final result = await service.matches('ABC123');

      expect(result, isFalse);
    });
  });
}
