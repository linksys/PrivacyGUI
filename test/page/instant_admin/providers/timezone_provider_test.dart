import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_state.dart';

import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';

/// `GetTimeSettings` output: the router's zone, its DST switch, and the zones
/// it supports, in the router's own order.
const _timeSettings = <String, dynamic>{
  'timeZoneID': 'AEST-10',
  'autoAdjustForDST': true,
  'currentTime': '2026-11-25T10:00:00+1000',
  'supportedTimeZones': [
    {
      'observesDST': true,
      'timeZoneID': 'AEST-10',
      'description': '(GMT+10:00) Australia',
      'utcOffsetMinutes': 600,
    },
    {
      'observesDST': false,
      'timeZoneID': 'MST7-NO-DST',
      'description': '(GMT-07:00) Arizona',
      'utcOffsetMinutes': -420,
    },
    {
      'observesDST': false,
      'timeZoneID': 'GMT0-NO-DST',
      'description': '(GMT) Gambia, Liberia, Morocco',
      'utcOffsetMinutes': 0,
    },
    {
      'observesDST': true,
      'timeZoneID': 'NST03:30',
      'description': '(GMT-03:30) Newfoundland',
      'utcOffsetMinutes': -210,
    },
  ],
};

void main() {
  late RouterBoundary router;
  late RecordingPolling polling;
  late ProviderContainer container;

  TimezoneNotifier notifier() => container.read(timezoneProvider.notifier);
  TimezoneState page() => container.read(timezoneProvider);

  /// The index of [id] in the list the page shows.
  int indexOf(String id) =>
      page().supportedTimezones.indexWhere((zone) => zone.timeZoneID == id);

  setUp(() {
    router = RouterBoundary()..holds(JNAPAction.getTimeSettings, _timeSettings);
    polling = RecordingPolling();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => polling),
    ]);
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('reads the router zone and its DST switch', () async {
      await notifier().fetch();

      expect(page().timezoneId, 'AEST-10');
      expect(page().isDaylightSaving, isTrue);
    });

    test('lists the zones from west to east', () async {
      await notifier().fetch();

      expect(page().supportedTimezones.map((zone) => zone.timeZoneID),
          ['MST7-NO-DST', 'NST03:30', 'GMT0-NO-DST', 'AEST-10']);
    });

    test('falls back to PST8 with DST off when the router names neither',
        () async {
      router.holds(JNAPAction.getTimeSettings, {
        'supportedTimeZones': _timeSettings['supportedTimeZones'],
      });

      await notifier().fetch();

      expect(page().timezoneId, 'PST8');
      expect(page().isDaylightSaving, isFalse);
    });

    test('says which listed zone is the router zone and whether it has DST',
        () async {
      await notifier().fetch();

      expect(notifier().isSelectedTimezone(indexOf('AEST-10')), isTrue);
      expect(notifier().isSelectedTimezone(indexOf('NST03:30')), isFalse);
      expect(notifier().isSupportDaylightSaving(), isTrue);

      notifier().setSelectedTimezone(indexOf('MST7-NO-DST'));

      expect(notifier().isSupportDaylightSaving(), isFalse);
    });

    test('reports no DST for a zone the router does not list', () {
      // Before any fetch the page holds PST8 and an empty list.
      expect(notifier().isSupportDaylightSaving(), isFalse);
    });
  });

  group('save', () {
    setUp(() => notifier().fetch());

    test('writes the chosen zone with DST on when the zone observes it',
        () async {
      notifier().setSelectedTimezone(indexOf('NST03:30'));

      await notifier().save();

      expect(router.payloadsOf(JNAPAction.setTimeSettings).single, {
        'timeZoneID': 'NST03:30',
        'autoAdjustForDST': true,
      });
    });

    test('writes DST off when the user turns it off', () async {
      notifier().setDaylightSaving(false);

      await notifier().save();

      expect(router.payloadsOf(JNAPAction.setTimeSettings).single, {
        'timeZoneID': 'AEST-10',
        'autoAdjustForDST': false,
      });
    });

    test('writes DST off for a zone without DST, whatever the switch says',
        () async {
      notifier()
        ..setSelectedTimezone(indexOf('GMT0-NO-DST'))
        ..setDaylightSaving(true);

      await notifier().save();

      expect(router.payloadsOf(JNAPAction.setTimeSettings).single, {
        'timeZoneID': 'GMT0-NO-DST',
        'autoAdjustForDST': false,
      });
    });

    test('reads the settings back and polls at once after the save', () async {
      router.holds(JNAPAction.getTimeSettings,
          {..._timeSettings, 'timeZoneID': 'NST03:30'});
      notifier().setSelectedTimezone(indexOf('NST03:30'));

      await notifier().save();

      expect(router.actions.where((a) => a == JNAPAction.getTimeSettings),
          hasLength(2));
      expect(page().timezoneId, 'NST03:30');
      expect(polling.forced, 1);
    });

    test('a refused save throws, reads nothing back and does not poll',
        () async {
      router.refuses(JNAPAction.setTimeSettings,
          result: 'ErrorInvalidTimeZone');
      notifier().setSelectedTimezone(indexOf('NST03:30'));

      await expectLater(
          notifier().save(),
          throwsA(isA<JNAPError>()
              .having((e) => e.result, 'result', 'ErrorInvalidTimeZone')));

      expect(router.actions.where((a) => a == JNAPAction.getTimeSettings),
          hasLength(1));
      expect(polling.forced, 0);
    });
  });
}
