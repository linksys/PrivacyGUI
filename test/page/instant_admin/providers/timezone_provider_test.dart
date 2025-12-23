import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/models/timezone.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_state.dart';
import 'package:privacy_gui/page/instant_admin/services/timezone_service.dart';

class MockTimezoneService extends Mock implements TimezoneService {}

void main() {
  late MockTimezoneService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockTimezoneService();
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        timezoneServiceProvider.overrideWithValue(mockService),
      ],
    );
  }

  group('TimezoneNotifier - build()', () {
    test('returns initial state', () {
      // Arrange
      container = createContainer();

      // Act
      final state = container.read(timezoneProvider);

      // Assert
      expect(state.settings.current.timezoneId, 'PST8');
      expect(state.settings.current.isDaylightSaving, true);
      expect(state.status.supportedTimezones, isEmpty);
    });
  });

  group('TimezoneNotifier - performFetch()', () {
    test(
        'calls service.fetchTimezoneSettings with forceRemote false by default',
        () async {
      // Arrange
      container = createContainer();
      when(() => mockService.fetchTimezoneSettings(forceRemote: false))
          .thenAnswer((_) async => (
                const TimezoneSettings(
                  timezoneId: 'EST5EDT',
                  isDaylightSaving: true,
                ),
                const TimezoneStatus(
                  supportedTimezones: [
                    SupportedTimezone(
                      observesDST: true,
                      timeZoneID: 'EST5EDT',
                      description: 'Eastern Time',
                      utcOffsetMinutes: -300,
                    ),
                  ],
                ),
              ));

      // Act
      final notifier = container.read(timezoneProvider.notifier);
      final result = await notifier.performFetch();

      // Assert
      expect(result.$1.timezoneId, 'EST5EDT');
      expect(result.$2.supportedTimezones.length, 1);
      verify(() => mockService.fetchTimezoneSettings(forceRemote: false))
          .called(1);
    });

    test(
        'calls service.fetchTimezoneSettings with forceRemote true when specified',
        () async {
      // Arrange
      container = createContainer();
      when(() => mockService.fetchTimezoneSettings(forceRemote: true))
          .thenAnswer((_) async => (
                const TimezoneSettings(
                  timezoneId: 'PST8',
                  isDaylightSaving: false,
                ),
                const TimezoneStatus(supportedTimezones: []),
              ));

      // Act
      final notifier = container.read(timezoneProvider.notifier);
      await notifier.performFetch(forceRemote: true);

      // Assert
      verify(() => mockService.fetchTimezoneSettings(forceRemote: true))
          .called(1);
    });
  });

  group('TimezoneNotifier - isSelectedTimezone()', () {
    test('returns true when timezone matches current selection', () async {
      // Arrange
      container = createContainer();
      when(() => mockService
              .fetchTimezoneSettings(forceRemote: any(named: 'forceRemote')))
          .thenAnswer((_) async => (
                const TimezoneSettings(
                  timezoneId: 'PST8',
                  isDaylightSaving: true,
                ),
                const TimezoneStatus(
                  supportedTimezones: [
                    SupportedTimezone(
                      observesDST: true,
                      timeZoneID: 'PST8',
                      description: 'Pacific Time',
                      utcOffsetMinutes: -480,
                    ),
                    SupportedTimezone(
                      observesDST: true,
                      timeZoneID: 'EST5EDT',
                      description: 'Eastern Time',
                      utcOffsetMinutes: -300,
                    ),
                  ],
                ),
              ));

      final notifier = container.read(timezoneProvider.notifier);
      await notifier.fetch();

      // Act & Assert
      expect(notifier.isSelectedTimezone(0), true); // PST8 is selected
      expect(notifier.isSelectedTimezone(1), false); // EST5EDT is not selected
    });
  });

  group('TimezoneNotifier - isSupportDaylightSaving()', () {
    test('returns true when current timezone supports DST', () async {
      // Arrange
      container = createContainer();
      when(() => mockService
              .fetchTimezoneSettings(forceRemote: any(named: 'forceRemote')))
          .thenAnswer((_) async => (
                const TimezoneSettings(
                  timezoneId: 'PST8',
                  isDaylightSaving: true,
                ),
                const TimezoneStatus(
                  supportedTimezones: [
                    SupportedTimezone(
                      observesDST: true,
                      timeZoneID: 'PST8',
                      description: 'Pacific Time',
                      utcOffsetMinutes: -480,
                    ),
                  ],
                ),
              ));

      final notifier = container.read(timezoneProvider.notifier);
      await notifier.fetch();

      // Act & Assert
      expect(notifier.isSupportDaylightSaving(), true);
    });

    test('returns false when current timezone does not support DST', () async {
      // Arrange
      container = createContainer();
      when(() => mockService
              .fetchTimezoneSettings(forceRemote: any(named: 'forceRemote')))
          .thenAnswer((_) async => (
                const TimezoneSettings(
                  timezoneId: 'JST-9',
                  isDaylightSaving: false,
                ),
                const TimezoneStatus(
                  supportedTimezones: [
                    SupportedTimezone(
                      observesDST: false,
                      timeZoneID: 'JST-9',
                      description: 'Japan Standard Time',
                      utcOffsetMinutes: 540,
                    ),
                  ],
                ),
              ));

      final notifier = container.read(timezoneProvider.notifier);
      await notifier.fetch();

      // Act & Assert
      expect(notifier.isSupportDaylightSaving(), false);
    });

    test('returns false when timezone not found in supportedTimezones', () {
      // Arrange
      container = createContainer();

      // Initial state has empty supportedTimezones
      final notifier = container.read(timezoneProvider.notifier);

      // Act & Assert
      expect(notifier.isSupportDaylightSaving(), false);
    });
  });

  group('TimezoneNotifier - setSelectedTimezone()', () {
    test('updates current settings with selected timezone', () async {
      // Arrange
      container = createContainer();
      when(() => mockService
              .fetchTimezoneSettings(forceRemote: any(named: 'forceRemote')))
          .thenAnswer((_) async => (
                const TimezoneSettings(
                  timezoneId: 'PST8',
                  isDaylightSaving: true,
                ),
                const TimezoneStatus(
                  supportedTimezones: [
                    SupportedTimezone(
                      observesDST: true,
                      timeZoneID: 'PST8',
                      description: 'Pacific Time',
                      utcOffsetMinutes: -480,
                    ),
                    SupportedTimezone(
                      observesDST: false,
                      timeZoneID: 'JST-9',
                      description: 'Japan Standard Time',
                      utcOffsetMinutes: 540,
                    ),
                  ],
                ),
              ));

      final notifier = container.read(timezoneProvider.notifier);
      await notifier.fetch();

      // Act
      notifier.setSelectedTimezone(1); // Select JST-9

      // Assert
      final state = container.read(timezoneProvider);
      expect(state.settings.current.timezoneId, 'JST-9');
      expect(state.settings.current.isDaylightSaving, false);
    });
  });

  group('TimezoneNotifier - setDaylightSaving()', () {
    test('updates isDaylightSaving in current settings', () {
      // Arrange
      container = createContainer();
      final notifier = container.read(timezoneProvider.notifier);

      // Initial state has isDaylightSaving = true
      expect(container.read(timezoneProvider).settings.current.isDaylightSaving,
          true);

      // Act
      notifier.setDaylightSaving(false);

      // Assert
      expect(container.read(timezoneProvider).settings.current.isDaylightSaving,
          false);
    });

    test('can toggle isDaylightSaving multiple times', () {
      // Arrange
      container = createContainer();
      final notifier = container.read(timezoneProvider.notifier);

      // Act & Assert
      notifier.setDaylightSaving(false);
      expect(container.read(timezoneProvider).settings.current.isDaylightSaving,
          false);

      notifier.setDaylightSaving(true);
      expect(container.read(timezoneProvider).settings.current.isDaylightSaving,
          true);
    });
  });
}
