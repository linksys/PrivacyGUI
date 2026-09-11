import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/views/isp_settings/pnp_ipoe_view.dart';

void main() {
  test('active PnP reconciliation hides the IPoE editor', () {
    expect(
      shouldShowPnpIPoEEditor(isRecovering: true),
      isFalse,
    );
  });

  test('retry and edit states restore the populated IPoE editor', () {
    expect(
      shouldShowPnpIPoEEditor(isRecovering: false),
      isTrue,
    );
  });

  test('new backend connectivity confirmation skips the duplicate probe', () {
    final status = const AutoIPoEStatus.init().copyWith(
      progressPhase: AutoIPoEProgressPhase.completed,
      connectivityVerified: true,
    );

    expect(shouldRunLegacyPnpIPoEConnectivityProbe(status), isFalse);
  });

  test('legacy status keeps the LinksysNow connectivity fallback', () {
    expect(
      shouldRunLegacyPnpIPoEConnectivityProbe(
        const AutoIPoEStatus.init(),
      ),
      isTrue,
    );
  });

  test('supported result contract never falls back to a duplicate ping', () {
    final awaitingResult = const AutoIPoEStatus.init().copyWith(
      terminalResultSupported: true,
    );
    final completed = const AutoIPoEStatus.init().copyWith(
      terminalResultSupported: true,
      terminalResult: const AutoIPoETerminalResult(
        phase: AutoIPoETerminalPhase.completed,
        operation: AutoIPoETerminalResult.applyOperation,
        exitCode: 0,
        reason: 'Completed',
        connectivityVerified: true,
      ),
    );

    expect(shouldRunLegacyPnpIPoEConnectivityProbe(awaitingResult), isFalse);
    expect(shouldRunLegacyPnpIPoEConnectivityProbe(completed), isFalse);
  });
}
