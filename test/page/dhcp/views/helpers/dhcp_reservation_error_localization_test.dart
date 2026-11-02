// Untagged (not `ui`) so `run_tests.sh`, and with it CI's Unit Tests job, runs
// this suite: it is AC3's message mapping (linksys/PrivacyGUI#1698).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/models/usp_operation_result.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/dhcp/views/helpers/dhcp_reservation_error_localization.dart';

/// A refusal FW named reads as that check, not the generic text
/// (linksys/PrivacyGUI#1698).
void main() {
  Future<String> localize(WidgetTester tester, Object error) async {
    late String out;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        out = localizeDhcpReservationSaveError(context, error);
        return const SizedBox();
      }),
    ));
    return out;
  }

  late AppLocalizations l;
  setUp(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  for (final (name, expected) in [
    (DhcpReservationRefusalNames.invalidIp, 'invalidIpAddress'),
    (DhcpReservationRefusalNames.invalidMac, 'invalidMacAddressFormat'),
    (DhcpReservationRefusalNames.ipConflict, 'duplicateIpAddress'),
    (DhcpReservationRefusalNames.invalidName, 'reservationNameInvalid'),
  ]) {
    testWidgets('"$name" reads as that check', (tester) async {
      final text = await localize(
          tester, InvalidInputError(field: name, code: 7012, detail: name));
      expect(
        text,
        switch (expected) {
          'invalidIpAddress' => l.invalidIpAddress,
          'invalidMacAddressFormat' => l.invalidMacAddressFormat,
          'duplicateIpAddress' => l.duplicateIpAddress,
          _ => l.reservationNameInvalid,
        },
      );
      expect(text, isNot(l.errorInvalidInput));
    });
  }

  testWidgets('any other error reads as before', (tester) async {
    const batch = UspCompleteFailureError(summary: 's', failures: [
      UspErrorDetail(requestedPath: 'p', errorCode: 7012, errorMessage: 'x'),
    ]);
    expect(await localize(tester, batch), l.errorUnexpected);
    expect(
        await localize(tester, const InvalidInputError()), l.errorInvalidInput);
  });
}
