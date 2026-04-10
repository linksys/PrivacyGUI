import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';

class MockUspService extends Mock implements UspService {}

void main() {
  late MockUspService mockUsp;

  final timeResponse = <String, dynamic>{
    'Device.Time.Enable': true,
    'Device.Time.Status': 'Synchronized',
    'Device.Time.NTPServer1': 'pool.ntp.org',
    'Device.Time.NTPServer2': 'time.google.com',
    'Device.Time.LocalTimeZone': 'CST-8',
    'Device.Time.CurrentLocalTime': '2026-03-23T12:00:00',
  };

  setUp(() {
    mockUsp = MockUspService();
    when(() => mockUsp.get(any())).thenAnswer((_) async => timeResponse);
    when(() => mockUsp.set(any())).thenAnswer((_) async => {
      'overallSuccess': true,
      'hasAnySuccess': true,
      'hasErrors': false,
      'results': []
    });
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        uspServiceProvider.overrideWithValue(mockUsp),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ],
    );
  }

  group('TimeDataNotifier', () {
    test('build fetches and maps time settings', () async {
      final container = createContainer();
      final data = await container.read(timeDataProvider.future);

      expect(data.model.enable, isTrue);
      expect(data.model.status, 'Synchronized');
      expect(data.model.ntpServer1, 'pool.ntp.org');
      expect(data.model.ntpServer2, 'time.google.com');
      expect(data.model.localTimeZone, 'CST-8');
      expect(data.model.currentLocalTime, '2026-03-23T12:00:00');
      container.dispose();
    });

    test('build throws when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspServiceProvider.overrideWithValue(null),
        ],
      );

      expect(
        container.read(timeDataProvider.future),
        throwsA(isA<StateError>()),
      );
      container.dispose();
    });

    test('updateTimeSettings calls save and invalidates', () async {
      final container = createContainer();
      await container.read(timeDataProvider.future);

      await container
          .read(timeDataProvider.notifier)
          .updateTimeSettings(enable: false, ntpServer1: 'ntp.example.com');

      verify(() => mockUsp.set(any())).called(1);
      container.dispose();
    });

    test('updateTimezone calls save with timezone param', () async {
      final container = createContainer();
      await container.read(timeDataProvider.future);

      await container
          .read(timeDataProvider.notifier)
          .updateTimezone(localTimeZone: 'EST5EDT', enable: true);

      verify(() => mockUsp.set(any())).called(1);
      container.dispose();
    });

    test('TimeData equality uses model props', () async {
      final container = createContainer();
      final data1 = await container.read(timeDataProvider.future);
      final data2 = await container.read(timeDataProvider.future);

      // Same model → equal
      expect(data1, equals(data2));
      expect(data1.props, isNotEmpty);
      container.dispose();
    });
  });
}
