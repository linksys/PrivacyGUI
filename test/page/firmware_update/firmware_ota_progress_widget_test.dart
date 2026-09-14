import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_ota_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../golden_test/golden_framework/mocks/mock_firmware_update.dart';
import '../../golden_test/page/firmware_update/fixtures/firmware_update_test_data.dart';
import '../../mocks/provider_overrides/mock_common.dart';

/// What the install card says while the *router* is doing the work (#1551, W5).
///
/// Before this work package the `installing` phase had one rendering: "Installing
/// firmware / The router is writing the new image", over an indeterminate bar. That
/// is true of a manual upload — this app pushed the image and the router publishes
/// nothing while it flashes — and it is wrong three times over for an OTA, which
/// runs `fwupd -m 2`: **check, download, flash.** A single card would claim the
/// image was being written while the router was still deciding whether one existed.
///
/// So the copy is chosen from the reading, and the two rules it has to keep are
/// both measurements rather than preferences:
///
///   * **a number is only shown while downloading.** `fwup_progress` was measured
///     sweeping 0→100 during `fwup_state=1` on one run and sitting at 0 through the
///     whole of the same phase on another, and it runs 0→100 *twice* across one
///     install — so a shared bar would show the same update completing twice. See
///     [FirmwareOtaInstallProgress.percent];
///   * **an unrecognised state is still progress.** REQ-A7: a firmware that grows a
///     sixth `fwup_state` must render as "something is happening", never as the last
///     state this build recognised.
///
/// And the manual path must come through unchanged, which is why every OTA
/// assertion here has a `otaProgress == null` counterpart.
///
/// Not tagged `ui`: gated in `run_tests.sh` (the repo's only CI test job).
void main() {
  late AppLocalizations loc;

  setUpAll(() async {
    loc = await AppLocalizations.delegate.load(const Locale('en'));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{
            'appName': 'PrivacyGUI',
            'packageName': 'com.linksys.privacygui',
            'version': '0.0.0',
            'buildNumber': '0',
          };
        }
        return null;
      },
    );
  });

  Widget wrap(FirmwareUpdateState state) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => const FirmwareOtaView(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        ...firmwareUpdateOverrides(
          updateState: state,
          banksData: testThreeInstanceBanksData,
          systemInfoData: testSystemInfoData,
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        routerConfig: router,
      ),
    );
  }

  /// Frames rather than `pumpAndSettle`: an indeterminate [AppLoader] repeats
  /// forever, so a settle would time out on every test in this file.
  Future<void> pump(WidgetTester tester, FirmwareUpdateState state) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(state));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// The bar the card draws — exactly one, and its `value` is the whole question:
  /// null is a spinner, a number is a claim.
  AppLoader loader(WidgetTester tester) {
    final finder = find.byType(AppLoader);
    expect(finder, findsOneWidget,
        reason: 'one progress bar per card; two would be two claims about one '
            'install');
    return tester.widget<AppLoader>(finder);
  }

  /// The three copy pairs that must never appear together.
  ///
  /// Asserted as a set rather than one at a time, for the reason the check card's
  /// test gives: a card that renders two of these is the defect, and it is
  /// invisible to a test that only looks for the one it expects.
  void expectOnlyTitle(String present) {
    final titles = <String>[
      loc.checkingForNewFirmware,
      loc.downloadingFirmware,
      loc.installingFirmware,
      loc.updatingFirmware,
    ];
    for (final title in titles) {
      expect(
        find.text(title),
        title == present ? findsOneWidget : findsNothing,
        reason: title == present
            ? '"$title" is what this reading says'
            : '"$title" describes a different phase of the same install',
      );
    }
  }

  group('a reading from the router', () {
    testWidgets('checking says the router is asking, with no number',
        (tester) async {
      await pump(
          tester, otaInstallProgressState(FirmwareAutoUpdateStatus.checking));

      expectOnlyTitle(loc.checkingForNewFirmware);
      expect(find.text(loc.routerCheckingForImage), findsOneWidget);
      expect(loader(tester).value, isNull,
          reason: '`fwup_progress` has been measured both sweeping and frozen '
              'during `fwup_state=1`, so no bar can render it');
    });

    testWidgets('downloading shows the number the router published',
        (tester) async {
      await pump(
        tester,
        otaInstallProgressState(FirmwareAutoUpdateStatus.downloading,
            progress: 42),
      );

      expectOnlyTitle(loc.downloadingFirmware);
      expect(find.text(loc.routerDownloadingImage), findsOneWidget);
      expect(find.text(loc.percentComplete('42')), findsOneWidget);
      expect(loader(tester).value, closeTo(0.42, 0.0001),
          reason: 'the one state where the parameter has been observed to mean '
              'what it says');
    });

    // 0 is a reading, not a missing one. This is the case the nullable
    // `otaProgress` field exists to keep separable: a bar that treated 0 as
    // "nothing known yet" would spin through the start of every download.
    testWidgets('downloading at zero is still a number', (tester) async {
      await pump(
        tester,
        otaInstallProgressState(FirmwareAutoUpdateStatus.downloading,
            progress: 0),
      );

      expect(find.text(loc.percentComplete('0')), findsOneWidget);
      expect(loader(tester).value, 0.0);
    });

    // The router has published `fwup_progress` above 100 on a spare-bank read, and
    // a bar cannot render 1.4 — ui_kit would paint past its own track.
    testWidgets('a number past the end is clamped, not passed through',
        (tester) async {
      await pump(
        tester,
        otaInstallProgressState(FirmwareAutoUpdateStatus.downloading,
            progress: 140),
      );

      expect(find.text(loc.percentComplete('100')), findsOneWidget);
      expect(loader(tester).value, 1.0);
    });

    testWidgets('flashing says the image is being written, with no number',
        (tester) async {
      await pump(
          tester, otaInstallProgressState(FirmwareAutoUpdateStatus.installing));

      // The same pair the manual path shows, and deliberately so: `fwup_state=4`
      // *is* the router writing the image, so a second wording for one fact would
      // be a distinction the firmware does not make.
      expectOnlyTitle(loc.installingFirmware);
      expect(find.text(loc.routerWritingImage), findsOneWidget);
      expect(loader(tester).value, isNull,
          reason: '`fwup_progress` during flashing has never been observed to '
              'move');
    });

    // REQ-A7. `7` is not in `mapAutoUpdateStatus`'s domain, which is the point:
    // this is the rendering for a firmware that grew a state after this build
    // shipped, and the requirement is that it reads as *something happening*.
    testWidgets('a state this build does not know is still an update running',
        (tester) async {
      await pump(
          tester, otaInstallProgressState(FirmwareAutoUpdateStatus.unknown));

      expectOnlyTitle(loc.updatingFirmware);
      expect(find.text(loc.routerUpdatingFirmware), findsOneWidget);
      expect(loader(tester).value, isNull);
      for (final wrongClaim in [
        loc.routerCheckingForImage,
        loc.routerDownloadingImage,
        loc.routerWritingImage,
      ]) {
        expect(find.text(wrongClaim), findsNothing,
            reason: '"$wrongClaim" names a phase that was not observed — an '
                'unknown state must not borrow the last one we recognised');
      }
    });
  });

  group('no reading from the router', () {
    // The manual path, byte-for-byte what it was before this work package. This
    // app pushed the image itself and the router publishes nothing while it
    // writes, so there is no reading and nothing to change.
    testWidgets('installing keeps the copy the manual upload always had',
        (tester) async {
      await pump(tester, installingState);

      expectOnlyTitle(loc.installingFirmware);
      expect(find.text(loc.routerWritingImage), findsOneWidget);
      expect(loader(tester).value, isNull,
          reason: 'a manual install has no progress to report — inventing 0% '
              'would be a bar that never moves');
      expect(find.textContaining('% complete'), findsNothing);
    });
  });

  group('completion narrates the master and promises nothing else', () {
    // Known issue M2, and the one thing this work package can do about it. The
    // update *is* network-wide — `Download(ota,"true")` is `update_firmware_now 2`,
    // which runs `update_nodes` — but the visibility is master-side only:
    // `fwup_state` is a master scalar, a child node that fails to flash does not
    // necessarily move it to 5, and `verify()` keys on the master's bank flip. So
    // the master can be done, and reported done, while a node is still writing or
    // has already failed.
    //
    // There is no data behind a network-wide claim, so the requirement is silence
    // rather than a guess. Asserted in `en` only: the translations are derived from
    // these two source strings, and a scan for English vocabulary in 26 locales
    // would assert nothing about 25 of them while looking like it did.
    testWidgets('says what this router is running, not what the network is',
        (tester) async {
      await pump(tester, doneState);

      expect(find.text(loc.updateComplete), findsOneWidget);
      expect(
          find.text(loc.nowRunningVersion('1.0.17.26050100')), findsOneWidget,
          reason: 'the version the master booted is the whole of what was '
              'observed');

      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => (t.data ?? '').toLowerCase())
          .join(' | ');
      for (final promise in [
        'all devices',
        'every device',
        'whole network',
        'entire network',
        'all nodes',
        'mesh',
      ]) {
        expect(rendered, isNot(contains(promise)),
            reason: '"$promise" is a claim about nodes this app cannot see — '
                'there is no per-node result source (M2), so the copy that '
                'would need one must not exist:\n$rendered');
      }
    });
  });

  group('a failure keeps the reading without rendering it', () {
    // The documented decision on `FirmwareUpdateState.otaProgress`, pinned because
    // it is easy to "improve" into a percentage on a failure card. It cannot be
    // one: the last reading before a failure *is* the failing reading, and
    // `percent` is null for every status except `downloading`.
    testWidgets('shows the failure and its state number, not a bar',
        (tester) async {
      await pump(
        tester,
        otaInstallProgressState(FirmwareAutoUpdateStatus.failed).copyWith(
          phase: FirmwareUpdatePhase.failed,
          errorMessage: 'The router reported the firmware update failed '
              '(fwup_state=5)',
        ),
      );

      expect(find.text(loc.updateFailed), findsOneWidget);
      expect(
          find.text('The router reported the firmware update failed '
              '(fwup_state=5)'),
          findsOneWidget,
          reason: '`5` says nothing about why, so the number is the whole '
              'diagnostic a support call has to work from');
      expect(find.byType(AppLoader), findsNothing,
          reason: 'nothing is in progress');
      expect(find.textContaining('% complete'), findsNothing);
    });
  });
}
