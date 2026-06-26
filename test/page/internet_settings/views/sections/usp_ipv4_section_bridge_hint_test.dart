import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_settings.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_status.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/usp_ipv4_section.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:ui_kit_library/ui_kit.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({
    'style': 'flat',
  }),
);

InternetSettingsFeatureState _bridgeState({
  required bool editing,
  required String hostName,
}) {
  const form = UspInternetSettingsForm(
    connectionType: UspWanConnectionType.bridge,
  );
  return InternetSettingsFeatureState(
    settings: Preservable(
      original: const InternetSettingsSettings(form: form),
      current: const InternetSettingsSettings(form: form),
    ),
    status: InternetSettingsStatus(
      isLoading: false,
      isEditing: editing,
      readOnlyInfo: InternetSettingsReadOnlyInfo(hostName: hostName),
    ),
  );
}

Widget _host(InternetSettingsFeatureState state, bool editing) {
  return ProviderScope(
    child: MaterialApp(
      theme: _testTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: UspIpv4Section(state: state, isEditing: editing),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows bold .local hint when editing bridge with a hostname',
      (tester) async {
    final state = _bridgeState(editing: true, hostName: 'Community00080');
    await tester.pumpWidget(_host(state, true));
    await tester.pumpAndSettle();

    expect(find.textContaining('https://Community00080.local'), findsOneWidget);

    // Assert the hint is rendered bold. A textContaining check alone would not
    // catch a regression back to the non-bold AppText.bodyMedium factory.
    expect(
      find.byWidgetPredicate((w) =>
          w is AppText &&
          w.data.contains('https://Community00080.local') &&
          w.fontWeight == FontWeight.bold),
      findsOneWidget,
    );
  });

  testWidgets('hides the hint when not editing', (tester) async {
    final state = _bridgeState(editing: false, hostName: 'Community00080');
    await tester.pumpWidget(_host(state, false));
    await tester.pumpAndSettle();

    expect(find.textContaining('https://Community00080.local'), findsNothing);
  });

  testWidgets('hides the hint when hostname is empty', (tester) async {
    final state = _bridgeState(editing: true, hostName: '');
    await tester.pumpWidget(_host(state, true));
    await tester.pumpAndSettle();

    expect(find.textContaining('.local'), findsNothing);
  });
}
