import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_ota_view.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../golden_test/golden_framework/mocks/mock_firmware_update.dart';
import '../../golden_test/page/firmware_update/fixtures/firmware_update_test_data.dart';
import '../../mocks/provider_overrides/mock_common.dart';

/// "The router could not be asked" is not "the update failed" (#1551, W5).
///
/// This is W3's handover, and the one requirement in the work package that is about
/// two states **not** sharing a widget. `loadBanks()` used to write its read failure
/// into the state's `errorMessage` (now `failure`), which is what the failure card
/// renders — so a
/// router that was merely slow, busy or behind a dropped bridge got
/// "Update failed / Try again" painted over it, on a page where nothing had been
/// attempted. Its Try Again called `cancel()`, which clears state rather than
/// re-reading, so the one control on screen could not fix the one thing wrong.
///
/// Three things are pinned here, and the third is the one a well-meaning
/// simplification breaks:
///
///   * a failed read renders its own card, with no failure vocabulary and a retry
///     that **re-reads**;
///   * the page asks whether an update is *already* running as soon as it opens
///     (REQ-A6) — auto-update can start a flash on its own, so the page can be
///     opened in the middle of one and has to show it rather than offer to start a
///     second;
///   * the card needs **both** conditions. `loadBanks()` and
///     `observeRunningOtaInstall()` run at the same time and write into one
///     `stateReadError` field, so a card keyed on that field alone would replace a
///     perfectly working Check button whenever the *other* read failed.
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

  Widget wrap(
    _RecordingReadNotifier notifier,
    Override banks, {
    Widget page = const FirmwareOtaView(),
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        LinksysRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => page,
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ...commonOverrides(),
        firmwareUpdateNotifierProvider.overrideWith(() => notifier),
        banks,
        systemInfoDataProvider.overrideWith(
            () => FixedSystemInfoDataNotifier(testSystemInfoData)),
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

  Future<void> pump(
    WidgetTester tester,
    _RecordingReadNotifier notifier,
    Override banks, {
    Widget page = const FirmwareOtaView(),
  }) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(notifier, banks, page: page));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// The button carrying [identifier], read as a widget.
  ///
  /// `find.bySemanticsIdentifier` locates the `Semantics` node rather than the
  /// button, and `isLoading` is a property of the button — so the busy state is read
  /// here the way `firmware_ota_card_identifier_widget_test.dart` reads `AppSwitch`'s.
  AppButton buttonOf(WidgetTester tester, String identifier) =>
      tester.widget<AppButton>(find.byWidgetPredicate(
          (widget) => widget is AppButton && widget.identifier == identifier));

  /// The banks read failed — an `AsyncError`, which is what leaves the page unable
  /// to say whether this router even has the fwup stack.
  final failingBanks = firmwareBanksDataProvider
      .overrideWith(() => FailingFirmwareBanksDataNotifier());

  final readableBanks = firmwareBanksDataProvider
      .overrideWith(() => FixedFirmwareBanksDataNotifier(
            testThreeInstanceBanksData,
          ));

  group('the router could not be asked', () {
    testWidgets('says so, in its own words', (tester) async {
      final handle = tester.ensureSemantics();
      final notifier = _RecordingReadNotifier(firmwareStateUnreadableState);
      await pump(tester, notifier, failingBanks);

      expect(find.text(loc.firmwareStatusUnavailable), findsOneWidget);
      expect(find.text(loc.firmwareStatusUnavailableDesc), findsOneWidget,
          reason: '"Nothing has been changed" is the whole point of the card — '
              'a user who has just been told an update failed will power-cycle '
              'a router that is mid-flash');
      expect(find.bySemanticsIdentifier('firmware-state-retry'), findsOneWidget,
          reason:
              'a read that failed can be retried, and the control needs its '
              'own hook because it is not the failure card\'s retry');

      handle.dispose();
    });

    testWidgets('borrows none of the update-failure vocabulary',
        (tester) async {
      final handle = tester.ensureSemantics();
      final notifier = _RecordingReadNotifier(firmwareStateUnreadableState);
      await pump(tester, notifier, failingBanks);

      for (final failureCopy in [loc.updateFailed, loc.tryAgain]) {
        expect(find.text(failureCopy), findsNothing,
            reason: '"$failureCopy" belongs to an update that was attempted, '
                'and nothing has been attempted here');
      }
      expect(find.bySemanticsIdentifier('firmware-retry'), findsNothing,
          reason: '`firmware-retry` calls `cancel()` — it clears state instead '
              'of re-reading, so wiring this card to it would leave the page '
              'exactly as broken with the button pressed');
      expect(find.bySemanticsIdentifier('firmware-check'), findsNothing,
          reason: 'a check needs the ota instance number, which is precisely '
              'what could not be read');

      handle.dispose();
    });

    testWidgets('does not show the raw error text', (tester) async {
      final notifier = _RecordingReadNotifier(firmwareStateUnreadableState);
      await pump(tester, notifier, failingBanks);

      // `stateReadError` carries a `ServiceError.toString()`: untranslated, and
      // about the transport rather than about the firmware. It is the signal that
      // the card is due, not the sentence on it.
      expect(
          find.text('Network error: the router did not respond'), findsNothing,
          reason: 'the card is localized; the diagnostic goes to the log');
    });

    testWidgets('its retry re-reads, and asks for a fresh read',
        (tester) async {
      final notifier = _RecordingReadNotifier(firmwareStateUnreadableState);
      await pump(tester, notifier, failingBanks);

      await tester.tap(find.text(loc.retry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // `refresh: true` is not politeness. Once the L1 provider is in
      // `AsyncError`, `ref.read(provider.future)` rethrows the *cached* error
      // without going near the router — a retry that did not ask for a refetch
      // would redraw the same failure forever.
      expect(notifier.loads, [false, true],
          reason: 'the page-open read wants the cache; the retry must not');
      expect(notifier.observes, 2,
          reason: 'the retry asks both questions again, because a router that '
              'can now be read may also be mid-update');
    });

    // The read this button starts goes to a router that has *just* failed to
    // answer, so the slow case is the honest one: `UspMutationLock` gives an
    // operation thirty seconds. With no busy state the card redrew identically for
    // all of it, which reads as a dead button and gets tapped again — and each extra
    // tap is another `Get` queued at a router that is already not coping.
    testWidgets('the retry says it is working, and swallows a second tap',
        (tester) async {
      final gate = Completer<void>();
      final notifier = _RecordingReadNotifier(firmwareStateUnreadableState,
          refreshGate: gate);
      await pump(tester, notifier, failingBanks);

      expect(buttonOf(tester, 'firmware-state-retry').isLoading, isFalse,
          reason: 'the resting state — the page-open read is not this '
              'button\'s work and must not spin it');

      await tester.tap(find.text(loc.retry));
      await tester.pump();

      expect(buttonOf(tester, 'firmware-state-retry').isLoading, isTrue,
          reason: 'the read is in flight and nothing else on this card can '
              'show it');

      await tester.tap(find.text(loc.retry), warnIfMissed: false);
      await tester.pump();

      expect(notifier.loads, [false, true],
          reason: '`AppButton._isEnabled` is `onTap != null && !isLoading`, so '
              'the second tap never reaches the router');

      gate.complete();
      await tester.pump();

      expect(buttonOf(tester, 'firmware-state-retry').isLoading, isFalse,
          reason: 'the read came back and failed again, so the card is still '
              'here — and has to be tappable again rather than stuck busy');
    });
  });

  group('on opening the page', () {
    // REQ-A6. `observe()` costs one `Get` on an idle router — zero startup grace,
    // no delay before the first read — so it is called unconditionally rather than
    // behind a pre-read of `fwup_state`.
    testWidgets('asks whether an update is already running', (tester) async {
      final notifier = _RecordingReadNotifier(idleNoFileState);
      await pump(tester, notifier, readableBanks);

      expect(notifier.observes, 1,
          reason: 'auto-update can start a flash with nobody watching, so the '
              'page has to look before it offers to start one');
      expect(notifier.loads, [false]);
    });
  });

  group('a read that throws is handled, not merely logged', () {
    // Both reads record their failure in state **and rethrow**, so the post-frame
    // callback that started them is the last handler on those futures — and one of
    // the two cannot be handled with `.catchError`.
    // `observeRunningOtaInstall` returns a `Future<FirmwareOtaInstallResult>`, which
    // satisfies a `Future<void> Function()` parameter because a narrower return type
    // is a subtype; but `Future<T>.catchError` checks its handler's return value
    // against the **runtime** `T`, so a void handler on that future throws
    // `ArgumentError` out of the error path — on exactly the failure this page draws
    // a card for. `flutter_test` fails a test on an uncaught async error, so pumping
    // the failing pair is the whole assertion.
    testWidgets('neither failing read raises an uncaught async error',
        (tester) async {
      final notifier = _RecordingReadNotifier(firmwareStateUnreadableState,
          readsThrow: true);
      await pump(tester, notifier, failingBanks);

      expect(notifier.loads, [false], reason: 'the read was attempted');
      expect(notifier.observes, 1);
      expect(find.text(loc.firmwareStatusUnavailable), findsOneWidget,
          reason: 'the page renders the state the failure put it in, which is '
              'what makes the throw safe to swallow — not silence about it');
    });

    testWidgets('and neither does the retry', (tester) async {
      final notifier = _RecordingReadNotifier(firmwareStateUnreadableState,
          readsThrow: true);
      await pump(tester, notifier, failingBanks);

      await tester.tap(find.text(loc.retry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(notifier.loads, [false, true]);
      expect(notifier.observes, 2);
    });
  });

  /// The page W3 took the surface away from.
  ///
  /// Before this work package `loadBanks()` wrote its read failure into the state's
  /// `errorMessage` (now `failure`), and **both** pages render that field as
  /// "Update failed". Moving
  /// it to `stateReadError` fixed the OTA page and left the manual one with nothing
  /// at all: its only reader of the old field was `FirmwareInstallPhaseCard`'s
  /// failure arm, which `idle` does not reach. So a manual page whose banks could
  /// not be read went from saying the wrong thing to saying nothing — a Choose File
  /// button over a router whose `targetBank` is unknown, and `_onConfirmInstall`
  /// refuses on that with a snack bar after the user has picked a 70 MB image.
  ///
  /// **Inside the mode gate, not above it.** The card sits in the `picker:` closure
  /// `firmwareManualEntry` decides on, so a surface that does not offer manual
  /// update still renders nothing — #1497's first attempt hoisted a decision out of
  /// that closure and dropped the phase machine with it.
  group('the manual page reports the same failure', () {
    testWidgets('replaces the picker rather than saying nothing',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        _RecordingReadNotifier(firmwareStateUnreadableState),
        failingBanks,
        page: const FirmwareUpdateView(),
      );

      expect(find.text(loc.firmwareStatusUnavailable), findsOneWidget);
      expect(
          find.bySemanticsIdentifier('firmware-state-retry'), findsOneWidget);
      expect(find.bySemanticsIdentifier('firmware-pick-file'), findsNothing,
          reason: 'picking a file cannot help — the failure is that the router '
              'has not said which slot the image would go into');
      expect(find.text(loc.updateFailed), findsNothing,
          reason: 'the vocabulary this whole requirement is about');

      handle.dispose();
    });

    // The card above is not the only thing on this page that reads the banks list.
    // The status card prints the boot slots, and an empty list has two causes with
    // opposite meanings: the router said "none" (a real answer, on a build with no
    // fwup stack) and the router said nothing at all. Rendered as the former, a
    // failed read makes a claim about the hardware directly above a card explaining
    // that nothing could be read.
    testWidgets('and its bank list stays silent rather than answering "none"',
        (tester) async {
      await pump(
        tester,
        _RecordingReadNotifier(firmwareStateUnreadableState),
        failingBanks,
        page: const FirmwareUpdateView(),
      );

      expect(find.text(loc.noFirmwareBanksReported), findsNothing,
          reason: 'a claim about the router\'s boot slots, off a read that '
              'never reached it');
      expect(
        find.descendant(
          of: find
              .ancestor(
                of: find.text(loc.firmwareBanks),
                matching: find.byType(Column),
              )
              .first,
          matching: find.text('—'),
        ),
        findsOneWidget,
        reason: 'a dash: the card below already says why, and any sentence '
            'here would either repeat it or answer a question nobody asked',
      );
    });

    testWidgets('and keeps the picker when the read succeeded', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        _RecordingReadNotifier(idleNoFileState),
        readableBanks,
        page: const FirmwareUpdateView(),
      );

      expect(find.bySemanticsIdentifier('firmware-pick-file'), findsOneWidget);
      expect(find.text(loc.firmwareStatusUnavailable), findsNothing);

      handle.dispose();
    });

    testWidgets('its retry re-reads with a refresh', (tester) async {
      final notifier = _RecordingReadNotifier(firmwareStateUnreadableState);
      await pump(tester, notifier, failingBanks,
          page: const FirmwareUpdateView());

      await tester.tap(find.text(loc.retry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Same reason as the OTA page's: `ref.read(provider.future)` replays a
      // cached `AsyncError` without going near the router.
      expect(notifier.loads, [false, true]);
      expect(notifier.observes, 0,
          reason: 'this page never asks whether an update is running — that is '
              'the OTA page\'s question, and asking it here would start a poll '
              'loop on a page that has no card for the answer');
    });
  });

  group('only one of the two reads failed', () {
    // The conjunction, and the reason it is a conjunction. Both reads run at once
    // and write into one field, so `stateReadError != null` on its own is true for
    // a page whose banks are perfectly readable — replacing the Check button there
    // would take away a control that works.
    testWidgets('a readable router keeps its check button', (tester) async {
      final handle = tester.ensureSemantics();
      final notifier = _RecordingReadNotifier(
        idleNoFileState.copyWith(stateReadError: 'observe read failed'),
      );
      await pump(tester, notifier, readableBanks);

      expect(find.bySemanticsIdentifier('firmware-check'), findsOneWidget,
          reason: 'the banks read succeeded, so the router can still be asked');
      expect(find.text(loc.firmwareStatusUnavailable), findsNothing,
          reason: 'the page is not unable to say anything — it is only missing '
              'the answer to one of two questions');

      handle.dispose();
    });

    /// The third condition, and the only one whose failure is dangerous rather than
    /// merely wrong.
    ///
    /// `stateReadError` is never cleared by the observe path, so a page opened during
    /// a flash whose *banks* read failed satisfies both conditions above at once — and
    /// the card then sat directly above the phase card, reading "Firmware status
    /// unavailable / nothing on the router has been changed" over "The router is
    /// writing the new image. Do not power off." The banks read having failed is true
    /// and is not the story: this card exists to stop someone power-cycling a router
    /// mid-flash, so it must not be the thing that tells them nothing is happening.
    testWidgets('an install being drawn outranks the failed read',
        (tester) async {
      final notifier = _RecordingReadNotifier(
        otaInstallProgressState(FirmwareAutoUpdateStatus.installing)
            .copyWith(stateReadError: 'the banks read failed'),
      );
      await pump(tester, notifier, failingBanks);

      expect(find.text(loc.routerWritingImage), findsOneWidget,
          reason: 'the one sentence on this page that keeps a router alive');
      expect(find.text(loc.firmwareStatusUnavailable), findsNothing);
      expect(find.text(loc.firmwareStatusUnavailableDesc), findsNothing,
          reason: '"Nothing on the router has been changed" is false while the '
              'router is writing NAND, and it is the sentence that would get '
              'the router power-cycled');
    });

    // A read still in flight is not a read that failed. Collapsing the two would
    // flash the card on every page open, off a bridge that was merely slow.
    testWidgets('a read still in flight claims nothing', (tester) async {
      final notifier = _RecordingReadNotifier(idleNoFileState);
      await pump(
          tester,
          notifier,
          firmwareBanksDataProvider
              .overrideWith(() => _PendingBanksNotifier()));

      expect(find.text(loc.firmwareStatusUnavailable), findsNothing);
      expect(find.text(loc.updateFailed), findsNothing);
    });
  });
}

/// Fixed state, but records which reads the page asked for.
class _RecordingReadNotifier extends FixedFirmwareUpdateNotifier {
  _RecordingReadNotifier(FirmwareUpdateState state,
      {this.readsThrow = false, this.refreshGate})
      : super(state);

  /// Whether both reads rethrow after recording, as the real ones do.
  ///
  /// Off by default so the tests about *which* reads happen are not also tests
  /// about failure handling — but the real pair does throw, and a fixture that
  /// never did is why the swallow's own defect survived the suite.
  final bool readsThrow;

  /// Held open by the **retry's** read, so its in-flight state can be observed.
  ///
  /// Only the refresh, and that asymmetry is what the test needs: the page-open read
  /// has to finish for the card to be on screen in its resting state to begin with,
  /// and a gate on both would make "not spinning yet" indistinguishable from
  /// "spinning for the wrong read".
  final Completer<void>? refreshGate;

  /// One entry per `loadBanks` call, holding its `refresh` argument.
  final List<bool> loads = [];

  int observes = 0;

  @override
  Future<void> loadBanks({bool refresh = false}) async {
    loads.add(refresh);
    if (refresh && refreshGate != null) await refreshGate!.future;
    if (readsThrow) throw const NetworkError(detail: 'bridge closed');
  }

  @override
  Future<FirmwareOtaInstallResult> observeRunningOtaInstall() async {
    observes++;
    if (readsThrow) throw const NetworkError(detail: 'bridge closed');
    return const FirmwareOtaInstallResult(
        verdict: FirmwareOtaInstallVerdict.abandoned);
  }
}

/// A banks provider that never answers, i.e. `AsyncLoading` forever.
class _PendingBanksNotifier extends FirmwareBanksDataNotifier {
  @override
  Future<FirmwareBanksData> build() => Completer<FirmwareBanksData>().future;
}
