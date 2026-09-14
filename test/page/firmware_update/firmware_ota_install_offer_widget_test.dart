import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_ota_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../golden_test/golden_framework/mocks/mock_firmware_update.dart';
import '../../golden_test/page/firmware_update/fixtures/firmware_update_test_data.dart';
import '../../mocks/provider_overrides/mock_common.dart';

/// The OTA page's install offer, and what happens when it is taken (#1551, W5).
///
/// #1550 left this page able to *ask* and unable to *act*: the check moved off the
/// cloud API onto the router, and the install that went with it needed a
/// `downloadUrl` only the cloud answer carried. So the whole subject here is the
/// button that closes that gap and the four decisions behind it:
///
///   * **when it is offered.** Three independent facts have to line up — the router
///     has the virtual `ota` row, the last check found an image, and nothing is
///     already running. Each is varied on its own below, because an offer that
///     appears on a router with nothing to fetch dispatches a `Download()` that can
///     only fail, and one that appears mid-flash starts a second update on top of
///     the first;
///   * **it asks before it acts.** A firmware update reboots the router. The
///     dispatch is behind `showConfirmActionDialog`, and declining has to dispatch
///     *nothing* rather than dispatch and cancel;
///   * **`flashing` is not success.** It means the router is committed and has
///     stopped answering, so the view hands off to `enterRecoveryWaiting()` and the
///     recovery dialog exactly as the manual path does. Every other verdict is
///     already on the card and must start no reboot wait at all;
///   * **a refusal is not a failure.** `OperationGuard` throws above the phase
///     change, so a refused install leaves the page in `idle` with no failure card
///     to read — the snack bar is the only channel that can say so.
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
    _RecordingNotifier notifier,
    FirmwareBanksData banks, {
    List<Override> extra = const [],
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
        // Not `firmwareUpdateOverrides`: that helper builds its own fixed
        // notifier, and every assertion in this file is about what the view asked
        // the notifier to do. The other two overrides are the same ones it sets.
        firmwareUpdateNotifierProvider.overrideWith(() => notifier),
        firmwareBanksDataProvider
            .overrideWith(() => FixedFirmwareBanksDataNotifier(banks)),
        systemInfoDataProvider.overrideWith(
            () => FixedSystemInfoDataNotifier(testSystemInfoData)),
        ...extra,
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

  /// A wide surface, so the offer sits on its own line without the card stacking.
  /// The stacked geometry renders the same widget and is measured by the layout
  /// gate; this file asserts behaviour only.
  ///
  /// Frames rather than `pumpAndSettle` throughout: the check card's button and the
  /// recovery dialog both draw indeterminate loaders, which never settle.
  Future<void> pump(
    WidgetTester tester,
    _RecordingNotifier notifier,
    FirmwareBanksData banks, {
    List<Override> extra = const [],
  }) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(notifier, banks, extra: extra));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Tap the offer and let the confirm dialog come in.
  Future<void> tapOffer(WidgetTester tester) async {
    await tester.tap(find.text(loc.updateNow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Answer the confirm dialog. `loc.update` is the confirm label and is a
  /// distinct string from `loc.updateNow` on the card behind it, so neither tap
  /// can land on the other by accident.
  Future<void> answer(WidgetTester tester, {required bool yes}) async {
    await tester.tap(find.text(yes ? loc.update : loc.cancel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('when the offer appears', () {
    testWidgets('an image is waiting, so it is offered', (tester) async {
      final handle = tester.ensureSemantics();
      final notifier = _RecordingNotifier(otaUpdateAvailableState);
      await pump(tester, notifier, testThreeInstanceBanksData);

      expect(find.bySemanticsIdentifier('firmware-ota-install'), findsOneWidget,
          reason: 'the one control that starts a router-side update must be '
              'locatable by id — an E2E spec cannot click a localized label');
      expect(find.text(loc.updateNow), findsOneWidget);

      handle.dispose();
    });

    // Each row removes exactly one of the three facts the offer needs, so a
    // condition that was dropped shows up as one failure rather than none.
    final withheld =
        <String, ({FirmwareUpdateState state, FirmwareBanksData banks})>{
      'nothing has been checked yet': (
        state: idleNoFileState,
        banks: testThreeInstanceBanksData,
      ),
      'the router was asked and had nothing': (
        state: const FirmwareUpdateState(
          phase: FirmwareUpdatePhase.idle,
          activeBank: testActiveBank,
          targetBank: testAvailableBank,
          otaCheck: FirmwareOtaCheckResult.noUpdateFound(),
        ),
        banks: testThreeInstanceBanksDataNoImage,
      ),
      'the router has no ota row to download onto': (
        state: otaUpdateAvailableState,
        banks: testBanksData,
      ),
      'an update is already running': (
        state: otaUpdateAvailableState.copyWith(
            phase: FirmwareUpdatePhase.installing),
        banks: testThreeInstanceBanksData,
      ),
    };

    withheld.forEach((why, fixture) {
      testWidgets('$why, so it is not', (tester) async {
        final handle = tester.ensureSemantics();
        final notifier = _RecordingNotifier(fixture.state);
        await pump(tester, notifier, fixture.banks);

        expect(find.bySemanticsIdentifier('firmware-ota-install'), findsNothing,
            reason: 'no offer when $why');
        expect(find.text(loc.updateNow), findsNothing,
            reason: 'asserted by label as well as by hook, because an offer '
                'that lost its identifier would pass the assertion above');

        handle.dispose();
      });
    });
  });

  group('taking the offer', () {
    testWidgets('asks before it dispatches anything', (tester) async {
      final notifier = _RecordingNotifier(otaUpdateAvailableState);
      await pump(tester, notifier, testThreeInstanceBanksData);
      await tapOffer(tester);

      expect(find.text(loc.firmwareInstallConfirmMessage), findsOneWidget,
          reason: 'the router reboots — the user is told so first');
      expect(notifier.dispatched, isEmpty,
          reason: 'nothing may reach the router before the dialog is answered');
    });

    testWidgets('declining dispatches nothing at all', (tester) async {
      final notifier = _RecordingNotifier(otaUpdateAvailableState);
      await pump(tester, notifier, testThreeInstanceBanksData);
      await tapOffer(tester);
      await answer(tester, yes: false);

      expect(notifier.dispatched, isEmpty,
          reason:
              'declining must not dispatch and then cancel — a `Download()` '
              'that reached mode 2 cannot be taken back');
      expect(notifier.recoveryWaits, 0);
      expect(find.text(loc.firmwareInstallConfirmMessage), findsNothing,
          reason: 'the dialog is gone');
    });

    testWidgets('confirming dispatches on the virtual ota instance',
        (tester) async {
      final notifier = _RecordingNotifier(otaUpdateAvailableState);
      await pump(tester, notifier, testThreeInstanceBanksData);
      await tapOffer(tester);
      await answer(tester, yes: true);

      // 3, from `testThreeInstanceBanksData` — the virtual row, not either
      // physical bank. Dispatching on a bank instance is the mistake this pins:
      // `Download()` on a NAND bank has no meaning, and instance 3 is the only
      // one the fwup stack answers for.
      expect(notifier.dispatched, [3],
          reason: 'the install is dispatched once, on the ota instance');
    });
  });

  group('what the verdict does', () {
    testWidgets('flashing hands off to the shared recovery wait',
        (tester) async {
      final notifier = _RecordingNotifier(otaUpdateAvailableState);
      await pump(tester, notifier, testThreeInstanceBanksData,
          // The recovery dialog reads this provider, and the fixed state is
          // `waitingForRecovery` — which is also what the view sees after the
          // dialog closes, so `verify()` must not run. Pinned below.
          extra: recoveryDialogOverrides());
      await tapOffer(tester);
      await answer(tester, yes: true);

      expect(notifier.recoveryWaits, 1,
          reason: '`flashing` means the router is committed and has stopped '
              'answering — the reboot wait is the only thing that can happen '
              'next');
      expect(find.text(loc.routerIsRebooting), findsOneWidget,
          reason: 'the same dialog the manual path shows, because it is the '
              'same reboot');
      expect(notifier.verifications, isEmpty,
          reason:
              'the session never came back, so there is nothing to verify — '
              'the redirect owns the page from here');

      // Popped by hand so the dialog's one-second ticker is disposed before the
      // test ends. In the app the recovery framework pops it on the transition to
      // `authenticated`, which a fixed state never makes.
      await _popDialog(tester, loc.routerIsRebooting);
    });

    testWidgets('and verifies the bank flip once the session is back',
        (tester) async {
      final notifier = _RecordingNotifier(otaUpdateAvailableState);
      await pump(tester, notifier, testThreeInstanceBanksData, extra: [
        appConnectionStateProvider.overrideWith(
          () => FixedAppConnectionStateNotifier(
            fixedState: AppConnectionState.authenticated,
          ),
        ),
      ]);
      await tapOffer(tester);
      await answer(tester, yes: true);
      await _popDialog(tester, loc.routerIsRebooting);

      // The version comes from the check verdict and the instance from the spare
      // physical bank: the router picks the slot, so the only slot it can boot
      // from is the one that was not active. Both are pinned because `verify()`
      // fails the update when the instance is wrong and merely logs when the
      // version is, so a swapped pair would look like a successful update.
      expect(notifier.verifications, ['2.0.1.26091009@2']);
    });

    testWidgets('an install that found nothing waits for no reboot',
        (tester) async {
      final notifier = _RecordingNotifier(
        otaUpdateAvailableState,
        verdict: FirmwareOtaInstallVerdict.idle,
      );
      await pump(tester, notifier, testThreeInstanceBanksData);
      await tapOffer(tester);
      await answer(tester, yes: true);

      // Mode 2 checks before it downloads, so an accepted dispatch can still find
      // nothing — the version we offered was superseded. The notifier has already
      // published that on the card; a reboot wait here would block the page on a
      // router that is not restarting.
      expect(notifier.dispatched, [3]);
      expect(notifier.recoveryWaits, 0);
      expect(find.text(loc.routerIsRebooting), findsNothing);
    });
  });

  group('when the install is refused or fails', () {
    testWidgets('a refusal is said out loud, because no card will say it',
        (tester) async {
      final notifier = _RecordingNotifier(
        otaUpdateAvailableState,
        throws: const UnauthorizedError(),
      );
      await pump(tester, notifier, testThreeInstanceBanksData);
      await tapOffer(tester);
      await answer(tester, yes: true);

      expect(find.text(loc.errorUnauthorized), findsOneWidget,
          reason: '`OperationGuard.enforce` throws above the phase change, so '
              'the page stays in `idle` and the failure card is never reached — '
              'without this the button would appear to do nothing');
      expect(notifier.recoveryWaits, 0);
    });

    testWidgets('any other failure names the operation that did not start',
        (tester) async {
      final notifier = _RecordingNotifier(
        otaUpdateAvailableState,
        throws: const NetworkError(detail: 'bridge closed'),
      );
      await pump(tester, notifier, testThreeInstanceBanksData);
      await tapOffer(tester);
      await answer(tester, yes: true);

      expect(find.text(loc.failedToStartOtaUpdate), findsOneWidget);
      expect(notifier.recoveryWaits, 0);
      expect(find.text('bridge closed'), findsNothing,
          reason: 'the diagnostic detail is firmware/WASM text and is logged, '
              'not shown');
    });

    testWidgets('refuses before it asks when no spare bank was reported',
        (tester) async {
      final notifier = _RecordingNotifier(const FirmwareUpdateState(
        phase: FirmwareUpdatePhase.idle,
        activeBank: testActiveBank,
        otaCheck:
            FirmwareOtaCheckResult.updateAvailable(version: '2.0.1.26091009'),
      ));
      await pump(tester, notifier, testThreeInstanceBanksData);
      await tapOffer(tester);

      // Before the dialog, not after. Without a spare bank there is nothing to
      // check the reboot against, so `verify()` would fail with "expected bank
      // not present" *after* the router had already flashed and restarted —
      // refusing while nothing has happened is the honest ordering.
      expect(find.text(loc.noTargetBankAvailable), findsOneWidget);
      expect(find.text(loc.firmwareInstallConfirmMessage), findsNothing,
          reason: 'the user is not asked to confirm an update that will be '
              'refused either way');
      expect(notifier.dispatched, isEmpty);
    });
  });
}

/// Pops a dialog found by a string in it, through the root navigator the dialog
/// was pushed on.
Future<void> _popDialog(WidgetTester tester, String anchor) async {
  Navigator.of(tester.element(find.text(anchor)), rootNavigator: true).pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// A [FixedFirmwareUpdateNotifier] that remembers what the view asked it to do.
///
/// The fixed state does not move, on purpose: every test here is about the
/// *request* the view makes, and a fake that also republished a new state would
/// let a passing assertion come from the fake's own bookkeeping rather than from
/// the view.
class _RecordingNotifier extends FixedFirmwareUpdateNotifier {
  _RecordingNotifier(
    FirmwareUpdateState state, {
    this.verdict = FirmwareOtaInstallVerdict.flashing,
    this.throws,
  }) : super(state);

  /// What the watch reports back. `flashing` by default: it is the only verdict
  /// with anything for the view to do.
  final FirmwareOtaInstallVerdict verdict;

  /// Thrown instead of answering, for the refusal and failure arms.
  final Object? throws;

  final List<int> dispatched = [];

  /// `'<expectedVersion>@<expectedActiveInstance>'` per `verify()` call.
  final List<String> verifications = [];

  int recoveryWaits = 0;

  @override
  Future<FirmwareOtaInstallResult> triggerRouterOtaInstall({
    required int otaInstance,
  }) async {
    dispatched.add(otaInstance);
    final error = throws;
    if (error != null) throw error;
    return FirmwareOtaInstallResult(verdict: verdict);
  }

  @override
  void enterRecoveryWaiting({
    Duration cooldown = const Duration(seconds: 60),
  }) {
    recoveryWaits++;
  }

  @override
  Future<void> verify({
    required String expectedVersion,
    required int expectedActiveInstance,
  }) async {
    verifications.add('$expectedVersion@$expectedActiveInstance');
  }
}
