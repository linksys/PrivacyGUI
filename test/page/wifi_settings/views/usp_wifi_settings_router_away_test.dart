import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_state.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_wifi_settings.dart';
import '../../../mocks/test_data/scenes/wifi_settings_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// The page's half of a save the router could not be read back from in time.
///
/// Bench, 2026-10-07 (M60, FW 2.0.2, local): a Quick Setup rename + password.
/// The one SET applied; the browser dropped off the old SSID; every read-back
/// for 60 s failed while the user rejoined; the save reported failure. Before
/// that, at 30 s, the event stream gave up and the shell put up "Connection
/// lost" — and the save's end closed THAT dialog, stranding "Processing".
///
/// Now the page waits for the router, reads back once, and reports what it
/// says. The recovery this waits on is whichever one is already running.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  late _ControllableConnection connection;
  late _RouterAwayWifiNotifier wifi;

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpWifi(
    WidgetTester tester, {
    AppModeProfile profile = const LocalModeProfile(),
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: const UspWifiSettingsView(),
      locale: const Locale('en'),
      overrides: [
        uspWifiSettingsProvider.overrideWith(() => wifi),
        uspWifiAdvancedProvider.overrideWith(
            () => FixedWifiAdvancedNotifier(defaultAdvancedState)),
        appConnectionStateProvider.overrideWith(() => connection),
        appModeProfileProvider.overrideWithValue(profile),
      ],
    ));
    await frames(tester);
    // Nothing on this page watches the connection state (the shell does), so
    // build it here or the test cannot move it.
    ProviderScope.containerOf(tester.element(find.byType(UspWifiSettingsView)))
        .read(appConnectionStateProvider);
  }

  final save = find.byWidgetPredicate(
    (w) => w is AppButton && w.identifier == 'page-save',
    description: 'the page Save button',
  );
  final processing = find.textContaining('Processing');
  final saved = find.text('WiFi settings saved');

  setUp(() {
    connection = _ControllableConnection();
    wifi = _RouterAwayWifiNotifier(editDirtyState);
  });

  testWidgets(
      'the bench sequence: recovery already up when the save returns — '
      'Processing closes, ONE recovery dialog, then success on read-back',
      (tester) async {
    await pumpWifi(tester);
    await tester.tap(save);
    await frames(tester);
    expect(processing, findsOneWidget);

    // The event stream gives up mid-save; the app enters recovery. (The
    // shell's listener is what shows its dialog; here a dialog stands in.)
    connection.set(AppConnectionState.waitingForRecovery);
    _pushStandInRecoveryDialog(tester);
    await frames(tester);

    wifi.finishSave();
    await frames(tester);

    expect(processing, findsNothing,
        reason: 'the spinner closed itself, not the dialog above it');
    expect(find.text('Connection lost'), findsOneWidget,
        reason: 'the running recovery keeps its own dialog');
    expect(find.text('Router is applying changes'), findsNothing,
        reason: 'no second recovery dialog stacked on the first');
    expect(wifi.confirms, 0,
        reason: 'nothing is read before the router is back');

    connection.set(AppConnectionState.authenticated);
    await frames(tester);

    expect(wifi.confirms, 1);
    expect(saved, findsOneWidget);
  });

  testWidgets('router back but the save did not apply ⇒ failure, not success',
      (tester) async {
    wifi.confirmFails = true;
    await pumpWifi(tester);
    await tester.tap(save);
    await frames(tester);
    connection.set(AppConnectionState.waitingForRecovery);
    wifi.finishSave();
    await frames(tester);

    connection.set(AppConnectionState.authenticated);
    await frames(tester);

    expect(wifi.confirms, 1);
    expect(saved, findsNothing);
    expect(find.text('Something went wrong. Please try again.'), findsOneWidget,
        reason: 'reported as a failure — not left silent');
  });

  testWidgets('signed out while waiting ⇒ nothing is read and nothing reported',
      (tester) async {
    await pumpWifi(tester);
    await tester.tap(save);
    await frames(tester);
    connection.set(AppConnectionState.waitingForRecovery);
    wifi.finishSave();
    await frames(tester);

    connection.set(AppConnectionState.loggedOut);
    await frames(tester);

    expect(wifi.confirms, 0);
    expect(saved, findsNothing);
  });

  // The other order: the save comes back first, with the app still signed in
  // and the router not answering. Over Remote Assistance the agent's own path
  // never broke — but the router still has to rejoin the cloud before it can be
  // read, so both modes wait for it, with no time limit.
  for (final MapEntry(key: mode, value: profile) in const {
    'local': LocalModeProfile(),
    'remote assistance': RemoteModeProfile(),
  }.entries) {
    testWidgets(
        '$mode: save returns first ⇒ waits for the router to come back, then '
        'reads back once', (tester) async {
      await pumpWifi(tester, profile: profile);
      await tester.tap(save);
      await frames(tester);

      wifi.finishSave();
      await frames(tester);

      expect(processing, findsNothing);
      expect(connection.current, AppConnectionState.waitingForRecovery,
          reason: 'entered a recovery that waits — not one this mode skips');
      expect(find.text('Router is applying changes'), findsNothing,
          reason: 'the wait is the natural recovery the shell shows; the page '
              'stacks nothing of its own on it');
      expect(wifi.confirms, 0,
          reason: 'nothing is read before the router is back');

      connection.set(AppConnectionState.authenticated);
      await frames(tester);

      expect(wifi.confirms, 1);
      expect(saved, findsOneWidget);
    });
  }
}

/// What the shell's natural-recovery listener does when the app enters
/// recovery: push a modal with no way out but the router coming back.
void _pushStandInRecoveryDialog(WidgetTester tester) {
  showDialog<void>(
    context: tester.element(find.byType(UspWifiSettingsView)),
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const AlertDialog(content: Text('Connection lost')),
  );
}

/// Ends its save the way a rename does when the browser cannot reach the
/// router by the deadline: written, and waiting for recovery.
class _RouterAwayWifiNotifier extends FixedWifiSettingsNotifier {
  _RouterAwayWifiNotifier(UspWifiSettingsState state) : super(state);

  // Created on first save, not with the notifier: the notifier is built in
  // `setUp`, outside the test's fake-async zone, and a completer made there
  // resumes its awaiter on the real event loop — after the test has finished
  // pumping.
  Completer<void>? _save;
  var _away = false;
  var confirms = 0;
  var confirmFails = false;

  void finishSave() {
    _away = true;
    _save!.complete();
  }

  @override
  Future<void> performSave() => (_save = Completer<void>()).future;

  @override
  bool get awaitsRouterRecovery => _away;

  @override
  Future<void> confirmAfterRecovery() async {
    confirms++;
    _away = false;
    if (confirmFails) throw const UnexpectedError();
  }
}

/// The connection state, moved by the test.
class _ControllableConnection extends AppConnectionStateNotifier {
  @override
  AppConnectionState build() => AppConnectionState.authenticated;

  void set(AppConnectionState next) => state = next;

  /// The real answer to "does this trigger need a recovery in this mode" —
  /// that is the decision under test — without the real probe loop.
  @override
  bool enterWaiting({required RecoveryContext context}) {
    if (state == AppConnectionState.waitingForRecovery) return true;
    final plan =
        ref.read(appModeProfileProvider).proximity.planFor(context.trigger);
    if (!plan.needsRecovery) return false;
    state = AppConnectionState.waitingForRecovery;
    return true;
  }

  AppConnectionState get current => state;
}
