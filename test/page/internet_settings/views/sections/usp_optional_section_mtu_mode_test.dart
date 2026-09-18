import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_settings.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_status.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/usp_optional_section.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../mocks/provider_overrides/mock_internet_settings.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({
    'style': 'flat',
  }),
);

/// [FixedInternetSettingsNotifier] with a live [updateField], so a tap on the
/// toggle actually flows back into the state the section is rebuilt from —
/// without it the fixed notifier swallows the update and the interaction tests
/// below would pass no matter what `_onMtuAutoChanged` does.
class _EditableInternetSettingsNotifier extends FixedInternetSettingsNotifier {
  _EditableInternetSettingsNotifier(InternetSettingsFeatureState initialState)
      : super(initialState);

  @override
  void updateField(
      UspInternetSettingsForm Function(UspInternetSettingsForm) updater) {
    state = state.copyWith(
      settings: state.settings.update(
        InternetSettingsSettings(form: updater(state.edited)),
      ),
    );
  }
}

InternetSettingsFeatureState _state({
  required UspWanConnectionType connectionType,
  required int mtu,
  bool mtuAuto = false,
  bool mtuModeSupported = true,
  bool isEditing = true,
}) {
  final settings = InternetSettingsSettings(
    form: UspInternetSettingsForm(
      connectionType: connectionType,
      mtu: mtu,
      mtuAuto: mtuAuto,
    ),
  );
  return InternetSettingsFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: InternetSettingsStatus(
      isLoading: false,
      isEditing: isEditing,
      mtuModeSupported: mtuModeSupported,
    ),
  );
}

/// Hosts the section the way the real view does — reading the state off the
/// provider rather than closing over a constant, so an `updateField` rebuilds it.
Future<void> _pump(
    WidgetTester tester, InternetSettingsFeatureState initial) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        uspInternetSettingsProvider.overrideWith(
          () => _EditableInternetSettingsNotifier(initial),
        ),
      ],
      child: MaterialApp(
        theme: _testTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Consumer(builder: (context, ref, _) {
              final state = ref.watch(uspInternetSettingsProvider);
              return UspOptionalSection(
                state: state,
                isEditing: state.isEditing,
              );
            }),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the Auto MTU toggle when the firmware supports the mode',
      (tester) async {
    await _pump(
        tester,
        _state(
          connectionType: UspWanConnectionType.dhcp,
          mtu: 1500,
        ));

    expect(find.byType(AppSwitch), findsOneWidget);
    expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isFalse);
    // Manual mode still offers the number.
    expect(find.byType(AppTextFormField), findsOneWidget);
  });

  testWidgets('hides the toggle on firmware without X_LINKSYS_MTUMode',
      (tester) async {
    await _pump(
        tester,
        _state(
          connectionType: UspWanConnectionType.dhcp,
          mtu: 1500,
          mtuModeSupported: false,
        ));

    // No mode to read or write, so the pre-vendor-extension UI: field only.
    expect(find.byType(AppSwitch), findsNothing);
    expect(find.byType(AppTextFormField), findsOneWidget);
  });

  testWidgets('hides the MTU field while in auto mode', (tester) async {
    await _pump(
        tester,
        _state(
          connectionType: UspWanConnectionType.dhcp,
          mtu: 1500,
          mtuAuto: true,
        ));

    expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isTrue);
    expect(find.byType(AppTextFormField), findsNothing);
  });

  testWidgets('turning the toggle on drops the MTU field', (tester) async {
    await _pump(
        tester,
        _state(
          connectionType: UspWanConnectionType.dhcp,
          mtu: 1500,
        ));
    expect(find.byType(AppTextFormField), findsOneWidget);

    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();

    expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isTrue);
    expect(find.byType(AppTextFormField), findsNothing);
  });

  testWidgets('turning the toggle off seeds the field with the effective MTU',
      (tester) async {
    // PPPoE reporting 1500 in auto mode: legal for the device to pick, but above
    // PPPoE's 1492 manual ceiling, so leaving auto has to clamp — otherwise the
    // user lands on an invalid form they never typed into.
    await _pump(
        tester,
        _state(
          connectionType: UspWanConnectionType.pppoe,
          mtu: 1500,
          mtuAuto: true,
        ));

    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();

    expect(tester.widget<AppSwitch>(find.byType(AppSwitch)).value, isFalse);
    expect(find.byType(AppTextFormField), findsOneWidget);
    expect(find.text('1492'), findsOneWidget);
  });

  testWidgets('read-only auto mode reports the mode, not the number',
      (tester) async {
    await _pump(
        tester,
        _state(
          connectionType: UspWanConnectionType.dhcp,
          mtu: 1400,
          mtuAuto: true,
          isEditing: false,
        ));

    // The row reads "Auto" on its own, matching the bridge row: the number
    // belongs to the device, so showing it here would read as a setting.
    expect(find.text('Auto'), findsOneWidget);
    expect(find.textContaining('1400'), findsNothing);
    expect(find.byType(AppSwitch), findsNothing);
  });
}
