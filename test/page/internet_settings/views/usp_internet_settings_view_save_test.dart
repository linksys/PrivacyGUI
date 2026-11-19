import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/views/usp_internet_settings_view.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  group('showWanSaveError', () {
    // A save the router applied in part (issue #1711) reads through the WAN
    // localizer, so the field the firmware refused is still named; a view
    // that sent it the generic way would read "The value entered is not valid".
    testWidgets(
        'a save applied in part names the refused check, '
        'then says part of it landed', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        })),
      ));
      final danger = Theme.of(ctx).extension<AppColorScheme>()?.semanticDanger;

      showWanSaveError(
          ctx,
          const SavePartlyAppliedError(InvalidInputError(
              field: WanRefusalNames.invalidServer, code: 7012)));
      await tester.pump();

      expect(
          find.text('Invalid IP address\n'
              'Some of your changes were already applied. '
              'Check the settings before you save again.'),
          findsOneWidget);
      expect(
          tester
              .widget<AppSurface>(find.byType(AppSurface))
              .style
              ?.backgroundColor,
          danger);
    });
  });

  group('shouldRedirectToBridge', () {
    test('true when entering bridge with a hostname', () {
      expect(
        shouldRedirectToBridge(
          previousType: UspWanConnectionType.dhcp,
          newType: UspWanConnectionType.bridge,
          hostName: 'Community00080',
        ),
        isTrue,
      );
    });

    test('false when already in bridge (no transition)', () {
      expect(
        shouldRedirectToBridge(
          previousType: UspWanConnectionType.bridge,
          newType: UspWanConnectionType.bridge,
          hostName: 'Community00080',
        ),
        isFalse,
      );
    });

    test('false when leaving bridge', () {
      expect(
        shouldRedirectToBridge(
          previousType: UspWanConnectionType.bridge,
          newType: UspWanConnectionType.dhcp,
          hostName: 'Community00080',
        ),
        isFalse,
      );
    });

    test('false when entering bridge but hostname is empty', () {
      expect(
        shouldRedirectToBridge(
          previousType: UspWanConnectionType.dhcp,
          newType: UspWanConnectionType.bridge,
          hostName: '',
        ),
        isFalse,
      );
    });
  });
}
