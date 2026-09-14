import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_auto_update_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_ota_card.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../mocks/provider_overrides/mock_admin.dart';
import '../../mocks/provider_overrides/mock_firmware_update.dart';

/// Verifies the E2E identifier hooks on [FirmwareOtaCard], added by #1549.
///
/// Three hooks, named for symmetry with the manual card's `firmware-card-*`
/// family: the card arrival anchor, the check CTA, and the current-version
/// value. `firmware-ota-card-check` is deliberately distinct from the OTA
/// *page*'s own `firmware-check` — the card opens the page, so a spec that
/// confused them would tap the wrong surface and still pass on the way in.
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
  const checkHook = 'firmware-ota-card-check';
  const versionHook = 'firmware-ota-card-version';
  const autoUpdateHook = 'firmware-ota-card-auto-update';

  // From the shared admin fixture `gateAdminSystemInfo`, whose one active bank
  // carries this version. The card reads it as `activeVersion`.
  const activeVersion = '1.0.16.213451';

  Widget wrap({List<Override>? overrides}) {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    return ProviderScope(
      // The card watches `systemInfoDataProvider` and, since #1552,
      // `firmwareAutoUpdateDataProvider`; `adminPageOverrides` pins both — the
      // first to a fixture with an active firmware bank so the version value and
      // the CTA render (the loading branch hides both), the second to a reading
      // whose policy is `autoInstall`, so the switch arrives ON.
      overrides: overrides ?? adminPageOverrides(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeConfig.createLightTheme(),
        home: const Scaffold(body: FirmwareOtaCard()),
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
    testWidgets('the card anchor, CTA, and version are each locatable',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      final matched = <Element>{};
      for (final id in <String>[
        cardAnchor,
        checkHook,
        versionHook,
        autoUpdateHook,
      ]) {
        final finder = find.bySemanticsIdentifier(id);
        expect(finder, findsOneWidget,
            reason: 'hook "$id" must resolve to exactly one node');
        matched.add(finder.evaluate().single);
      }
      expect(matched, hasLength(4),
          reason: 'the four hooks must target distinct widgets');

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

    testWidgets('the CTA is hidden while the router info is still loading',
        (tester) async {
      // The loading branch renders a skeleton in place of the version and drops
      // the button entirely, so a spec cannot tap "check for updates" before
      // there is a version to compare against. Pinned because the skeleton
      // moved to this card with the version block, and a hook that appears one
      // frame early is exactly the flake E2E cannot diagnose.
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
      expect(find.bySemanticsIdentifier(checkHook), findsNothing);
      expect(find.bySemanticsIdentifier(versionHook), findsNothing);

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
