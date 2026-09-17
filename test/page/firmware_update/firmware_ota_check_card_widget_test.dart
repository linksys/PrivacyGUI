import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_ota_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../golden_test/golden_framework/mocks/mock_firmware_update.dart';
import '../../golden_test/page/firmware_update/fixtures/firmware_update_test_data.dart';
import '../../mocks/provider_overrides/mock_common.dart';
import '../../mocks/test_data/firmware_update_test_data.dart';

/// What the OTA check card says, per #1550 (REQ-A3 and the UI half of REQ-A1).
///
/// **Four renderings, and the requirement is that no two of them collapse.** The
/// card reads two independent facts — whether this router has the virtual `ota` row
/// at all, and what the last check returned — and the failure this file exists to
/// prevent is any of them being answered with another's copy:
///
///   * an image is waiting → the version, and an offer;
///   * asked, nothing found → a conservative sentence, and **not** "you are up to
///     date": that verdict is reached by a deadline expiring, so the copy is held to
///     what was observed (`FirmwareRouterOtaCheckService.defaultDeadline`);
///   * no `ota` row → "not available here", **no button**, and nothing that reads as
///     a failure. Permanent on OEM and rebadged builds, so there is nothing to
///     retry;
///   * nothing checked yet, or a check that failed → the button alone. Every
///     sentence above is a claim about the firmware on the router and neither state
///     supports one; a failure is reported in a snack bar instead.
///
/// **The two negative results are the pair worth the most here.** "This router
/// cannot be asked" and "we asked and there is nothing" are one sentence to a user
/// if they share copy, and the second one is reassurance the first has not earned.
/// So each test asserts the other three sentences absent rather than only its own
/// present — an absence is what a collapsed state would trip.
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
    FirmwareUpdateState state,
    FirmwareBanksData banks, {
    FirmwareAutoUpdateUIModel? autoUpdate,
  }) {
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
          banksData: banks,
          systemInfoData: testSystemInfoData,
          autoUpdate: autoUpdate,
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

  /// A wide surface on purpose: the card lays the button and the verdict out in a
  /// `Row` above 600px of card content and stacks them below it. Both geometries
  /// render the same strings, and the stacking itself is measured by the layout gate
  /// in all 26 locales at nine widths — so this file picks the width where nothing
  /// wraps and asserts only the copy.
  Future<void> pump(
    WidgetTester tester,
    FirmwareUpdateState state,
    FirmwareBanksData banks, {
    FirmwareAutoUpdateUIModel? autoUpdate,
  }) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(state, banks, autoUpdate: autoUpdate));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// The four sentences only one of which may ever be on screen at a time.
  ///
  /// Asserted as a set rather than one at a time so that adding a fifth verdict
  /// forces a decision here: a state that renders two of these is the defect, and it
  /// is invisible to a test that only looks for the one it expects.
  ///
  /// `firmwareStatusUnavailable` is the odd one out and is in the list for exactly
  /// that reason: #1551 gave it a card of its own, replacing this one rather than
  /// appearing beside it, because "the router could not be asked" is the absence of
  /// every answer above. Every state pumped in this file *can* be read, so it must
  /// be absent from all of them — see
  /// `firmware_state_unreadable_widget_test.dart` for the state that shows it.
  void expectOnly(String? present) {
    final sentences = <String>[
      loc.updateAvailable,
      loc.firmwareNoUpdateFound,
      loc.otaCheckNotSupported,
      loc.firmwareStatusUnavailable,
    ];
    for (final sentence in sentences) {
      expect(
        find.text(sentence),
        sentence == present ? findsOneWidget : findsNothing,
        reason: sentence == present
            ? '"$sentence" is what this state says'
            : '"$sentence" is another state\'s answer and must not appear '
                'beside "${present ?? 'nothing'}"',
      );
    }
  }

  group('an image is waiting', () {
    testWidgets('offers it, by version', (tester) async {
      await pump(
        tester,
        const FirmwareUpdateState(
          phase: FirmwareUpdatePhase.idle,
          otaCheck:
              FirmwareOtaCheckResult.updateAvailable(version: '2.0.1.26091009'),
        ),
        testThreeInstanceBanksData,
      );

      expectOnly(loc.updateAvailable);
      expect(find.text(loc.availableVersionLabel('2.0.1.26091009')),
          findsOneWidget,
          reason: 'the version is the one actionable detail the check returns');
    });

    // `Available=true` with an empty `Version` is measured, not hypothetical — the
    // spare NAND bank reports exactly that shape and the ota row can too. The offer
    // must survive the missing detail rather than render an empty label beside it.
    testWidgets('is still an offer when the router names no version',
        (tester) async {
      await pump(
        tester,
        const FirmwareUpdateState(
          otaCheck: FirmwareOtaCheckResult.updateAvailable(),
        ),
        testThreeInstanceBanksData,
      );

      expectOnly(loc.updateAvailable);
      expect(find.textContaining(loc.availableVersionLabel('')), findsNothing,
          reason:
              'an empty version renders no version line at all, rather than '
              'a label with nothing after it');
    });
  });

  group('the router was asked and had nothing', () {
    testWidgets('says so without claiming the firmware is current',
        (tester) async {
      await pump(
        tester,
        const FirmwareUpdateState(
          otaCheck: FirmwareOtaCheckResult.noUpdateFound(),
        ),
        testThreeInstanceBanksDataNoImage,
      );

      expectOnly(loc.firmwareNoUpdateFound);
      expect(find.bySemanticsIdentifier('firmware-check'), findsOneWidget,
          reason: 'a router that answered can be asked again');
    });
  });

  group('the router has no ota row', () {
    // REQ-A1. The state the whole tri-state read exists for: `FirmwareBanksData`
    // with two physical banks and no virtual row is an OEM or rebadged build, which
    // never ships the fwup stack — so this is a property of the device, permanent,
    // and not a fault.
    testWidgets('is not offered a check at all', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const FirmwareUpdateState(),
        testBanksData,
      );

      expectOnly(loc.otaCheckNotSupported);
      expect(find.bySemanticsIdentifier('firmware-check'), findsNothing,
          reason: 'a control whose only possible outcome is failure is worse '
              'than no control — there is nothing here to retry');
      expect(find.text(loc.checkForUpdates), findsNothing,
          reason: 'asserted by label as well as by hook, because a button that '
              'lost its identifier would pass the assertion above');

      handle.dispose();
    });

    // The other half of REQ-A1, and the reason the copy was rewritten rather than
    // reused: none of the app's failure vocabulary may appear for a state that is
    // not a failure. `firmwareNoUpdateFound` is excluded by `expectOnly` above; this
    // catches the shapes that would read as "check failed / cannot connect".
    testWidgets('does not read as a failure', (tester) async {
      await pump(
        tester,
        const FirmwareUpdateState(),
        testBanksData,
      );

      for (final failureCopy in [
        loc.generalError,
        loc.retry,
        loc.tryAgain,
      ]) {
        expect(find.text(failureCopy), findsNothing,
            reason: '"$failureCopy" is failure copy, and a router that was '
                'built without the fwup stack has not failed at anything');
      }
    });
  });

  group('nothing has been checked', () {
    // The resting state, and the state a *failed* check returns to — the notifier
    // publishes `notChecked` rather than `noUpdateFound` for exactly this reason, so
    // one assertion covers both. A card that filled this gap with the up-to-date
    // sentence is the defect the ticket names: "we could not ask" rendered as "there
    // is nothing new".
    testWidgets('says nothing at all', (tester) async {
      await pump(
        tester,
        const FirmwareUpdateState(),
        testThreeInstanceBanksData,
      );

      expectOnly(null);
      expect(find.bySemanticsIdentifier('firmware-check'), findsOneWidget);
    });

    testWidgets('and a check in flight does not leave the last verdict up',
        (tester) async {
      await pump(
        tester,
        const FirmwareUpdateState(
          phase: FirmwareUpdatePhase.checkingOta,
          otaCheck:
              FirmwareOtaCheckResult.updateAvailable(version: '2.0.1.26091009'),
        ),
        testThreeInstanceBanksData,
      );

      // The state is unreachable in the app — `checkForUpdate` clears the verdict
      // before it moves the phase — and pinned anyway, because "unreachable" is a
      // claim about one method and this widget is read by two pages plus the gate.
      expectOnly(null);
      expect(
          find.text(loc.availableVersionLabel('2.0.1.26091009')), findsNothing,
          reason: 'a verdict beside a running spinner reads as the new answer');
    });
  });

  /// An update is running that this page did not start (#1551, REQ-A6).
  ///
  /// Auto-update flashes on its own, so the page can be *opened* mid-install and the
  /// observe read promotes the phase — `checkingOta` is the only phase a tap here
  /// ever sets, and `installing` arrives without one. A live Check button in that
  /// state cost four things at once, and none of them are hypothetical: the phase
  /// change to `checkingOta` takes the "do not power off" card off the screen
  /// (`_buildInstallCard` draws nothing for it), the dispatch is a second
  /// `Download()` at a router writing NAND, the verdict re-offers "Update Now" on top
  /// of the running update, and the progress the user was watching is gone until the
  /// next poll.
  group('an update is already running', () {
    testWidgets('the check button is still there, and dead', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        otaInstallProgressState(FirmwareAutoUpdateStatus.downloading,
            progress: 40),
        testThreeInstanceBanksData,
      );

      final hook = find.bySemanticsIdentifier('firmware-check');
      expect(hook, findsOneWidget,
          reason: 'not removed: an E2E spec waiting on this control would see '
              'it vanish for the duration of an update it is watching, and a '
              'button that comes back is harder to read than one that is off');
      expect(
        tester.getSemantics(hook),
        isSemantics(hasEnabledState: true, isEnabled: false),
        reason: 'asserted through semantics because that is what a screen '
            'reader and a Playwright `toBeDisabled()` actually read — a '
            'greyed-out button that still reports enabled is a live control',
      );

      final button = tester.widget<AppButton>(find.byWidgetPredicate((widget) =>
          widget is AppButton && widget.identifier == 'firmware-check'));
      expect(button.onTap, isNull,
          reason: 'and through the mechanism: `AppButton._isEnabled` is '
              '`onTap != null && !isLoading`, so nulling the callback is what '
              'refuses the tap');
      expect(button.isLoading, isFalse,
          reason: 'no spinner on this button — nothing it started is in '
              'flight, and a busy check button would claim the running '
              'download was a check');

      handle.dispose();
    });

    // The other side of the same `&&`, and the reason it is not just
    // `state.isUpdating`: a check *this* button started is also an update in flight,
    // and killing the button for it would drop `isLoading` — the one state the
    // button has that says the tap worked.
    testWidgets('but a check of its own still spins rather than dying',
        (tester) async {
      await pump(
        tester,
        checkingOtaState,
        testThreeInstanceBanksData,
      );

      final button = tester.widget<AppButton>(find.byWidgetPredicate((widget) =>
          widget is AppButton && widget.identifier == 'firmware-check'));
      expect(button.isLoading, isTrue);
      expect(button.onTap, isNotNull,
          reason: '`isLoading` already refuses the tap, and nulling it as well '
              'would re-state that in a second place');
    });
  });

  // ---------------------------------------------------------------------------
  // #1572 — what the *router* remembers, on a page nobody has asked anything on.
  // ---------------------------------------------------------------------------
  group('the router history line', () {
    testWidgets('a router that has not checked since boot says so',
        (tester) async {
      // The fifth rendering, and the gap it fills: `notChecked` absorbs both "never
      // checked" and "the check failed", so this state used to show a bare button and
      // the user could not tell the two apart.
      await pump(
        tester,
        const FirmwareUpdateState(phase: FirmwareUpdatePhase.idle),
        testThreeInstanceBanksData,
        autoUpdate:
            FirmwareUpdateTestData.autoUpdateModel(checkedAfterBoot: false),
      );

      expect(find.text(loc.firmwareNotCheckedYet), findsOneWidget);
      expect(find.text(loc.firmwareNoUpdateFound), findsNothing);
      expect(find.text(loc.updateAvailable), findsNothing);
    });

    testWidgets('a router that did not report the field says nothing',
        (tester) async {
      // The distinction the nullable mapping exists for: null is the router not
      // answering, and asserting "not checked yet" from silence is the same class of
      // defect as asserting "up to date" from a timeout.
      await pump(
        tester,
        const FirmwareUpdateState(phase: FirmwareUpdatePhase.idle),
        testThreeInstanceBanksData,
        autoUpdate: FirmwareUpdateTestData.autoUpdateModel(),
      );

      expect(find.text(loc.firmwareNotCheckedYet), findsNothing);
      expect(find.text(loc.firmwareLastCheckDidNotFinish), findsNothing);
    });

    testWidgets('a failure the router still holds is shown as history',
        (tester) async {
      // The overnight scheduled check that could not reach the server. Stated as
      // history and with no retry, because the value is undated — see
      // `FirmwareAutoUpdateUIModel.errorCode`.
      await pump(
        tester,
        const FirmwareUpdateState(phase: FirmwareUpdatePhase.idle),
        testThreeInstanceBanksData,
        autoUpdate: FirmwareUpdateTestData.autoUpdateModel(
          checkedAfterBoot: true,
          errorCode: FirmwareUpdateErrorCode.serverUnreachable,
        ),
      );

      expect(find.text(loc.firmwareLastCheckDidNotFinish), findsOneWidget);
      expect(find.text(loc.firmwareErrorServerUnreachable), findsOneWidget);
      expect(find.text(loc.firmwareNoUpdateFound), findsNothing);
    });

    testWidgets('this session\'s verdict outranks the router\'s history',
        (tester) async {
      // A check that ran in this session is a later answer than the row. The history
      // line only exists for `notChecked`, so a stale reason must not sit under a
      // fresh "nothing found".
      await pump(
        tester,
        const FirmwareUpdateState(
          phase: FirmwareUpdatePhase.idle,
          otaCheck: FirmwareOtaCheckResult.noUpdateFound(),
        ),
        testThreeInstanceBanksData,
        autoUpdate: FirmwareUpdateTestData.autoUpdateModel(
          checkedAfterBoot: false,
          errorCode: FirmwareUpdateErrorCode.serverUnreachable,
        ),
      );

      expect(find.text(loc.firmwareNoUpdateFound), findsOneWidget);
      expect(find.text(loc.firmwareNotCheckedYet), findsNothing);
      expect(find.text(loc.firmwareLastCheckDidNotFinish), findsNothing);
    });

    testWidgets('a check this session failed shows no history line',
        (tester) async {
      // `checkFailed` reports through the snack bar, which is transient by design.
      // Letting the history line fill the space would put a *different*, undated
      // reason on the card immediately underneath it.
      await pump(
        tester,
        const FirmwareUpdateState(
          phase: FirmwareUpdatePhase.idle,
          otaCheck: FirmwareOtaCheckResult.checkFailed(
              FirmwareUpdateErrorCode.serverResponse),
        ),
        testThreeInstanceBanksData,
        autoUpdate: FirmwareUpdateTestData.autoUpdateModel(
          checkedAfterBoot: false,
          errorCode: FirmwareUpdateErrorCode.serverUnreachable,
        ),
      );

      expect(find.text(loc.firmwareNotCheckedYet), findsNothing);
      expect(find.text(loc.firmwareLastCheckDidNotFinish), findsNothing);
      expect(find.text(loc.firmwareNoUpdateFound), findsNothing);
    });
  });
}
