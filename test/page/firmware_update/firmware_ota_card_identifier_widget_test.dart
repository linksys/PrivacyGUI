import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_auto_update_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_ota_card.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../mocks/provider_overrides/mock_admin.dart';
import '../../mocks/provider_overrides/mock_firmware_update.dart';

/// Verifies the E2E identifier hooks on [FirmwareOtaCard], added by #1549.
///
/// Four hooks, named for symmetry with the manual card's `firmware-card-*`
/// family: the card arrival anchor, the block that opens the OTA page, the
/// current-version value, and the offer line. `firmware-ota-card-open` is
/// deliberately distinct from the OTA *page*'s own `firmware-check` — the card
/// navigates and nothing more, so a spec that confused them would tap the wrong
/// surface and still pass on the way in.
///
/// **`-open` replaced `-check` on 2026-09-15**, when the button whose label
/// promised a check became a whole-block tap that admits it only opens a page.
/// The rename is asserted here only in the sense that the old id is gone; what
/// this file adds is the tap itself, hosted in a real `GoRouter` so "the hook is
/// on the thing that navigates" is one assertion rather than two hopeful ones.
///
/// **This card owns "current version" for the whole Administration page.** It
/// took the hook over from [FirmwareUpdateCard] because the manual card is the
/// one hidden in remote assistance; the absent half of that decision is
/// asserted in `firmware_update_card_identifier_widget_test.dart`, so the pair
/// pins one owner from both sides.
///
/// Deliberately NOT tagged `ui`, matching its sibling: this repo's CI runs only
/// `run_tests.sh` (`--exclude-tags=golden||loc||ui`), and the identifier
/// contract is worth gating there.
void main() {
  const cardAnchor = 'firmware-ota-card';
  const openHook = 'firmware-ota-card-open';
  const versionHook = 'firmware-ota-card-version';
  const offerHook = 'firmware-ota-card-offer';
  const autoUpdateHook = 'firmware-ota-card-auto-update';

  // From the shared admin fixture `gateAdminSystemInfo`, whose one active bank
  // carries this version. The card reads it as `activeVersion`.
  const activeVersion = '1.0.16.213451';

  // From `gateFirmwareBanksWithOta`'s third row — the virtual `ota` instance,
  // which is the only place the version being *offered* exists.
  const offeredVersion = '1.0.17.220118';

  /// Where a tap on the block landed, or null if nothing navigated.
  String? navigatedTo;

  setUp(() => navigatedTo = null);

  Widget wrap({List<Override>? overrides}) {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    // A router rather than `home:`, because the card's one action is
    // `pushNamed` — under a plain `MaterialApp` a tap throws instead of
    // navigating, which is a pass nobody asked for.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) => const Scaffold(body: FirmwareOtaCard()),
        ),
        GoRoute(
          path: '/ota',
          name: RouteNamed.uspFirmwareOta,
          builder: (context, state) {
            navigatedTo = RouteNamed.uspFirmwareOta;
            return const Scaffold(body: Text('ota page'));
          },
        ),
      ],
    );
    return ProviderScope(
      // The card watches `systemInfoDataProvider`, `firmwareAutoUpdateDataProvider`
      // (#1552) and `firmwareBanksDataProvider` (the offer line);
      // `adminPageOverrides` pins all three — the first to a fixture with an
      // active firmware bank so the version value and the chevron render (the
      // loading branch hides both), the second to a reading whose policy is
      // `autoInstall`, so the switch arrives ON, and the third to a router
      // reporting an `ota` image, so the offer line is on screen.
      overrides: overrides ?? adminPageOverrides(),
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeConfig.createLightTheme(),
        routerConfig: router,
      ),
    );
  }

  Future<void> pumpCard(WidgetTester tester,
      {List<Override>? overrides}) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(overrides: overrides));
    await tester.pumpAndSettle();
  }

  /// The one switch on the card, reached *through* its E2E hook.
  ///
  /// Via `find.ancestor` rather than `find.byType` alone so the assertions below
  /// prove the identifier and the control are the same widget — a hook that
  /// drifted onto the row instead of the switch would still satisfy the
  /// "locatable" test above.
  AppSwitch switchOf(WidgetTester tester) => tester.widget<AppSwitch>(
        find.ancestor(
          of: find.bySemanticsIdentifier(autoUpdateHook),
          matching: find.byType(AppSwitch),
        ),
      );

  /// What the card last asked the router to store.
  ///
  /// `FixedFirmwareAutoUpdateNotifier.setPolicy` publishes locally instead of
  /// calling the service, and `withPolicy` derives `rawFlags` from the policy —
  /// so the published `rawFlags` is literally the string the card's tap would have
  /// written to `autoupdate_flags`. That is the REQ-C1 value under test here; the
  /// service test pins that nothing *else* is written with it.
  FirmwareAutoUpdateUIModel readingOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(FirmwareOtaCard)))
          .read(firmwareAutoUpdateDataProvider)
          .requireValue;

  group('FirmwareOtaCard identifiers', () {
    testWidgets('the card anchor, entry, version and offer are each locatable',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      final matched = <Element>{};
      for (final id in <String>[
        cardAnchor,
        openHook,
        versionHook,
        offerHook,
        autoUpdateHook,
      ]) {
        final finder = find.bySemanticsIdentifier(id);
        expect(finder, findsOneWidget,
            reason: 'hook "$id" must resolve to exactly one node');
        matched.add(finder.evaluate().single);
      }
      expect(matched, hasLength(5),
          reason: 'the five hooks must target distinct widgets');

      handle.dispose();
    });

    testWidgets('the retired check hook is gone, not renamed onto the block',
        (tester) async {
      // The id a spec would have used to press "Check for Updates" from here.
      // Keeping it alive on a block that only navigates is worse than removing
      // it: the spec would keep passing while asserting a check that never runs.
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      expect(
          find.bySemanticsIdentifier('firmware-ota-card-check'), findsNothing);
      expect(
          find.text(loc(tester.element(find.byType(FirmwareOtaCard)))
              .checkForUpdates),
          findsNothing,
          reason: 'the label promised a check this card never performed');

      handle.dispose();
    });

    testWidgets('the version hook wraps the active firmware version text',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      // The pinned node carries the identifier; the version string it wraps is
      // what E2E asserts against, so prove they are the same subtree.
      final version = find.descendant(
        of: find.bySemanticsIdentifier(versionHook),
        matching: find.text(activeVersion),
      );
      expect(version, findsOneWidget,
          reason:
              '"$versionHook" must wrap the active version "$activeVersion"');

      handle.dispose();
    });

    testWidgets('the entry is hidden while the router info is still loading',
        (tester) async {
      // The loading branch renders a skeleton in place of the version and drops
      // both the hook and the chevron, so a spec cannot tap its way into the OTA
      // page before this card has said anything. Pinned because a hook that
      // appears one frame early is exactly the flake E2E cannot diagnose — and
      // because the chevron would take 32px off the skeleton's caption at the
      // width the caption has least of it (#1380).
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: adminPageLoadingFirmwareOverrides(),
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
            home: const Scaffold(body: FirmwareOtaCard()),
          ),
        ),
      );
      // Not `pumpAndSettle`: the loading state never completes by design.
      await tester.pump();

      expect(find.bySemanticsIdentifier(cardAnchor), findsOneWidget,
          reason: 'the card itself is on screen either way — only its contents '
              'change');
      expect(find.bySemanticsIdentifier(openHook), findsNothing);
      expect(find.bySemanticsIdentifier(versionHook), findsNothing);
      expect(find.byIcon(AppFontIcons.chevronRight), findsNothing,
          reason: 'a chevron on a block that does not respond is an affordance '
              'that lies, and it costs the caption beside it 32px');

      handle.dispose();
    });
  });

  group('FirmwareOtaCard entry', () {
    testWidgets('tapping the block opens the OTA page', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      await tester.tap(find.bySemanticsIdentifier(openHook));
      await tester.pumpAndSettle();

      expect(navigatedTo, RouteNamed.uspFirmwareOta,
          reason: 'the whole block is the entry point now, so the hook and the '
              'navigation have to be the same node');
      handle.dispose();
    });

    testWidgets('the block announces itself as a button', (tester) async {
      // The reason this design is honest rather than merely tidier: a tappable
      // area that assistive tech reads as loose text is a worse affordance than
      // the mislabelled button it replaced. `LayoutBlock` sets the flag from
      // `onTap`, so this asserts the wiring, not the kit.
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      expect(tester.getSemantics(find.bySemanticsIdentifier(openHook)),
          isSemantics(isButton: true, hasTapAction: true));

      handle.dispose();
    });
  });

  group('FirmwareOtaCard offered version', () {
    testWidgets('states the offer and names the version', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      final l10n = loc(tester.element(find.byType(FirmwareOtaCard)));
      final offer = find.bySemanticsIdentifier(offerHook);
      expect(
          find.descendant(of: offer, matching: find.text(l10n.updateAvailable)),
          findsOneWidget);
      expect(
          find.descendant(
              of: offer,
              matching: find.text(l10n.availableVersionLabel(offeredVersion))),
          findsOneWidget,
          reason: 'the version the router is offering is the thing the deleted '
              'button used to promise to find out');
      // The same string is not also drawn as the current version.
      expect(
          find.descendant(
              of: find.bySemanticsIdentifier(versionHook),
              matching: find.text(offeredVersion)),
          findsNothing);

      handle.dispose();
    });

    testWidgets('says nothing when the router reports no ota row',
        (tester) async {
      // `gateFirmwareBanks` is a router with two NAND banks and no `ota`
      // instance — an OEM build without the fwup stack. Absent is the only
      // honest rendering: null means *no update information*, and printing "up
      // to date" here would be a claim nobody made.
      final handle = tester.ensureSemantics();
      await pumpCard(tester,
          overrides: adminPageOverrides(banks: gateFirmwareBanks));

      expect(find.bySemanticsIdentifier(offerHook), findsNothing);
      final l10n = loc(tester.element(find.byType(FirmwareOtaCard)));
      expect(find.text(l10n.updateAvailable), findsNothing);
      // The rest of the card is unaffected: two independent reads.
      expect(find.bySemanticsIdentifier(versionHook), findsOneWidget);

      handle.dispose();
    });

    testWidgets('says nothing when the ota row is not offering an image',
        (tester) async {
      // `Available=false` on the ota row. Two different facts arrive as that one
      // value — "checked, nothing new" and "nobody has asked yet" — so it
      // supports neither sentence.
      final handle = tester.ensureSemantics();
      await pumpCard(tester,
          overrides:
              adminPageOverrides(banks: _banksWithOta(available: false)));

      expect(find.bySemanticsIdentifier(offerHook), findsNothing);

      handle.dispose();
    });

    testWidgets('keeps the headline when the offered version is empty',
        (tester) async {
      // The router does publish `Available=true` with an empty `Version`. An
      // offer with no name is still an offer, so only the second line goes.
      final handle = tester.ensureSemantics();
      await pumpCard(tester,
          overrides: adminPageOverrides(banks: _banksWithOta(version: '')));

      final l10n = loc(tester.element(find.byType(FirmwareOtaCard)));
      expect(find.bySemanticsIdentifier(offerHook), findsOneWidget);
      expect(find.text(l10n.updateAvailable), findsOneWidget);
      expect(find.text(l10n.availableVersionLabel('')), findsNothing,
          reason: '"Available: " with nothing after it names no version');

      handle.dispose();
    });

    testWidgets('withdraws the offer when the banks read fails afterwards',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester,
          overrides: adminPageOverrides(
              banksNotifier: _FailAfterFirstReadBanksNotifier.new));
      expect(find.bySemanticsIdentifier(offerHook), findsOneWidget);

      final container = ProviderScope.containerOf(
          tester.element(find.byType(FirmwareOtaCard)));
      (container.read(firmwareBanksDataProvider.notifier)
              as _FailAfterFirstReadBanksNotifier)
          .failNow();
      await tester.pumpAndSettle();

      // The trap this asserts against, stated so a later simplification cannot
      // walk into it: riverpod attaches the previous reading to the error, so
      // `valueOrNull` still answers with the offer. Only `hasError` sees it.
      final published = container.read(firmwareBanksDataProvider);
      expect(published.hasError, isTrue);
      expect(published.hasValue, isTrue,
          reason: 'the stale reading rides along on the error — that is the '
              'whole reason the card checks hasError first');

      expect(find.bySemanticsIdentifier(offerHook), findsNothing,
          reason: 'an offer nobody can confirm any more is not an offer');
      expect(find.bySemanticsIdentifier(versionHook), findsOneWidget,
          reason: 'the current version comes from another read and survives');

      handle.dispose();
    });
  });

  group('FirmwareOtaCard auto-update toggle', () {
    // Only `autoInstall` is ON. `off` and `unknown` are read-only arrivals — a
    // router can reach `0` from the factory or the CLI, and `unknown` is a flag
    // this build does not define — and neither means the router installs by
    // itself, which is the one thing this control claims.
    const positions = {
      FirmwareAutoUpdatePolicy.autoInstall: true,
      FirmwareAutoUpdatePolicy.notifyOnly: false,
      FirmwareAutoUpdatePolicy.off: false,
      FirmwareAutoUpdatePolicy.unknown: false,
    };

    for (final entry in positions.entries) {
      testWidgets('sits ${entry.value ? "ON" : "OFF"} for ${entry.key.name}',
          (tester) async {
        final handle = tester.ensureSemantics();
        await pumpCard(tester,
            overrides: adminPageOverrides(
                autoUpdate: gateFirmwareAutoUpdateOn.withPolicy(entry.key)));

        final appSwitch = switchOf(tester);
        expect(appSwitch.value, entry.value);
        expect(appSwitch.isLoading, isFalse,
            reason: 'an answered read is not busy');
        expect(appSwitch.onChanged, isNotNull,
            reason: 'every readable policy is changeable — including the two '
                'the UI never writes');

        handle.dispose();
      });
    }

    testWidgets('turning it off asks for notify-only, never off',
        (tester) async {
      final handle = tester.ensureSemantics();
      // Arrives ON: the fixture's policy is `autoInstall`.
      await pumpCard(tester);
      expect(switchOf(tester).value, isTrue);

      await tester.tap(find.bySemanticsIdentifier(autoUpdateHook));
      await tester.pumpAndSettle();

      final reading = readingOf(tester);
      expect(reading.policy, FirmwareAutoUpdatePolicy.notifyOnly);
      expect(reading.rawFlags, '1',
          reason: 'REQ-C1: off writes 1. Writing 0 would also stop the router '
              'checking, which takes the dashboard banner away — a different '
              'request from "do not install things behind my back".');
      // Still checking, so the banner half of #1552 survives being switched off.
      expect(reading.checksForUpdates, isTrue);
      expect(switchOf(tester).value, isFalse);

      handle.dispose();
    });

    testWidgets('turning it on asks for auto-install', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester,
          overrides: adminPageOverrides(
              autoUpdate: gateFirmwareAutoUpdateOn
                  .withPolicy(FirmwareAutoUpdatePolicy.notifyOnly)));
      expect(switchOf(tester).value, isFalse);

      await tester.tap(find.bySemanticsIdentifier(autoUpdateHook));
      await tester.pumpAndSettle();

      final reading = readingOf(tester);
      expect(reading.policy, FirmwareAutoUpdatePolicy.autoInstall);
      expect(reading.rawFlags, '2');
      expect(switchOf(tester).value, isTrue);

      handle.dispose();
    });

    testWidgets('the whole row is absent when the reading failed',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester,
          overrides: adminPageOverrides(
              autoUpdateNotifier: _FailedReadAutoUpdateNotifier.new));

      expect(find.bySemanticsIdentifier(cardAnchor), findsOneWidget,
          reason: 'the rest of the card is unaffected — the two reads are '
              'independent');
      expect(find.bySemanticsIdentifier(autoUpdateHook), findsNothing,
          reason: 'a switch drawn from a failed read states a policy nobody '
              'knows, in whichever direction it points');
      expect(find.byType(AppSwitch), findsNothing);

      handle.dispose();
    });

    testWidgets('the switch is locked until the first reading lands',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notifier = _UnansweredAutoUpdateNotifier();
      await tester.pumpWidget(wrap(
          overrides: adminPageOverrides(autoUpdateNotifier: () => notifier)));
      // Not `pumpAndSettle`: the read never completes by design.
      await tester.pump();

      // Busy, and asserted through the tap rather than through `onChanged`.
      // `isLoading` is what refuses input — `AppSwitch` drops the handler itself
      // and already reports `enabled: false` — while `onChanged: null` would ask
      // for the *disabled* treatment on top, which the kit says busy is not. So
      // the assertion that matters is that the tap does nothing.
      expect(switchOf(tester).isLoading, isTrue);
      await tester.tap(find.bySemanticsIdentifier(autoUpdateHook));
      await tester.pump();

      expect(notifier.requested, isEmpty,
          reason: 'a tap here would write a policy derived from a value the '
              'router has not given yet');

      handle.dispose();
    });

    testWidgets('the switch is busy while the write is in flight',
        (tester) async {
      final handle = tester.ensureSemantics();
      final notifier = _PendingWriteAutoUpdateNotifier();
      await pumpCard(tester,
          overrides: adminPageOverrides(autoUpdateNotifier: () => notifier));
      expect(switchOf(tester).isLoading, isFalse);

      await tester.tap(find.bySemanticsIdentifier(autoUpdateHook));
      await tester.pump();

      // Mid-write the switch still shows the *old* position — ui_kit's contract
      // — and refuses a second tap, so a slow router cannot be handed two
      // conflicting writes.
      expect(switchOf(tester).isLoading, isTrue);
      expect(switchOf(tester).value, isTrue);
      await tester.tap(find.bySemanticsIdentifier(autoUpdateHook));
      await tester.pump();
      expect(notifier.requested, hasLength(1),
          reason: 'the busy switch must swallow the second tap, not queue a '
              'second write behind the first');

      notifier.completeWrite();
      await tester.pumpAndSettle();

      expect(switchOf(tester).isLoading, isFalse);
      expect(switchOf(tester).value, isFalse);
      expect(notifier.requested, [FirmwareAutoUpdatePolicy.notifyOnly]);

      handle.dispose();
    });
  });
}

/// [gateFirmwareBanksWithOta] with the ota row's two decisive fields open.
///
/// Local to this file rather than a shared fixture: `available: false` and
/// `version: ''` are shapes only this card's offer line branches on, and the gate
/// fixtures are shared by pages that would gain nothing from either.
FirmwareBanksData _banksWithOta(
        {bool available = true, String version = '1.0.17.220118'}) =>
    FirmwareBanksData(banks: [
      ...gateFirmwareBanks.banks,
      FirmwareImageUIModel(
        instance: 3,
        instancePath: 'Device.DeviceInfo.FirmwareImage.3.',
        alias: 'ota',
        name: '',
        version: version,
        status: available ? 'Available' : 'None',
        available: available,
      ),
    ]);

/// A banks read that succeeds and is then lost — the shape a router going away
/// mid-session produces, and the only one that tells `hasError` apart from
/// `valueOrNull == null`.
///
/// [failNow] assigns `AsyncError` through the notifier's own setter on purpose:
/// that is where riverpod's `asyncTransition` re-attaches the previous reading, so
/// the state the card sees is the real one rather than one this class composed.
class _FailAfterFirstReadBanksNotifier extends FirmwareBanksDataNotifier {
  @override
  Future<FirmwareBanksData> build() async => gateFirmwareBanksWithOta;

  void failNow() => state = AsyncError(
      const NetworkError(detail: 'FirmwareImage read failed'),
      StackTrace.empty);
}

/// A reading that failed, which [FixedFirmwareAutoUpdateNotifier] cannot hold.
class _FailedReadAutoUpdateNotifier extends FirmwareAutoUpdateDataNotifier {
  @override
  Future<FirmwareAutoUpdateUIModel> build() async =>
      throw const NetworkError(detail: 'autoupdate_flags read failed');
}

/// A reading that never arrives — the frame the switch has to render locked.
///
/// Records writes so the lock can be asserted by tapping it: the real
/// `setPolicy` would `await future` on a read that never lands, so a tap that got
/// through would hang rather than fail.
class _UnansweredAutoUpdateNotifier extends FirmwareAutoUpdateDataNotifier {
  final requested = <FirmwareAutoUpdatePolicy>[];

  @override
  Future<FirmwareAutoUpdateUIModel> build() =>
      Completer<FirmwareAutoUpdateUIModel>().future;

  @override
  Future<void> setPolicy(FirmwareAutoUpdatePolicy policy) async =>
      requested.add(policy);
}

/// A write the test finishes by hand, so the busy frame can be asserted.
class _PendingWriteAutoUpdateNotifier extends FirmwareAutoUpdateDataNotifier {
  final requested = <FirmwareAutoUpdatePolicy>[];
  Completer<void>? _pending;

  @override
  Future<FirmwareAutoUpdateUIModel> build() async => gateFirmwareAutoUpdateOn;

  @override
  Future<void> setPolicy(FirmwareAutoUpdatePolicy policy) async {
    requested.add(policy);
    final pending = _pending = Completer<void>();
    await pending.future;
    state = AsyncData(
        (state.valueOrNull ?? gateFirmwareAutoUpdateOn).withPolicy(policy));
  }

  void completeWrite() => _pending!.complete();
}
