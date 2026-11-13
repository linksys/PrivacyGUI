import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/instant_setup/models/troubleshooting_phase.dart';
import 'package:privacy_gui/page/instant_setup/providers/internet_troubleshooting_provider.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_pppoe_view.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_common.dart';
import '../../../mocks/provider_overrides/mock_internet_troubleshooting.dart';
import '../../../mocks/test_data/scenes/pnp_scene_data.dart';

/// The PPPoE form's prefill from the router's WAN (#1511 P1).
///
/// The form fills itself once, from the first WAN read that completes — and
/// only once, so a later read (one after an ISP save, say) never overwrites
/// what the user typed. The static-IP form runs the same code over its own
/// fields.
void main() {
  late ProviderContainer container;
  late List<UspInternetSettingsForm?> reads;

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    var call = 0;
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const PnpPppoeView()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...commonOverrides(),
        internetTroubleshootingProvider.overrideWith(
          () => FixedInternetTroubleshootingNotifier(
              const TroubleshootingNoInternet()),
        ),
        troubleshootingWanPrefillProvider.overrideWith((ref) async {
          final answer = reads[call < reads.length ? call : reads.length - 1];
          call++;
          return answer;
        }),
      ],
      child: MaterialApp.router(
        theme: AppTheme.create(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ));
    container =
        ProviderScope.containerOf(tester.element(find.byType(PnpPppoeView)));
    await tester.pump();
    await tester.pump();
  }

  String username(WidgetTester tester) => tester
      .widget<EditableText>(find.byType(EditableText).first)
      .controller
      .text;

  testWidgets('fills the form from the WAN once it has been read',
      (tester) async {
    reads = [pnpCurrentWanSettings];
    await pumpForm(tester);

    expect(username(tester), pnpCurrentWanSettings.pppUsername);
  });

  testWidgets(
      'keeps what the user typed when a later read lands, even after a first '
      'read that found nothing', (tester) async {
    // The first read found no WAN (it failed, or the router had none), so the
    // form opened empty and the user typed. A read after that — the one an ISP
    // save triggers — must not replace their text.
    reads = [null, pnpCurrentWanSettings];
    await pumpForm(tester);
    expect(username(tester), isEmpty);

    await tester.enterText(find.byType(EditableText).first, 'typed@isp');
    container.invalidate(troubleshootingWanPrefillProvider);
    await tester.pump();
    await tester.pump();

    expect(username(tester), 'typed@isp');
  });
}
