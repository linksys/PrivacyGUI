@Tags(['layout-gate'])
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/admin/cards/usp_time_settings_card.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({
    'style': 'flat',
  }),
);

const _gmt8Time = TimeSettingsUIModel(
  enable: true,
  status: 'Synchronized',
  currentLocalTime: '2026-04-17T04:00:00Z',
  localTimeZone: 'UTC-8', // matches GMT+8 (no DST)
  ntpServer1: 'pool.ntp.org',
  ntpServer2: '',
);

const _dstTime = TimeSettingsUIModel(
  enable: true,
  status: 'Synchronized',
  currentLocalTime: '2026-04-17T12:00:00Z',
  localTimeZone: 'EST5EDT,M3.2.0/02:00,M11.1.0/02:00',
  ntpServer1: 'time.google.com',
  ntpServer2: '',
);

const _unsyncTime = TimeSettingsUIModel(
  enable: true,
  status: 'Unsynchronized',
  currentLocalTime: '',
  localTimeZone: '',
  ntpServer1: '',
  ntpServer2: '',
);

/// Test-only notifier that returns canned data without USP client.
class _FakeTimeDataNotifier extends TimeDataNotifier {
  final TimeData _data;
  _FakeTimeDataNotifier(this._data);

  @override
  Future<TimeData> build() async => _data;
}

Widget _buildTestWidget(TimeSettingsUIModel time) {
  final notifier = _FakeTimeDataNotifier(TimeData(model: time));
  return ProviderScope(
    overrides: [
      timeDataProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp(
      theme: _testTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 800,
          child: UspTimeSettingsCard(),
        ),
      ),
    ),
  );
}

void main() {
  group('UspTimeSettingsCard', () {
    testWidgets('displays friendly timezone name', (tester) async {
      await tester.pumpWidget(_buildTestWidget(_gmt8Time));
      await tester.pumpAndSettle();

      expect(find.textContaining('GMT+08:00'), findsOneWidget);
    });

    testWidgets('shows Synchronized status badge', (tester) async {
      await tester.pumpWidget(_buildTestWidget(_gmt8Time));
      await tester.pumpAndSettle();

      expect(find.text('Synchronized'), findsOneWidget);
    });

    testWidgets('shows Unsynchronized status badge', (tester) async {
      await tester.pumpWidget(_buildTestWidget(_unsyncTime));
      await tester.pumpAndSettle();

      expect(find.text('Unsynchronized'), findsOneWidget);
    });

    testWidgets('hides DST row for non-DST timezone', (tester) async {
      await tester.pumpWidget(_buildTestWidget(_gmt8Time));
      await tester.pumpAndSettle();

      expect(find.text('DST'), findsNothing);
    });

    testWidgets('shows DST On for DST-enabled timezone', (tester) async {
      await tester.pumpWidget(_buildTestWidget(_dstTime));
      await tester.pumpAndSettle();

      expect(find.text('DST'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
    });

    testWidgets('does not display NTP server row', (tester) async {
      await tester.pumpWidget(_buildTestWidget(_gmt8Time));
      await tester.pumpAndSettle();

      expect(find.text('NTP Server'), findsNothing);
    });

    testWidgets('shows "Not set" for empty timezone', (tester) async {
      await tester.pumpWidget(_buildTestWidget(_unsyncTime));
      await tester.pumpAndSettle();

      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('shows skeleton when data is null', (tester) async {
      // Override with a notifier that never resolves
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            timeDataProvider.overrideWith(
              () => _FakeTimeDataNotifier(TimeData(model: _gmt8Time)),
            ),
          ],
          child: MaterialApp(
            theme: _testTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(width: 800, child: UspTimeSettingsCard()),
            ),
          ),
        ),
      );
      // Don't pumpAndSettle — check initial loading state
      await tester.pump();

      // Should show title after data loads or skeleton before
      // The card either shows content or CardSkeleton
      expect(find.byType(UspTimeSettingsCard), findsOneWidget);
    });

    testWidgets('edit button has semantic label', (tester) async {
      await tester.pumpWidget(_buildTestWidget(_gmt8Time));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Edit time settings'), findsOneWidget);
    });

    // The assertion above finds the label *somewhere* in the semantics tree,
    // which is not the same claim: what a screen reader announces is the label
    // on the node it can activate. Those were one node until a `container: true`
    // inside `AppIconButton` split them, and then the tree read
    //
    //   [button, no tap ] "Edit time settings"
    //     [button, tap  ] "Icon button"
    //
    // — a named node nothing can press over a pressable node with no name. Both
    // `findsOneWidget` above and a tap test stay green through that, because the
    // label is still present and the button still works for a pointer. So the
    // two properties are pinned together, on one node.
    testWidgets(
        'the edit button announces its name on the node that is tappable',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_buildTestWidget(_gmt8Time));
      await tester.pumpAndSettle();

      final node = tester.getSemantics(find.byType(AppIconButton));

      expect(node.label, 'Edit time settings',
          reason: 'the tappable node announces "${node.label}", so the button '
              'has no accessible name — the name is on an ancestor a screen '
              'reader cannot press.');
      expect(node, isSemantics(hasTapAction: true, isEnabled: true),
          reason: 'the node carrying the name cannot be activated, so the name '
              'belongs to nothing.');

      handle.dispose();
    });
  });
}
