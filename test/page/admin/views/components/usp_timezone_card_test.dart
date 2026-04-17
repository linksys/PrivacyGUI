@Tags(['ui'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/ui_kit.dart';
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
      localTimeZone: 'UTC-8', // matches SGT-8-NO-DST (GMT+8, no DST)
      ntpServer1: 'pool.ntp.org',
      ntpServer2: '',
    );

    testWidgets('displays friendly timezone name', (tester) async {
      await tester.pumpWidget(_buildTestWidget(timeSettings: gmt8Settings));
      await tester.pumpAndSettle();

      // SGT-8-NO-DST → "China, Hong Kong, Australia Western (GMT+08:00)"
      // or "Singapore, Taiwan, Russia (GMT+08:00)" depending on match order
      expect(find.textContaining('GMT+08:00'), findsOneWidget);
    });

    testWidgets('hides DST row for non-DST timezone', (tester) async {
      await tester.pumpWidget(_buildTestWidget(timeSettings: gmt8Settings));
      await tester.pumpAndSettle();

      expect(find.text('Daylight Savings Time'), findsNothing);
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

    testWidgets('shows DST Off for DST-capable timezone with DST off',
        (tester) async {
      const dstOffSettings = TimeSettingsUIModel(
        enable: true,
        status: 'Synchronized',
        currentLocalTime: '2026-04-17T12:00:00Z',
        localTimeZone: 'UTC5', // matches EST5 posixNoDST (DST off)
        ntpServer1: 'pool.ntp.org',
        ntpServer2: '',
      );
      await tester.pumpWidget(_buildTestWidget(timeSettings: dstOffSettings));
      await tester.pumpAndSettle();

      expect(find.text('Daylight Savings Time'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
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

    testWidgets('displays status', (tester) async {
      await tester.pumpWidget(_buildTestWidget(timeSettings: gmt8Settings));
      await tester.pumpAndSettle();

      expect(find.text('Status'), findsOneWidget);
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

      expect(find.text('WEIRD_TZ_STRING'), findsOneWidget);
    });

    testWidgets('edit button triggers onEdit callback', (tester) async {
      var editTapped = false;
      await tester.pumpWidget(_buildTestWidget(
        timeSettings: gmt8Settings,
        onEdit: () => editTapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_right));
      expect(editTapped, isTrue);
    });

    testWidgets('edit button has semantic label', (tester) async {
      await tester.pumpWidget(_buildTestWidget(timeSettings: gmt8Settings));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Edit timezone settings'), findsOneWidget);
    });
  });
}
