@Tags(['ui'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/wifi_channel_dialog.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({
    'style': 'flat',
  }),
);

WifiRadioUIModel _radio({
  String band = '5GHz',
  int channel = 36,
  bool autoChannelEnable = false,
  bool isDfsEnabled = true,
  List<int> possibleChannels = const [36, 40, 44, 48, 52, 149],
}) {
  return WifiRadioUIModel(
    instancePath: 'Device.WiFi.Radio.1.',
    band: band,
    enable: true,
    transmitPower: 100,
    maxBitRate: 1200,
    channel: channel,
    autoChannelEnable: autoChannelEnable,
    channelBandwidth: '80MHz',
    supportedStandards: 'ax',
    possibleChannels: possibleChannels,
    isDfsEnabled: isDfsEnabled,
  );
}

/// White-box widget tests for [WifiChannelDialog].
void main() {
  Widget host(WifiRadioUIModel radio,
      void Function(({int channel, bool autoChannel})?) onResult) {
    return MaterialApp(
      theme: _testTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                final r = await showDialog<({int channel, bool autoChannel})>(
                  context: context,
                  builder: (_) => WifiChannelDialog(radio: radio),
                );
                onResult(r);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('WifiChannelDialog', () {
    testWidgets('AC1: renders an AppDropdown, not an AppTextField', (t) async {
      await t.pumpWidget(host(_radio(), (_) {}));
      await openDialog(t);

      expect(find.byType(AppDropdown<int>), findsOneWidget);
      expect(find.byType(AppTextField), findsNothing);
    });

    testWidgets('AC4: selecting Auto when already auto is a no-op (null)',
        (t) async {
      ({int channel, bool autoChannel})? captured;
      var called = false;
      await t.pumpWidget(host(
        _radio(channel: 36, autoChannelEnable: true),
        (r) {
          captured = r;
          called = true;
        },
      ));
      await openDialog(t);

      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();

      expect(called, isTrue);
      expect(captured, isNull);
    });

    testWidgets(
        'AC3/AC4: turning Auto OFF then Apply returns the stored manual channel',
        (t) async {
      ({int channel, bool autoChannel})? captured;
      await t.pumpWidget(host(
        _radio(channel: 44, autoChannelEnable: true),
        (r) => captured = r,
      ));
      await openDialog(t);

      // Auto switch is ON initially; toggle it OFF.
      await t.tap(find.byType(AppSwitch));
      await t.pumpAndSettle();

      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.autoChannel, isFalse);
      expect(captured!.channel, 44);
    });

    testWidgets(
        'AC4: switching a manual channel to Auto returns autoChannel:true',
        (t) async {
      ({int channel, bool autoChannel})? captured;
      await t.pumpWidget(host(
        _radio(channel: 44, autoChannelEnable: false),
        (r) => captured = r,
      ));
      await openDialog(t);

      // Auto switch is OFF initially; toggle it ON.
      await t.tap(find.byType(AppSwitch));
      await t.pumpAndSettle();

      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.autoChannel, isTrue);
    });

    testWidgets(
        'AC5: stored channel not in possibleChannels displays as Auto, and '
        'confirming without moving is a no-op', (t) async {
      ({int channel, bool autoChannel})? captured;
      var called = false;
      await t.pumpWidget(host(
        // channel 165 is not in the possibleChannels list.
        _radio(
            channel: 165,
            autoChannelEnable: false,
            possibleChannels: const [36, 40, 44]),
        (r) {
          captured = r;
          called = true;
        },
      ));
      await openDialog(t);

      // The switch should reflect Auto (ghost value suppressed).
      final sw = t.widget<AppSwitch>(find.byType(AppSwitch));
      expect(sw.value, isTrue);

      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();

      // The dialog opened on Auto because 165 is unselectable; the user did not
      // move the selection, so Apply must NOT rewrite the radio to Auto.
      expect(called, isTrue);
      expect(captured, isNull);
    });

    testWidgets(
        'AC6: empty possibleChannels locks to Auto and shows the no-options text',
        (t) async {
      ({int channel, bool autoChannel})? captured;
      await t.pumpWidget(host(
        _radio(
            channel: 36, autoChannelEnable: true, possibleChannels: const []),
        (r) => captured = r,
      ));
      await openDialog(t);

      expect(find.text('No manual channels available for this band.'),
          findsOneWidget);

      // Switch is disabled (no manual channels to switch to).
      final sw = t.widget<AppSwitch>(find.byType(AppSwitch));
      expect(sw.onChanged, isNull);

      // Dropdown is disabled.
      final dd = t.widget<AppDropdown<int>>(find.byType(AppDropdown<int>));
      expect(dd.onChanged, isNull);

      // Apply is still valid (Auto, unchanged here -> no-op null).
      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();
      expect(captured, isNull);
    });

    testWidgets('AC3: dropdown disabled while Auto switch is ON', (t) async {
      await t.pumpWidget(host(
        _radio(channel: 36, autoChannelEnable: true),
        (_) {},
      ));
      await openDialog(t);

      final dd = t.widget<AppDropdown<int>>(find.byType(AppDropdown<int>));
      expect(dd.onChanged, isNull);
    });

    testWidgets('AC3: dropdown enabled while Auto switch is OFF', (t) async {
      await t.pumpWidget(host(
        _radio(channel: 36, autoChannelEnable: false),
        (_) {},
      ));
      await openDialog(t);

      final dd = t.widget<AppDropdown<int>>(find.byType(AppDropdown<int>));
      expect(dd.onChanged, isNotNull);
    });

    testWidgets('AC9: 5GHz DFS channel is annotated with the DFS suffix',
        (t) async {
      await t.pumpWidget(host(
        _radio(
            band: '5GHz',
            channel: 52,
            autoChannelEnable: false,
            possibleChannels: const [36, 52]),
        (_) {},
      ));
      await openDialog(t);

      final dd = t.widget<AppDropdown<int>>(find.byType(AppDropdown<int>));
      // 52 is a DFS channel -> "52 · DFS"; 36 is not.
      expect(dd.itemAsString!(52), '52 · DFS');
      expect(dd.itemAsString!(36), '36');
    });

    testWidgets('#1025: DFS disabled hides 5GHz DFS channels from the dropdown',
        (t) async {
      await t.pumpWidget(host(
        _radio(
          band: '5GHz',
          channel: 36,
          autoChannelEnable: false,
          isDfsEnabled: false,
          possibleChannels: const [36, 40, 44, 48, 52, 100, 149],
        ),
        (_) {},
      ));
      await openDialog(t);

      final dd = t.widget<AppDropdown<int>>(find.byType(AppDropdown<int>));
      // -1 is the Auto sentinel; DFS channels 52 and 100 must be gone.
      expect(dd.items, [-1, 36, 40, 44, 48, 149]);
    });

    testWidgets('#1025: DFS enabled keeps 5GHz DFS channels in the dropdown',
        (t) async {
      await t.pumpWidget(host(
        _radio(
          band: '5GHz',
          channel: 36,
          autoChannelEnable: false,
          isDfsEnabled: true,
          possibleChannels: const [36, 40, 44, 48, 52, 100, 149],
        ),
        (_) {},
      ));
      await openDialog(t);

      final dd = t.widget<AppDropdown<int>>(find.byType(AppDropdown<int>));
      expect(dd.items, [-1, 36, 40, 44, 48, 52, 100, 149]);
    });

    testWidgets(
        '#1025: radio stuck on a DFS channel with DFS off — confirming without '
        'moving does not rewrite to Auto', (t) async {
      // SSH-confirmed firmware behaviour: disabling DFS leaves the radio on its
      // manual DFS channel (e.g. 100). The dialog can only show Auto since 100
      // is filtered out, but merely opening and confirming must not mutate.
      ({int channel, bool autoChannel})? captured;
      var called = false;
      await t.pumpWidget(host(
        _radio(
          band: '5GHz',
          channel: 100,
          autoChannelEnable: false,
          isDfsEnabled: false,
          possibleChannels: const [36, 40, 44, 48, 52, 100, 149],
        ),
        (r) {
          captured = r;
          called = true;
        },
      ));
      await openDialog(t);

      // 100 is filtered out, so the dialog opens on Auto.
      final sw = t.widget<AppSwitch>(find.byType(AppSwitch));
      expect(sw.value, isTrue);

      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();

      // No user interaction → no mutation.
      expect(called, isTrue);
      expect(captured, isNull);
    });

    testWidgets(
        '#1025: after DFS-off fallback to Auto, actively picking a channel '
        'still writes', (t) async {
      // Guard against over-suppression: the no-op check must not block a real
      // user selection made after the Auto fallback.
      ({int channel, bool autoChannel})? captured;
      await t.pumpWidget(host(
        _radio(
          band: '5GHz',
          channel: 100,
          autoChannelEnable: false,
          isDfsEnabled: false,
          possibleChannels: const [36, 40, 44, 48, 52, 100, 149],
        ),
        (r) => captured = r,
      ));
      await openDialog(t);

      // Turn Auto OFF, which selects the first manual channel (36).
      await t.tap(find.byType(AppSwitch));
      await t.pumpAndSettle();

      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.autoChannel, isFalse);
      expect(captured!.channel, 36);
    });

    // Fix (#1023): UI-kit v2.26.1 gates the AppDropdown tap gesture when
    // onChanged is null (app_dropdown.dart:138,183), so passing a null
    // onChanged genuinely blocks interaction — no consumer-side IgnorePointer
    // is needed. These tests prove the disabled *behavior*, not the widget tree.
    testWidgets(
        'Fix#1: Auto ON => dropdown disabled and its menu will not open',
        (t) async {
      await t.pumpWidget(host(
        _radio(channel: 36, autoChannelEnable: true),
        (_) {},
      ));
      await openDialog(t);

      // Disabled: onChanged is null (2.26.1 gates the tap gesture on this).
      final dd = t.widget<AppDropdown<int>>(find.byType(AppDropdown<int>));
      expect(dd.onChanged, isNull);

      // The menu must not open when tapping the (disabled) dropdown.
      await t.tap(find.byType(AppDropdown<int>), warnIfMissed: false);
      await t.pumpAndSettle();
      // No manual channel option (e.g. '40') becomes a tappable menu entry.
      expect(find.text('40'), findsNothing);
    });

    testWidgets('Fix#1: Auto OFF => dropdown is enabled and interactive',
        (t) async {
      await t.pumpWidget(host(
        _radio(channel: 36, autoChannelEnable: false),
        (_) {},
      ));
      await openDialog(t);

      final dd = t.widget<AppDropdown<int>>(find.byType(AppDropdown<int>));
      expect(dd.onChanged, isNotNull);
    });

    testWidgets(
        'Fix#1: no manual channels => dropdown locked to Auto (disabled)',
        (t) async {
      await t.pumpWidget(host(
        _radio(
            channel: 36, autoChannelEnable: true, possibleChannels: const []),
        (_) {},
      ));
      await openDialog(t);

      final dd = t.widget<AppDropdown<int>>(find.byType(AppDropdown<int>));
      expect(dd.onChanged, isNull);
    });

    testWidgets(
        'Fix#2: currently-using line is shown in Auto mode with the real channel',
        (t) async {
      await t.pumpWidget(host(
        _radio(channel: 149, autoChannelEnable: true),
        (_) {},
      ));
      await openDialog(t);

      expect(find.text('Currently using: 149'), findsOneWidget);
    });

    testWidgets(
        'Fix#2: currently-using line is shown in manual mode with the channel',
        (t) async {
      await t.pumpWidget(host(
        _radio(channel: 44, autoChannelEnable: false),
        (_) {},
      ));
      await openDialog(t);

      expect(find.text('Currently using: 44'), findsOneWidget);
    });

    testWidgets('AC2: dropdown items = Auto + possibleChannels', (t) async {
      await t.pumpWidget(host(
        _radio(
            channel: 36,
            autoChannelEnable: false,
            possibleChannels: const [36, 40, 44]),
        (_) {},
      ));
      await openDialog(t);

      final dd = t.widget<AppDropdown<int>>(find.byType(AppDropdown<int>));
      // -1 is the Auto sentinel.
      expect(dd.items, [-1, 36, 40, 44]);
    });
  });
}
