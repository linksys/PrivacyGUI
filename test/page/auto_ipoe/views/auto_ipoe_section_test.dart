import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_issue.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_section.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  for (final locale in ['en', 'ja']) {
    testWidgets('all supported modes render without overflow on $locale phone',
        (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final mode
          in AutoIPoEMode.values.where((m) => m != AutoIPoEMode.disabled)) {
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.create(brightness: Brightness.light),
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
              body: SingleChildScrollView(
                  child: Padding(
            padding: const EdgeInsets.all(16),
            child: AutoIPoESection(
              settings: AutoIPoESettings(isEnabled: true, selectedMode: mode),
              status: const AutoIPoEStatus.init(),
              capabilities: AutoIPoECapabilities(
                  isSupported: true,
                  supportedModes: AutoIPoEMode.values,
                  blocksManualIPv6Configuration: true,
                  requiresResetOnExit: true),
              isEditing: true,
              onChanged: (_) {},
            ),
          ))),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(AppDropdown<AutoIPoEMode>), findsOneWidget);
        expect(tester.takeException(), isNull, reason: mode.value);
      }
    });
  }

  for (final form in _providerForms) {
    testWidgets('${form.name} collects its provider-specific settings',
        (tester) async {
      final draft = await _pumpSection(
        tester,
        AutoIPoESettings(isEnabled: true, selectedMode: form.mode),
        highlightedFieldGroup: form.fieldGroup,
      );
      expect(
        tester
            .widgetList<AppTextFormField>(find.byType(AppTextFormField))
            .map((field) => field.label),
        orderedEquals(form.fields.map((field) => field.label)),
      );
      final highlightedGroup = find.byKey(
        ValueKey('autoIpoe${form.mode.value}FieldGroup'),
      );
      expect(
        find.descendant(
          of: highlightedGroup,
          matching: find.text('Review the settings in this section.'),
        ),
        findsOneWidget,
      );
      for (final field in form.fields) {
        expect(tester.widget<EditableText>(_input(field.label)).obscureText,
            field.obscure);
        await _enter(tester, field.label, field.value);
      }
      expect(draft.value.toMap()[form.profileKey], form.profile());
      expect(draft.value.selectedMode, form.mode);
      expect(find.text('Review the settings in this section.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${form.name} summary shows settings without exposing secrets',
        (tester) async {
      final draft = await _pumpSection(
        tester,
        AutoIPoESettings(isEnabled: true, selectedMode: form.mode),
        isEditing: false,
      );
      expect(find.byType(AppTextFormField), findsNothing);
      expect(find.byType(AppDropdown<AutoIPoEMode>), findsNothing);
      for (final field in form.fields) {
        expect(_summaryRows(tester)[field.label], '-');
      }

      draft.value = form.settings(stored: true);
      await tester.pump();
      expect(_summaryRows(tester), {
        'IPoE Mode': form.name,
        'Apply State': 'Idle',
        for (final field in form.fields)
          field.label: field.secret ? 'Configured' : field.value,
      });
      for (final field in form.fields.where((field) => field.secret)) {
        expect(find.text(field.value), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });

    if (form.fields.any((field) => field.secret)) {
      testWidgets('${form.name} preserves stored credentials when edits clear',
          (tester) async {
        final storedProfile = form.profile(stored: true);
        for (final field in form.fields.where((field) => field.secret)) {
          storedProfile[field.property] = {'hasStoredValue': true};
        }
        final initial = AutoIPoESettings.fromMap({
          'isEnabled': true,
          'selectedMode': form.mode.value,
          form.profileKey: storedProfile,
        });
        final draft = await _pumpSection(tester, initial);
        for (final field in form.fields.where((field) => field.secret)) {
          expect(
              tester.widget<EditableText>(_input(field.label)).controller.text,
              isEmpty);
          final inputWidget = tester.widget<AppTextField>(find.descendant(
            of: _field(field.label),
            matching: find.byType(AppTextField),
          ));
          expect(inputWidget.hintText, 'Stored on router');
          await _enter(tester, field.label, field.value);
          expect(draft.value.toMap()[form.profileKey][field.property], {
            'hasStoredValue': true,
            'value': field.value,
          });
          await _enter(tester, field.label, '');
          expect(draft.value.toMap()[form.profileKey][field.property], {
            'hasStoredValue': true,
          });
        }
        expect(draft.value, initial);
      });
    }
  }

  testWidgets('BIGLOBE credentials enforce allowed characters and length',
      (tester) async {
    final draft = await _pumpSection(
        tester,
        const AutoIPoESettings(
          isEnabled: true,
          selectedMode: AutoIPoEMode.biglobeStaticIp,
        ));
    for (final label in ['User ID', 'Password']) {
      await _enter(tester, label,
          'AB-user_01.${String.fromCharCodes([0x65e5, 0x672c])} !@#');
      expect(tester.widget<EditableText>(_input(label)).controller.text,
          'AB-user_01');
      await _enter(tester, label, List.filled(40, 'Z').join());
      expect(tester.widget<EditableText>(_input(label)).controller.text,
          List.filled(32, 'Z').join());
    }
    expect(draft.value.biglobeStaticIpSettings.userId.value,
        List.filled(32, 'Z').join());
    expect(draft.value.biglobeStaticIpSettings.userPassword.value,
        List.filled(32, 'Z').join());
  });

  for (final mode in [
    AutoIPoEMode.auto,
    AutoIPoEMode.ocnVirtualConnectStaticIp,
    AutoIPoEMode.ocxHikariV6ixStaticIp,
  ]) {
    testWidgets('${mode.value} requires no additional provider fields',
        (tester) async {
      final settings = AutoIPoESettings(
        isEnabled: true,
        selectedMode: mode,
        ocnVirtualConnectStaticIpSettings:
            const OCNVirtualConnectStaticIPSettings(
          ruleApiCode:
              AutoIPoESecret(value: 'old-rule-code', hasStoredValue: true),
          updateUserId: 'old-update-user',
          updatePassword: AutoIPoESecret(
              value: 'old-update-password', hasStoredValue: true),
        ),
      );
      final draft = await _pumpSection(tester, settings);
      expect(find.byType(AppTextFormField), findsNothing);
      expect(find.text('No additional parameters required'), findsOneWidget);
      expect(find.text('old-rule-code'), findsNothing);
      expect(find.text('old-update-user'), findsNothing);
      expect(find.text('old-update-password'), findsNothing);
      expect(draft.value, settings);

      await _pumpSection(tester, settings, showParameterHints: false);
      expect(find.byType(AppTextFormField), findsNothing);
      expect(find.text('No additional parameters required'), findsNothing);
      expect(find.byType(AppDropdown<AutoIPoEMode>), findsOneWidget);

      await _pumpSection(tester, settings, isEditing: false);
      expect(_summaryRows(tester)['Details'], 'No additional parameters');
      expect(find.byType(AppTextFormField), findsNothing);
      expect(find.text('old-rule-code'), findsNothing);
      expect(find.text('old-update-user'), findsNothing);
      expect(find.text('old-update-password'), findsNothing);
    });
  }

  testWidgets('changing modes enables IPoE and retains each provider draft',
      (tester) async {
    final draft = await _pumpSection(
      tester,
      const AutoIPoESettings.init(),
      supportedModes: const [
        AutoIPoEMode.disabled,
        AutoIPoEMode.auto,
        AutoIPoEMode.biglobeStaticIp,
        AutoIPoEMode.standardIpip,
      ],
    );
    final dropdown = tester.widget<AppDropdown<AutoIPoEMode>>(
        find.byType(AppDropdown<AutoIPoEMode>));
    expect(dropdown.value, AutoIPoEMode.auto);
    expect(dropdown.items, isNot(contains(AutoIPoEMode.disabled)));
    await _selectMode(tester, 'BIGLOBE IPIP (HB46PP)');
    await _enter(tester, 'User ID', 'Saved_user-01');
    await _selectMode(tester, 'Standard IPIP');
    await _enter(tester, 'IPv6 Remote', '2001:db8::50');
    await _selectMode(tester, 'BIGLOBE IPIP (HB46PP)');
    expect(tester.widget<EditableText>(_input('User ID')).controller.text,
        'Saved_user-01');
    expect(draft.value.isEnabled, isTrue);
    expect(draft.value.selectedMode, AutoIPoEMode.biglobeStaticIp);
    expect(draft.value.standardIpipSettings.ipv6Remote, '2001:db8::50');
  });
}

Finder _field(String label) => find.byWidgetPredicate(
    (widget) => widget is AppTextFormField && widget.label == label);

Finder _input(String label) =>
    find.descendant(of: _field(label), matching: find.byType(EditableText));

Future<void> _enter(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(_field(label));
  await tester.enterText(_input(label), value);
  await tester.pump();
}

Future<void> _selectMode(WidgetTester tester, String label) async {
  final dropdown = find.byType(AppDropdown<AutoIPoEMode>);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.text(label).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Map<String, String> _summaryRows(WidgetTester tester) => {
      for (final row in tester.widgetList<UspInfoRow>(find.byType(UspInfoRow)))
        row.label: row.value,
    };

Future<ValueNotifier<AutoIPoESettings>> _pumpSection(
  WidgetTester tester,
  AutoIPoESettings settings, {
  bool isEditing = true,
  bool showParameterHints = true,
  AutoIPoEFieldGroup highlightedFieldGroup = AutoIPoEFieldGroup.none,
  List<AutoIPoEMode> supportedModes = AutoIPoEMode.values,
}) async {
  final draft = ValueNotifier(settings);
  addTearDown(draft.dispose);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.create(brightness: Brightness.light),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<AutoIPoESettings>(
            valueListenable: draft,
            builder: (context, value, child) => AutoIPoESection(
              settings: value,
              status: const AutoIPoEStatus.init(),
              capabilities: AutoIPoECapabilities(
                isSupported: true,
                supportedModes: supportedModes,
                blocksManualIPv6Configuration: true,
                requiresResetOnExit: true,
              ),
              isEditing: isEditing,
              showParameterHints: showParameterHints,
              highlightedFieldGroup: highlightedFieldGroup,
              onChanged: (value) => draft.value = value,
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return draft;
}

class _ProviderField {
  const _ProviderField(this.label, this.property, this.value,
      {this.secret = false, this.obscure = false});

  final String label;
  final String property;
  final String value;
  final bool secret;
  final bool obscure;
}

class _ProviderForm {
  const _ProviderForm(
      this.name, this.mode, this.profileKey, this.fieldGroup, this.fields);

  final String name;
  final AutoIPoEMode mode;
  final String profileKey;
  final AutoIPoEFieldGroup fieldGroup;
  final List<_ProviderField> fields;

  Map<String, dynamic> profile({bool stored = false}) => {
        for (final field in fields)
          field.property: field.secret
              ? {'hasStoredValue': stored, 'value': field.value}
              : field.value,
      };

  AutoIPoESettings settings({bool stored = false}) => AutoIPoESettings.fromMap({
        'isEnabled': true,
        'selectedMode': mode.value,
        profileKey: profile(stored: stored),
      });
}

const _providerForms = [
  _ProviderForm('BIGLOBE IPIP (HB46PP)', AutoIPoEMode.biglobeStaticIp,
      'biglobeStaticIpSettings', AutoIPoEFieldGroup.biglobeStaticIp, [
    _ProviderField('User ID', 'userId', 'BIG_user-01', secret: true),
    _ProviderField('Password', 'userPassword', 'BIG_pass-02',
        secret: true, obscure: true),
  ]),
  _ProviderForm('Standard IPIP', AutoIPoEMode.standardIpip,
      'standardIpipSettings', AutoIPoEFieldGroup.standardIpip, [
    _ProviderField('IPv6 Remote', 'ipv6Remote', '2001:db8::10'),
    _ProviderField('Interface ID', 'ipv6InterfaceId', '::10'),
    _ProviderField('IPv4 Address', 'ipv4Address', '192.0.2.10'),
  ]),
  _ProviderForm('v6 Plus Static IP', AutoIPoEMode.v6PlusStaticIp,
      'v6PlusStaticIpSettings', AutoIPoEFieldGroup.v6PlusStaticIp, [
    _ProviderField('BR IPv6 Address', 'ipv6Remote', '2001:db8::20'),
    _ProviderField('Interface ID', 'ipv6InterfaceId', '::20'),
    _ProviderField('IPv4 Global Address', 'ipv4Address', '192.0.2.20'),
    _ProviderField('User ID', 'userId', 'plus-user'),
    _ProviderField('Password', 'userPassword', 'plus-password',
        secret: true, obscure: true),
  ]),
  _ProviderForm('transix Static IP', AutoIPoEMode.transixStaticIp,
      'transixStaticIpSettings', AutoIPoEFieldGroup.transixStaticIp, [
    _ProviderField('IPv6 Tunnel BR', 'ipv6Remote', '2001:db8::30'),
    _ProviderField('Interface ID', 'ipv6InterfaceId', '::30'),
    _ProviderField('IPv4 Global Address', 'ipv4Address', '192.0.2.30'),
    _ProviderField('Update User ID', 'updateUserId', 'transix-user'),
    _ProviderField('Update Password', 'updatePassword', 'transix-password',
        secret: true, obscure: true),
  ]),
  _ProviderForm('Asahi Net Static IP', AutoIPoEMode.asahiNetStaticIp,
      'asahiNetStaticIpSettings', AutoIPoEFieldGroup.asahiNetStaticIp, [
    _ProviderField('Authentication Key', 'authenticationKey', 'asahi-key'),
    _ProviderField(
        'Authentication Password', 'authenticationPassword', 'asahi-password',
        secret: true, obscure: true),
  ]),
  _ProviderForm('Xpass Static IP', AutoIPoEMode.xpassStaticIp,
      'xpassStaticIpSettings', AutoIPoEFieldGroup.xpassStaticIp, [
    _ProviderField('DDNS FQDN', 'fqdn', 'router.example.test'),
    _ProviderField('DDNS ID', 'ddnsId', 'ddns-user'),
    _ProviderField('DDNS Password', 'ddnsPassword', 'ddns-password',
        secret: true, obscure: true),
    _ProviderField('Basic Auth ID', 'basicAuthId', 'basic-user'),
    _ProviderField('Basic Auth Password', 'basicAuthPassword', 'basic-password',
        secret: true, obscure: true),
    _ProviderField('DDNS Update URL', 'ddnsUpdateUrl',
        'https://update.example.test/router'),
    _ProviderField('Tunnel Destination', 'ipv6Remote', '2001:db8::40'),
    _ProviderField('IPv4 Global Address', 'ipv4Address', '192.0.2.40'),
  ]),
];
