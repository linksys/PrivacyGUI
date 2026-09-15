import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_auto_update_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_banner_provider.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_available_banner.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../mocks/provider_overrides/mock_firmware_update.dart';

/// [FirmwareUpdateAvailableBanner]'s contract — REQ-C3.
///
/// The load-bearing test in this file is "no third action". The requirement asked
/// for a "Tonight" button, that was cut because nothing in the stack can name the
/// time it would promise, and a decision like that survives exactly as long as
/// someone remembers it. So it is asserted twice and from opposite directions:
/// once by counting the banner's buttons, and once by scanning `app_en.arb` for
/// every string that promises a time and requiring none of them on screen. The
/// count catches a third button with new copy; the scan catches a *renamed* one
/// reusing copy that already exists.
///
/// The second group is the redesign's own contract: this notice is a card inset to
/// the page margin, not the full-bleed strip it shipped as. That is not a taste
/// assertion — a full-bleed bar above a grid of inset cards is what made it read as
/// browser chrome, and the only way a revert shows up in a test is by measuring
/// where its edges are.
void main() {
  const bannerAnchor = 'firmware-update-banner';
  const updateHook = 'firmware-update-banner-update';
  const dismissHook = 'firmware-update-banner-dismiss';

  /// Where a tap on Update Now landed, or null if nothing navigated.
  String? navigatedTo;

  setUp(() => navigatedTo = null);

  Widget wrap(
      {bool otaAvailable = true,
      String rawFlags = '2',
      FirmwareBanksData? banks}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'test_root',
          builder: (context, state) =>
              const Scaffold(body: FirmwareUpdateAvailableBanner()),
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
      overrides: [
        firmwareAutoUpdateDataProvider.overrideWith(
            () => FixedFirmwareAutoUpdateNotifier(FirmwareAutoUpdateUIModel(
                  status: FirmwareAutoUpdateStatus.idle,
                  progress: 0,
                  rawState: '0',
                  policy: FirmwareAutoUpdatePolicy.fromRaw(rawFlags),
                  rawFlags: rawFlags,
                ))),
        firmwareBanksDataProvider.overrideWith(() =>
            FixedFirmwareBanksDataNotifier(banks ??
                (otaAvailable ? gateFirmwareBanksWithOta : gateFirmwareBanks))),
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

  /// [width] is a *screen* width, which is what `context.pageMargin` reads — so it
  /// picks the layout arm as well as the inset. 1280 is a single row (856px of
  /// content against the widget's 780px threshold); 375 is stacked.
  Future<void> pump(WidgetTester tester,
      {bool otaAvailable = true,
      String rawFlags = '2',
      double width = 1280}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Twice, because the first `pumpWidget` after the view metrics change can lay
    // out at the previous surface — and every assertion in the second group is a
    // coordinate.
    await tester
        .pumpWidget(wrap(otaAvailable: otaAvailable, rawFlags: rawFlags));
    await tester
        .pumpWidget(wrap(otaAvailable: otaAvailable, rawFlags: rawFlags));
    await tester.pumpAndSettle();
  }

  group('FirmwareUpdateAvailableBanner visibility', () {
    testWidgets('renders when the router checks and an image is waiting',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      expect(find.bySemanticsIdentifier(bannerAnchor), findsOneWidget);
      handle.dispose();
    });

    testWidgets('renders nothing when no image is waiting', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, otaAvailable: false);

      expect(find.bySemanticsIdentifier(bannerAnchor), findsNothing);
      expect(find.byType(AppButton), findsNothing,
          reason: 'a hidden banner must contribute no actions at all');
      handle.dispose();
    });

    testWidgets('renders nothing when the router is not checking',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, rawFlags: '0');

      expect(find.bySemanticsIdentifier(bannerAnchor), findsNothing);
      handle.dispose();
    });
  });

  group('FirmwareUpdateAvailableBanner actions', () {
    testWidgets('offers exactly two, and they are Update Now and Dismiss',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      final buttons = tester
          .widgetList<AppButton>(find.byType(AppButton))
          .map((b) => b.label)
          .toList();

      expect(buttons, hasLength(2),
          reason: 'REQ-C3 is two actions. A third is the "Tonight" button that '
              'was cut — see the banner widget for why.');
      expect(buttons.toSet(), {'Update Now', 'Dismiss'});

      expect(find.bySemanticsIdentifier(updateHook), findsOneWidget);
      expect(find.bySemanticsIdentifier(dismissHook), findsOneWidget);
      handle.dispose();
    });

    testWidgets('no action promises a time', (tester) async {
      await pump(tester);

      // Every English string in the app that commits to a moment. Derived from
      // the ARB rather than hand-listed so a future "Install tonight" string
      // enrols itself: whatever someone adds, if it names a time it lands here.
      final arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
      final timePromising = RegExp(
        r'\b(tonight|overnight|tomorrow|schedule[ds]?|scheduling|later|'
        r'this evening|remind me)\b',
        caseSensitive: false,
      );
      final forbidden = arb.entries
          .where((e) => !e.key.startsWith('@') && e.value is String)
          .map((e) => e.value as String)
          .where(timePromising.hasMatch)
          .toSet();
      expect(forbidden, isNotEmpty,
          reason: 'the scan must have something to look for, or it proves '
              'nothing — if this fails, the regex stopped matching the ARB');

      for (final phrase in forbidden) {
        expect(find.textContaining(phrase, findRichText: true), findsNothing,
            reason: 'the banner must not promise a time: found "$phrase"');
      }
    });

    testWidgets('Dismiss hides the banner and records which version',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(FirmwareUpdateAvailableBanner)),
      );
      expect(
          container.read(firmwareUpdateBannerDismissedVersionProvider), isNull);

      await tester.tap(find.bySemanticsIdentifier(dismissHook));
      await tester.pumpAndSettle();

      // The version the fixture's ota row is offering, not merely `true`: the
      // next build the router finds is a new notice and has to arrive.
      expect(container.read(firmwareUpdateBannerDismissedVersionProvider),
          gateFirmwareBanksWithOta.otaInstance!.version);
      expect(find.bySemanticsIdentifier(bannerAnchor), findsNothing);
      // The router still holds an update — dismissing is the user hiding a
      // notice, not the notice becoming untrue.
      expect(
        container.read(firmwareAutoUpdateDataProvider).requireValue.rawFlags,
        '2',
      );
      handle.dispose();
    });

    testWidgets('Update Now opens the OTA page rather than starting a flash',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);

      await tester.tap(find.bySemanticsIdentifier(updateHook));
      await tester.pumpAndSettle();

      expect(navigatedTo, RouteNamed.uspFirmwareOta,
          reason: 'the install verb lives on the OTA page, behind its own '
              'confirmation');
      // Navigating away must not have dismissed anything: the banner is still
      // true until the image is installed.
      final container = ProviderScope.containerOf(
        tester.element(find.text('ota page')),
      );
      expect(
          container.read(firmwareUpdateBannerDismissedVersionProvider), isNull);
      handle.dispose();
    });
  });

  group('FirmwareUpdateAvailableBanner shape', () {
    testWidgets('is a card inset to the page margin, not a full-bleed strip',
        (tester) async {
      await pump(tester);

      expect(find.byType(AppCard), findsOneWidget,
          reason: 'the notice goes through AppCard so AppSurface resolves the '
              'design language — radius, border, shadow, texture and the '
              'content colour it cascades. A Container(color:) renders the '
              'same under all eight themes, which is what it used to do.');

      final context =
          tester.element(find.byType(FirmwareUpdateAvailableBanner));
      final inset = context.pageMargin;
      // The same inset the dashboard grid uses, read from the same context rather
      // than hard-coded, so this measures alignment rather than a number.
      expect(inset, greaterThan(0));

      final surface = tester.getSize(find.byType(MaterialApp)).width;
      final left =
          tester.getTopLeft(find.text(loc(context).firmwareUpdateAvailable)).dx;
      final right = tester
          .getBottomRight(find.widgetWithText(AppButton, 'Update Now'))
          .dx;

      expect(left, greaterThanOrEqualTo(inset),
          reason:
              'a full-bleed strip starts at the screen edge; this one starts '
              'where the cards under it start');
      expect(right, lessThanOrEqualTo(surface - inset),
          reason: 'and ends where they end — both edges, or a strip with '
              'padding would pass');
    });

    testWidgets('names the version the router is offering', (tester) async {
      await pump(tester);

      // The banner used to say only that *an* update existed. The version is the
      // one fact that lets a user tell this notice from the one they dismissed.
      expect(find.textContaining(gateFirmwareBanksWithOta.otaInstance!.version),
          findsOneWidget);
    });

    testWidgets('drops the version line when the row has to stack',
        (tester) async {
      await pump(tester, width: 375);

      // Deliberate, and the reason is measured: stacked, the version line is a
      // whole extra line on the widths where the sentence above it is already
      // wrapping — while in the single row it costs nothing, because the 48px
      // buttons beside it already set the row's height. The OTA page this
      // banner's own button opens names the version.
      expect(find.textContaining(gateFirmwareBanksWithOta.otaInstance!.version),
          findsNothing);
      // Still a notice, still both actions — only the second line went.
      expect(find.byType(AppButton), findsNWidgets(2));
      final context =
          tester.element(find.byType(FirmwareUpdateAvailableBanner));
      expect(find.text(loc(context).firmwareUpdateAvailable), findsOneWidget);
    });

    testWidgets('renders no version line when the router reports none',
        (tester) async {
      // Some builds publish `Available=true` with an empty `Version`. "Available: "
      // with nothing after it is worse than no line — the same rule the wizard's
      // install card follows.
      await tester.pumpWidget(wrap(banks: _otaWithNoVersion));
      await tester.pumpAndSettle();

      expect(find.textContaining('Available:'), findsNothing);
      expect(find.byType(AppButton), findsNWidgets(2),
          reason: 'only the version line is conditional; the notice itself is '
              'true either way');
    });
  });
}

/// [gateFirmwareBanksWithOta]'s ota row with the version omitted.
///
/// Local rather than in `mock_firmware_update.dart`: it is not a state any gate cell
/// or harness should render, only the one this file's guard is about.
const _otaWithNoVersion = FirmwareBanksData(banks: [
  FirmwareImageUIModel(
    instance: 1,
    instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
    alias: 'fw1',
    name: 'firmware-bank-1',
    version: '1.0.16.213451',
    status: 'Active',
    available: true,
    isBootTarget: true,
  ),
  FirmwareImageUIModel(
    instance: 3,
    instancePath: 'Device.DeviceInfo.FirmwareImage.3.',
    alias: 'ota',
    name: '',
    version: '',
    status: 'Available',
    available: true,
  ),
]);
