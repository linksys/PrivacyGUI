import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/firmware_update/views/dialogs/firmware_update_recovery_dialog.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

import '../../golden_test/golden_framework/mocks/mock_firmware_update.dart';
import '../../golden_test/golden_framework/overlay_host.dart';
import '../../mocks/provider_overrides/mock_common.dart';

/// The firmware recovery dialog's countdown follows the test's clock (#905).
///
/// It ticks once a second and reads the elapsed time from `clock.now()`. Read
/// from `DateTime.now()` instead, as it used to be, the countdown follows the
/// machine's wall clock while the test advances fake time, so the text depends
/// on how fast the machine runs the test. That made every golden of this dialog
/// one extra pump away from flaking between "4m 00s" and "3m 59s".
void main() {
  late AppLocalizations loc;

  setUpAll(() async {
    loc = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...commonOverrides(), ...recoveryDialogOverrides()],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
          home: const OverlayHost(),
        ),
      ),
    );
    final host = overlayHostOf(tester);
    showFirmwareUpdateRecoveryDialog(host.context, host.ref);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('counts down by the fake time the test advances', (tester) async {
    await open(tester);
    expect(find.text(loc.estimatedTimeRemaining('4m 00s')), findsOneWidget);

    // 300ms already elapsed in `open`; this takes it to 5.3s, past five ticks.
    await tester.pump(const Duration(seconds: 5));

    expect(find.text(loc.estimatedTimeRemaining('3m 55s')), findsOneWidget);

    // Popped so the dialog's ticker is cancelled before the test ends.
    Navigator.of(tester.element(find.byType(OverlayHost)), rootNavigator: true)
        .pop();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
