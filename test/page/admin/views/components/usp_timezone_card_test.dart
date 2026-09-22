@Tags(['layout-gate'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/admin/views/components/usp_timezone_card.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({
    'style': 'flat',
  }),
);

Widget _buildTestWidget({
  required TimeSettingsUIModel timeSettings,
  VoidCallback? onEdit,
}) {
  return MaterialApp(
    theme: _testTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 800,
        child: UspTimezoneCard(
          timeSettings: timeSettings,
          onEdit: onEdit ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  group('UspTimezoneCard', () {
    const gmt8Settings = TimeSettingsUIModel(
      enable: true,
      status: 'Synchronized',
      currentLocalTime: '2026-04-17T04:00:00Z',
      // A legacy value: `UTC-8` matches **HKT-8-NO-DST**, not SGT-8-NO-DST as
      // the comment here used to claim. Both zones stored this one string, and
      // `matchTimezone` returns whichever comes first, which is Hong Kong —
      // the bug #1609 fixes, mis-documented in the test that rendered it.
      localTimeZone: 'UTC-8',
      ntpServer1: 'pool.ntp.org',
      ntpServer2: '',
    );

    testWidgets('displays friendly timezone name', (tester) async {
      await tester.pumpWidget(_buildTestWidget(timeSettings: gmt8Settings));
      await tester.pumpAndSettle();

      expect(find.textContaining('China, Hong Kong, Australia Western'),
          findsOneWidget);
      expect(find.textContaining('GMT+08:00'), findsOneWidget);
    });

    // #1609: this replaces `hides DST row for non-DST timezone`. The row used to
    // be gated on `observesDST`, which is how saving a DST-capable zone with DST
    // off — landing on the equivalent non-DST zone — made the option vanish.
    // It now states the selected zone's own DST property and stays put.
    testWidgets('shows DST Off, rather than nothing, for a non-DST zone',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(timeSettings: gmt8Settings));
      await tester.pumpAndSettle();

      expect(find.text('Daylight Savings Time'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('shows DST row for DST-capable timezone with DST on',
        (tester) async {
      const dstSettings = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '2026-04-17T12:00:00Z',
        localTimeZone: 'EST5EDT,M3.2.0/02:00,M11.1.0/02:00',
        ntpServer1: 'pool.ntp.org',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: dstSettings));
      await tester.pumpAndSettle();

      expect(find.text('Daylight Savings Time'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
    });

    // #1609: this replaces `shows DST Off for DST-capable timezone with DST off`,
    // whose premise no longer exists — DST is a property of the zone, so a
    // DST-capable zone cannot be saved with DST off. What remains worth pinning
    // is that a legacy router still holding the old `UTC±N` reads correctly: the
    // string resolves to the non-DST sibling, and the row says Off because that
    // sibling does not observe DST (AC8).
    testWidgets('a legacy UTC±N string reads as its non-DST sibling',
        (tester) async {
      const legacy = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        // What releases up to 2.7.1 wrote for GMT-05:00 with DST off.
        currentLocalTime: '2026-04-17T07:00:00-05:00',
        localTimeZone: 'UTC5',
        ntpServer1: 'pool.ntp.org',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: legacy));
      await tester.pumpAndSettle();

      expect(find.textContaining('Indiana East'), findsOneWidget);
      expect(find.text('Daylight Savings Time'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
    });

    // #1609 remediation. `UTC8` is owned only by `PST8`, which observes DST, so
    // reading `observesDST` off the resolved entry announced daylight savings on
    // a router 2.7.1 left at a fixed UTC-8. The string has no transitions in it.
    testWidgets('a legacy UTC8 reads DST Off, not On', (tester) async {
      const legacy = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '2026-09-22T06:30:00-08:00',
        localTimeZone: 'UTC8',
        ntpServer1: 'pool.ntp.org',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: legacy));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pacific Time'), findsOneWidget);
      expect(find.text('Daylight Savings Time'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('On'), findsNothing);
    });

    // #1609 AC5: the pair that no POSIX string could tell apart.
    testWidgets('the zone name picks Singapore over Hong Kong', (tester) async {
      const sg = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '2026-09-22T18:30:00+08:00',
        // Both zones are GMT+8 with no DST. The POSIX string the firmware
        // derived is the same one it would derive for Hong Kong; only the name
        // separates them.
        localTimeZone: 'CST-8',
        localTimeZoneName: 'Asia/Singapore',
        ntpServer1: 'pool.ntp.org',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: sg));
      await tester.pumpAndSettle();

      expect(find.textContaining('Singapore'), findsOneWidget);
      expect(find.textContaining('Hong Kong'), findsNothing);
    });

    testWidgets('displays NTP server', (tester) async {
      await tester.pumpWidget(_buildTestWidget(timeSettings: gmt8Settings));
      await tester.pumpAndSettle();

      expect(find.text('NTP Server'), findsOneWidget);
      expect(find.text('pool.ntp.org'), findsOneWidget);
    });

    testWidgets('shows dash when NTP server is empty', (tester) async {
      const noNtp = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '',
        localTimeZone: 'UTC-8',
        ntpServer1: '',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: noNtp));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('displays status as badge', (tester) async {
      await tester.pumpWidget(_buildTestWidget(timeSettings: gmt8Settings));
      await tester.pumpAndSettle();

      // Status is now shown as a badge in the title row, not as an info row
      expect(find.text('Status'), findsNothing);
      expect(find.text('Synchronized'), findsOneWidget);
    });

    testWidgets('shows "Not set" for empty timezone', (tester) async {
      const emptyTz = TimeSettingsUIModel(
        enable: true,
        status: 'Unsynchronized',
        currentLocalTime: '',
        localTimeZone: '',
        ntpServer1: '',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: emptyTz));
      await tester.pumpAndSettle();

      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('shows raw POSIX for unrecognized timezone', (tester) async {
      const unknownTz = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '',
        localTimeZone: 'WEIRD_TZ_STRING',
        ntpServer1: '',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: unknownTz));
      await tester.pumpAndSettle();

      expect(find.text('WEIRD_TZ_STRING'), findsOneWidget,
          reason: 'with no reported offset there is nothing truer to show, so '
              'the raw string stays the last resort.');
    });

    // #1609 AC9. An unrecognized zone is the ordinary case on FLWRT 2.0, not an
    // edge: the factory value is a bare `UTC` and 81 of the 89 zones the device
    // publishes have no entry of ours. We cannot name the region, but the device
    // reports its offset on every read, so show that rather than a POSIX string.
    testWidgets('shows the reported offset, not the raw POSIX string',
        (tester) async {
      const unknownTz = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        // `CST-8` is the device's own value for Asia/Taipei.
        currentLocalTime: '2026-09-22T18:30:00+08:00',
        localTimeZone: 'CST-8',
        ntpServer1: '',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: unknownTz));
      await tester.pumpAndSettle();

      expect(find.text('GMT+08:00'), findsOneWidget);
      expect(find.text('CST-8'), findsNothing);
    });

    testWidgets('shows GMT+00:00 for the factory-default bare UTC',
        (tester) async {
      const factoryTz = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '2026-09-22T03:10:17+00:00',
        // What a factory-fresh FLWRT 2.0 box ships with. The table carries
        // `UTC0`, not `UTC`, so it has never matched.
        localTimeZone: 'UTC',
        ntpServer1: '',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: factoryTz));
      await tester.pumpAndSettle();

      expect(find.text('GMT+00:00'), findsOneWidget);
    });

    testWidgets('edit button triggers onEdit callback', (tester) async {
      var editTapped = false;
      await tester.pumpWidget(_buildTestWidget(
        timeSettings: gmt8Settings,
        onEdit: () => editTapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      expect(editTapped, isTrue);
    });

    testWidgets('edit button has semantic label', (tester) async {
      await tester.pumpWidget(_buildTestWidget(timeSettings: gmt8Settings));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Edit timezone settings'), findsOneWidget);
    });

    // Same pairing as `usp_time_settings_card_test.dart` — see the note there
    // for why "the label exists" and "the pressable node is named" are two
    // claims, and why the first one stays green while the second breaks.
    testWidgets(
        'the edit button announces its name on the node that is tappable',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_buildTestWidget(timeSettings: gmt8Settings));
      await tester.pumpAndSettle();

      final node = tester.getSemantics(find.byType(AppIconButton));

      expect(node.label, 'Edit timezone settings',
          reason: 'the tappable node announces "${node.label}", so the button '
              'has no accessible name — the name is on an ancestor a screen '
              'reader cannot press.');
      expect(node, isSemantics(hasTapAction: true, isEnabled: true),
          reason: 'the node carrying the name cannot be activated, so the name '
              'belongs to nothing.');

      handle.dispose();
    });

    testWidgets('displays initial local time correctly', (tester) async {
      const settings = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '2026-04-17T12:00:00',
        localTimeZone: 'UTC-8',
        ntpServer1: 'pool.ntp.org',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: settings));
      await tester.pump();

      expect(find.text('2026-04-17 12:00:00'), findsOneWidget);
    });

    testWidgets('re-syncs time when timeSettings changes', (tester) async {
      const initial = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '2026-04-17T12:00:00',
        localTimeZone: 'UTC-8',
        ntpServer1: 'pool.ntp.org',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: initial));
      await tester.pump();
      expect(find.text('2026-04-17 12:00:00'), findsOneWidget);

      const updated = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '2026-04-17T20:00:00',
        localTimeZone: 'UTC-8',
        ntpServer1: 'pool.ntp.org',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: updated));
      await tester.pump();
      expect(find.text('2026-04-17 20:00:00'), findsOneWidget);
    });

    // #1609 AC4. The model's own suite pins the arithmetic; these two pin that
    // the card renders it, because the defect was invisible to every test above
    // — they all use a `Z` suffix or no offset at all, the one shape the broken
    // branch never ran on. Both readings are from the bench (M60TB-EU,
    // FLWRT 2.0.x).
    testWidgets('renders the device clock while DST is in force',
        (tester) async {
      const settings = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        // The firmware applies the POSIX rule, so July reports -07:00 for a
        // zone whose standard offset is -08:00. Re-deriving from the table's
        // standard offset showed 13:00.
        currentLocalTime: '2026-07-15T14:00:00-07:00',
        localTimeZone: 'PST8PDT,M3.2.0/02:00,M11.1.0/02:00',
        ntpServer1: 'pool.ntp.org',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: settings));
      await tester.pump();

      expect(find.text('2026-07-15 14:00:00'), findsOneWidget);
    });

    testWidgets('renders the device clock for a zone the table cannot match',
        (tester) async {
      const settings = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        // `CST-8` is the device's own value for Asia/Taipei. Dropping the
        // offset with nothing to put back showed 10:30, i.e. UTC.
        currentLocalTime: '2026-09-22T18:30:00+08:00',
        localTimeZone: 'CST-8',
        ntpServer1: 'pool.ntp.org',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: settings));
      await tester.pump();

      expect(find.text('2026-09-22 18:30:00'), findsOneWidget);
    });
  });
}
