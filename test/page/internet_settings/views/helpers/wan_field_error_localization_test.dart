import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/views/helpers/wan_field_error_localization.dart';

/// Runs [body] with an English [BuildContext].
Future<void> _withContext(
    WidgetTester tester, void Function(BuildContext context) body) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: (context) {
      body(context);
      return const SizedBox();
    }),
  ));
}

void main() {
  group('localizeWanSaveError', () {
    for (final (name, message) in [
      (WanRefusalNames.invalidServer, 'Invalid IP address'),
      (WanRefusalNames.invalidGateway, 'Invalid gateway IP address'),
      (WanRefusalNames.invalidPrimaryDns, 'Invalid DNS'),
      (WanRefusalNames.invalidPrefixLength, 'Invalid subnet mask'),
    ]) {
      testWidgets('a refusal named "$name" reads as its check', (tester) async {
        await _withContext(tester, (context) {
          expect(
              localizeWanSaveError(
                  context, InvalidInputError(field: name, code: 7012)),
              message);
        });
      });
    }

    testWidgets('any other error reads as the generic message', (tester) async {
      await _withContext(tester, (context) {
        expect(localizeWanSaveError(context, const InvalidInputError()),
            'The value entered is not valid. Please check and try again.');
        expect(localizeWanSaveError(context, const NetworkError()),
            isNot(contains('Invalid')));
      });
    });

    // A save the router applied in part (issue #1711): why it failed, then, on
    // a line of its own, that part of it landed.
    group('for a save applied in part', () {
      const appliedLine = 'Some of your changes were already applied. '
          'Check the settings before you save again.';

      testWidgets('names the refused check, then says part of it landed',
          (tester) async {
        await _withContext(tester, (context) {
          expect(
            localizeWanSaveError(
                context,
                const SavePartlyAppliedError(InvalidInputError(
                    field: WanRefusalNames.invalidServer, code: 7012))),
            'Invalid IP address\n$appliedLine',
          );
        });
      });

      testWidgets(
          'reads any other cause as its own message, then the same line',
          (tester) async {
        await _withContext(tester, (context) {
          expect(
            localizeWanSaveError(
                context, const SavePartlyAppliedError(NetworkError())),
            'Network error. Please check your connection and try again.\n'
            '$appliedLine',
          );
        });
      });
    });
  });
}
