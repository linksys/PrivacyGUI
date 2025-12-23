import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/timezone.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_state.dart';
import 'package:privacy_gui/page/instant_admin/services/timezone_service.dart';

import '../../../mocks/test_data/instant_admin_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late TimezoneService service;
  late MockRouterRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(JNAPAction.getTimeSettings);
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    service = TimezoneService(mockRepository);
  });

  group('TimezoneService - fetchTimezoneSettings', () {
    test('returns timezone settings and status on success', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.getTimeSettings,
                auth: true,
                fetchRemote: any(named: 'fetchRemote'),
              ))
          .thenAnswer(
              (_) async => InstantAdminTestData.createGetTimeSettingsSuccess(
                    timeZoneID: 'PST8',
                    autoAdjustForDST: true,
                  ));

      // Act
      final (settings, status) = await service.fetchTimezoneSettings();

      // Assert
      expect(settings.timezoneId, 'PST8');
      expect(settings.isDaylightSaving, true);
      expect(status.supportedTimezones, isNotEmpty);
      verify(() => mockRepository.send(
            JNAPAction.getTimeSettings,
            auth: true,
            fetchRemote: false,
          )).called(1);
    });

    test('sorts timezones by UTC offset', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.getTimeSettings,
                auth: true,
                fetchRemote: any(named: 'fetchRemote'),
              ))
          .thenAnswer(
              (_) async => InstantAdminTestData.createGetTimeSettingsSuccess(
                    supportedTimeZones: InstantAdminTestData.unsortedTimezones,
                  ));

      // Act
      final (_, status) = await service.fetchTimezoneSettings();

      // Assert
      final offsets =
          status.supportedTimezones.map((t) => t.utcOffsetMinutes).toList();
      expect(offsets, isSortedList);
    });

    test('throws ServiceError on JNAP failure', () async {
      // Arrange
      when(() => mockRepository.send(
            JNAPAction.getTimeSettings,
            auth: true,
            fetchRemote: any(named: 'fetchRemote'),
          )).thenThrow(InstantAdminTestData.createGetTimeSettingsError());

      // Act & Assert
      expect(
        () => service.fetchTimezoneSettings(),
        throwsA(isA<ServiceError>()),
      );
    });

    test('respects forceRemote parameter', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.getTimeSettings,
                auth: true,
                fetchRemote: true,
              ))
          .thenAnswer(
              (_) async => InstantAdminTestData.createGetTimeSettingsSuccess());

      // Act
      await service.fetchTimezoneSettings(forceRemote: true);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.getTimeSettings,
            auth: true,
            fetchRemote: true,
          )).called(1);
    });
  });

  group('TimezoneService - saveTimezoneSettings', () {
    test('saves timezone settings successfully', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.setTimeSettings,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer(
              (_) async => InstantAdminTestData.createSetTimeSettingsSuccess());

      final settings = const TimezoneSettings(
        timezoneId: 'PST8',
        isDaylightSaving: true,
      );
      final supportedTimezones = [
        const SupportedTimezone(
          observesDST: true,
          timeZoneID: 'PST8',
          description: 'Pacific Time',
          utcOffsetMinutes: -480,
        ),
      ];

      // Act
      await service.saveTimezoneSettings(
        settings: settings,
        supportedTimezones: supportedTimezones,
      );

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setTimeSettings,
            data: {
              'timeZoneID': 'PST8',
              'autoAdjustForDST': true,
            },
            auth: true,
          )).called(1);
    });

    test('handles DST for non-DST timezones', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.setTimeSettings,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer(
              (_) async => InstantAdminTestData.createSetTimeSettingsSuccess());

      // Timezone that does NOT observe DST
      final settings = const TimezoneSettings(
        timezoneId: 'JST-9',
        isDaylightSaving:
            true, // User selected DST, but timezone doesn't support it
      );
      final supportedTimezones = [
        const SupportedTimezone(
          observesDST: false, // This timezone doesn't observe DST
          timeZoneID: 'JST-9',
          description: 'Japan Standard Time',
          utcOffsetMinutes: 540,
        ),
      ];

      // Act
      await service.saveTimezoneSettings(
        settings: settings,
        supportedTimezones: supportedTimezones,
      );

      // Assert - DST should be false because the timezone doesn't support it
      verify(() => mockRepository.send(
            JNAPAction.setTimeSettings,
            data: {
              'timeZoneID': 'JST-9',
              'autoAdjustForDST': false,
            },
            auth: true,
          )).called(1);
    });

    test('throws ServiceError on JNAP failure', () async {
      // Arrange
      when(() => mockRepository.send(
            JNAPAction.setTimeSettings,
            data: any(named: 'data'),
            auth: true,
          )).thenThrow(InstantAdminTestData.createGenericError());

      final settings = const TimezoneSettings(
        timezoneId: 'PST8',
        isDaylightSaving: true,
      );
      final supportedTimezones = [
        const SupportedTimezone(
          observesDST: true,
          timeZoneID: 'PST8',
          description: 'Pacific Time',
          utcOffsetMinutes: -480,
        ),
      ];

      // Act & Assert
      expect(
        () => service.saveTimezoneSettings(
          settings: settings,
          supportedTimezones: supportedTimezones,
        ),
        throwsA(isA<ServiceError>()),
      );
    });
  });
}

/// Custom matcher for checking if a list is sorted in ascending order
const Matcher isSortedList = _IsSortedList();

class _IsSortedList extends Matcher {
  const _IsSortedList();

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! List<int>) return false;
    for (int i = 0; i < item.length - 1; i++) {
      if (item[i] > item[i + 1]) return false;
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('is a sorted list in ascending order');
}
