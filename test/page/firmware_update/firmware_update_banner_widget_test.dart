import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
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
void main() {
  const bannerAnchor = 'firmware-update-banner';
  const updateHook = 'firmware-update-banner-update';
  const dismissHook = 'firmware-update-banner-dismiss';

  /// Where a tap on Update Now landed, or null if nothing navigated.
  String? navigatedTo;

  setUp(() => navigatedTo = null);

  Widget wrap({bool otaAvailable = true, String rawFlags = '2'}) {
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
            FixedFirmwareBanksDataNotifier(
                otaAvailable ? gateFirmwareBanksWithOta : gateFirmwareBanks)),
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

  Future<void> pump(WidgetTester tester,
      {bool otaAvailable = true, String rawFlags = '2'}) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
}
