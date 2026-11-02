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
  });
}
