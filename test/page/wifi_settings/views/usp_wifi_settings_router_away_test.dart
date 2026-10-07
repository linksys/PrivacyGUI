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

/// One recovery for the whole Wi-Fi save, entered when the save starts.
///
/// Bench, 2026-10-07 (M60, FW 2.0.2, local), a Quick Setup rename + password,
/// four rounds. What the page did before this, in order: "Processing"; the
/// event stream gave up mid-save and the shell put up "Connection lost"; the
/// save came back and — as every Wi-Fi save always had — opened a SECOND
/// recovery, "Router is applying changes", with its own 20 s cooldown; the
/// form was then re-read while the access-point table was still empty.
///
/// Now the save enters recovery itself, so the app is already waiting when the
/// stream drops and the shell shows nothing of its own. The probe is held off
/// while the router is still applying — it answers for the first ~38 s of the
/// reload — and started once the write has settled. Recovery ends through the
/// probe as for every trigger; the page then reports the save.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  late _ControllableConnection connection;
  late _ScriptedWifiNotifier wifi;

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
  final applying = find.text('Router is applying changes');
  final saved = find.text('WiFi settings saved');
  final failed = find.text('Something went wrong. Please try again.');

  setUp(() {
    connection = _ControllableConnection();
    wifi = _ScriptedWifiNotifier(editDirtyState);
  });

  group('local', () {
    testWidgets(
        'the save enters recovery when it starts: ONE dialog, no probe while '
        'the router is applying, no second recovery after', (tester) async {
      await pumpWifi(tester);
      await tester.tap(save);
      await frames(tester);

      expect(connection.current, AppConnectionState.waitingForRecovery,
          reason: 'waiting from the start — so the stream dropping mid-save '
              'finds the app already recovering and shows nothing new');
      expect(applying, findsOneWidget);
      expect(processing, findsNothing,
          reason: 'the recovery dialog is the one dialog');
      expect(connection.probingStarted, isFalse,
          reason: 'the router still answers early in the reload; a probe '
              'now would end the recovery before anything restarted');

      wifi.finishSave(WifiSaveEnd.confirmed);
      await frames(tester);
      expect(connection.probingStarted, isTrue,
          reason: 'the write has settled — now the router is worth probing');
      expect(saved, findsNothing, reason: 'not before the router is back');

      connection.set(AppConnectionState.authenticated);
      await frames(tester);

      expect(applying, findsNothing);
      expect(saved, findsOneWidget);
      expect(connection.waitsEntered, 1,
          reason: 'one recovery for the whole save, never a second one');
    });

    testWidgets(
        'router away (a rename): waits through the same recovery, then reads '
        'back once', (tester) async {
      await pumpWifi(tester);
      await tester.tap(save);
      await frames(tester);

      wifi.finishSave(WifiSaveEnd.routerAway);
      await frames(tester);
      expect(wifi.confirms, 0,
          reason: 'nothing is read before the router is back');

      connection.set(AppConnectionState.authenticated);
      await frames(tester);

      expect(wifi.confirms, 1);
      expect(saved, findsOneWidget);
      expect(connection.waitsEntered, 1);
    });

    testWidgets('router back but the save did not apply ⇒ failure',
        (tester) async {
      wifi.confirmFails = true;
      await pumpWifi(tester);
      await tester.tap(save);
      await frames(tester);
      wifi.finishSave(WifiSaveEnd.routerAway);
      await frames(tester);

      connection.set(AppConnectionState.authenticated);
      await frames(tester);

      expect(saved, findsNothing);
      expect(failed, findsOneWidget);
    });

    testWidgets(
        'a refused save still ends the recovery it entered, then reports the '
        'failure', (tester) async {
      await pumpWifi(tester);
      await tester.tap(save);
      await frames(tester);

      wifi.finishSave(WifiSaveEnd.refused);
      await frames(tester);
      expect(connection.probingStarted, isTrue,
          reason: 'the router answered, so the probe passes at once — the '
              'one exit recovery has');

      connection.set(AppConnectionState.authenticated);
      await frames(tester);

      expect(applying, findsNothing);
      expect(failed, findsOneWidget);
      expect(saved, findsNothing);
    });

    testWidgets('signed out while waiting ⇒ nothing is read or reported',
        (tester) async {
      await pumpWifi(tester);
      await tester.tap(save);
      await frames(tester);
      wifi.finishSave(WifiSaveEnd.routerAway);
      await frames(tester);

      connection.set(AppConnectionState.loggedOut);
      await frames(tester);

      expect(wifi.confirms, 0);
      expect(saved, findsNothing);
    });
  });

  group('remote assistance', () {
    // A Wi-Fi change does not interrupt the agent's path (#1323), so no
    // recovery is entered for the save; the spinner covers it.
    testWidgets('confirmed: Processing, then success — no recovery at all',
        (tester) async {
      await pumpWifi(tester, profile: const RemoteModeProfile());
      await tester.tap(save);
      await frames(tester);

      expect(processing, findsOneWidget);
      expect(applying, findsNothing);
      expect(connection.current, AppConnectionState.authenticated);

      wifi.finishSave(WifiSaveEnd.confirmed);
      await frames(tester);

      expect(processing, findsNothing);
      expect(saved, findsOneWidget);
      expect(connection.waitsEntered, 0);
    });

    testWidgets(
        'router away: waits for it to rejoin the cloud (natural recovery), '
        'then reads back once', (tester) async {
      await pumpWifi(tester, profile: const RemoteModeProfile());
      await tester.tap(save);
      await frames(tester);

      wifi.finishSave(WifiSaveEnd.routerAway);
      await frames(tester);
      expect(connection.current, AppConnectionState.waitingForRecovery,
          reason: 'the router still has to rejoin the cloud before it can '
              'be read, and RA runs the natural recovery');
      expect(wifi.confirms, 0);

      connection.set(AppConnectionState.authenticated);
      await frames(tester);

      expect(wifi.confirms, 1);
      expect(saved, findsOneWidget);
    });
  });
}

enum WifiSaveEnd { confirmed, routerAway, refused }

/// Ends its save the way the test says.
class _ScriptedWifiNotifier extends FixedWifiSettingsNotifier {
  _ScriptedWifiNotifier(UspWifiSettingsState state) : super(state);

  // Created on first save, not with the notifier: the notifier is built in
  // `setUp`, outside the test's fake-async zone, and a completer made there
  // resumes its awaiter on the real event loop — after the test has finished
  // pumping.
  Completer<void>? _save;
  var _away = false;
  var confirms = 0;
  var confirmFails = false;

  void finishSave(WifiSaveEnd end) {
    switch (end) {
      case WifiSaveEnd.confirmed:
        _save!.complete();
      case WifiSaveEnd.routerAway:
        _away = true;
        _save!.complete();
      case WifiSaveEnd.refused:
        _save!.completeError(const UnexpectedError());
    }
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
  var waitsEntered = 0;
  var probingStarted = false;

  @override
  AppConnectionState build() => AppConnectionState.authenticated;

  void set(AppConnectionState next) => state = next;

  /// The real answer to "does this trigger need a recovery in this mode" —
  /// that is part of what is under test — without the real probe loop.
  @override
  bool enterWaiting({required RecoveryContext context}) {
    if (state == AppConnectionState.waitingForRecovery) return true;
    final plan =
        ref.read(appModeProfileProvider).proximity.planFor(context.trigger);
    if (!plan.needsRecovery) return false;
    waitsEntered++;
    probingStarted = context.cooldown == Duration.zero;
    state = AppConnectionState.waitingForRecovery;
    return true;
  }

  @override
  void startProbingNow() {
    if (state == AppConnectionState.waitingForRecovery) probingStarted = true;
  }

  AppConnectionState get current => state;
}
