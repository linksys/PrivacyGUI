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
import 'package:privacy_gui/page/internet_settings/views/sections/usp_ipv4_section.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../mocks/provider_overrides/mock_internet_settings.dart';
import '../../../../mocks/test_data/scenes/internet_settings_scene_data.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// PPTP over DHCP on Keep Alive: the shared scene with the underlay off.
final _pptp = pptpDhcpUnderlayForm;

InternetSettingsFeatureState _state(UspInternetSettingsForm form,
        {bool editing = true}) =>
    InternetSettingsFeatureState(
      settings: Preservable(
        original: InternetSettingsSettings(form: form),
        current: InternetSettingsSettings(form: form),
      ),
      status: InternetSettingsStatus(isLoading: false, isEditing: editing),
    );

Future<void> _pump(WidgetTester tester, UspInternetSettingsForm form,
    {bool editing = true}) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: _testTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: UspIpv4Section(
              state: _state(form, editing: editing), isEditing: editing),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// [FixedInternetSettingsNotifier] with a live [updateField], so a tap on a
/// switch flows back into the state the section is rebuilt from.
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

/// Hosts the section the way the real view does, reading its state off the
/// provider, so an edit rebuilds it.
Future<ProviderContainer> _pumpLive(
    WidgetTester tester, UspInternetSettingsForm form) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      uspInternetSettingsProvider
          .overrideWith(() => _EditableInternetSettingsNotifier(_state(form))),
    ],
    child: MaterialApp(
      theme: _testTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Consumer(builder: (context, ref, _) {
            final state = ref.watch(uspInternetSettingsProvider);
            return UspIpv4Section(state: state, isEditing: state.isEditing);
          }),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(UspIpv4Section)));
}

Finder _field(String label) =>
    find.byWidgetPredicate((w) => w is AppTextFormField && w.label == label);

Finder get _vlanSwitch => find.descendant(
      of: find
          .ancestor(of: find.text('VLAN Tagging'), matching: find.byType(Row))
          .first,
      matching: find.byType(AppSwitch),
    );

Future<void> _tapVlanSwitch(WidgetTester tester) async {
  await tester.ensureVisible(_vlanSwitch);
  await tester.tap(_vlanSwitch);
  await tester.pumpAndSettle();
}

String? _errorOf(WidgetTester tester, String label) =>
    tester.widget<AppTextFormField>(_field(label)).externalErrorText;

void main() {
  group('UspIpv4Section — PPTP', () {
    testWidgets('offers the static underlay switch', (tester) async {
      await _pump(tester, _pptp);
      expect(find.text('Static IP'), findsOneWidget);
      expect(_field('IP address'), findsNothing);
    });

    testWidgets('a static underlay shows its fields with their checks',
        (tester) async {
      await _pump(
          tester,
          _pptp.copyWith(
            underlayStatic: true,
            underlayIpAddress: '198.51.100.10',
            underlaySubnetMask: '255.255.255.0',
            underlayGateway: '10.0.0.1',
            underlayDns1: '8.8.8.8',
          ));
      expect(_errorOf(tester, 'IP address'), isNull);
      expect(_errorOf(tester, 'Default Gateway'), 'Invalid gateway IP address');
    });

    testWidgets('a hostname server is refused', (tester) async {
      await _pump(tester, _pptp.copyWith(serverAddress: 'vpn.example.com'));
      expect(_errorOf(tester, 'PPTP Server'), 'Invalid IP address');
    });

    testWidgets('a reserved server is refused', (tester) async {
      await _pump(tester, _pptp.copyWith(serverAddress: '127.0.0.1'));
      expect(_errorOf(tester, 'PPTP Server'),
          'Reserved IP address is not allowed');
    });
  });

  group('UspIpv4Section — L2TP', () {
    testWidgets('offers no underlay, as 1.0', (tester) async {
      await _pump(
          tester, _pptp.copyWith(connectionType: UspWanConnectionType.l2tp));
      expect(find.text('Static IP'), findsNothing);
    });
  });

  group('UspIpv4Section — connection mode', () {
    testWidgets('Keep Alive edits the interval and checks 20 to 180',
        (tester) async {
      await _pump(tester, _pptp.copyWith(lcpEchoInterval: 10));
      expect(_errorOf(tester, 'LCP Echo Interval (seconds)'),
          'Must be between 20 and 180');
    });

    testWidgets('On Demand takes the idle time in minutes, 1 to 9999',
        (tester) async {
      await _pump(
          tester,
          _pptp.copyWith(
              connectionTrigger: 'OnDemand', idleDisconnectTime: 10000));
      expect(_errorOf(tester, 'Max idle time (minutes)'),
          'Must be between 1 and 9999');
    });

    testWidgets('PPPoE gets the same Keep Alive field', (tester) async {
      await _pump(
          tester,
          _pptp.copyWith(
              connectionType: UspWanConnectionType.pppoe,
              lcpEchoInterval: 200));
      expect(_errorOf(tester, 'LCP Echo Interval (seconds)'),
          'Must be between 20 and 180');
    });
  });

  testWidgets('Static WAN shows each check FW 036 would refuse',
      (tester) async {
    await _pump(
        tester,
        const UspInternetSettingsForm(
          connectionType: UspWanConnectionType.staticIp,
          staticIpAddress: '198.51.100.10',
          subnetMask: '255.255.255.0',
          defaultGateway: '198.51.101.1',
          dnsServer1: '8.8.8.8',
          dnsServer2: '224.0.0.1',
          mtu: 1500,
        ));
    expect(_errorOf(tester, 'IP address'), isNull);
    expect(_errorOf(tester, 'Default Gateway'), 'Invalid gateway IP address');
    expect(_errorOf(tester, 'DNS 2 (optional)'),
        'Reserved IP address is not allowed');
  });

  // #1072: an ID typed while VLAN was on must not be saved once it is off.
  group('UspIpv4Section — VLAN switch (#1072)', () {
    for (final type in [
      UspWanConnectionType.pppoe,
      UspWanConnectionType.pptp
    ]) {
      testWidgets('${type.name}: turning VLAN off puts the router ID back',
          (tester) async {
        final container = await _pumpLive(
            tester,
            _pptp.copyWith(
                connectionType: type, vlanEnabled: false, vlanId: 1));

        await _tapVlanSwitch(tester);
        await tester.enterText(
            find.descendant(
                of: _field('VLAN ID (optional)'),
                matching: find.byType(EditableText)),
            '200');
        await tester.pumpAndSettle();
        expect(container.read(uspInternetSettingsProvider).edited.vlanId, 200);
        await _tapVlanSwitch(tester);

        final state = container.read(uspInternetSettingsProvider);
        expect(state.edited.vlanEnabled, isFalse);
        expect(state.edited.vlanId, 1);
        expect(state.isDirty, isFalse);
      });
    }
  });

  testWidgets('a user name over 255 characters is refused', (tester) async {
    await _pump(tester, _pptp.copyWith(pppUsername: 'a' * 256));
    expect(_errorOf(tester, 'Username'), 'At most 255 characters');
  });

  testWidgets('read-only, a static underlay is listed with the tunnel',
      (tester) async {
    await _pump(
        tester,
        _pptp.copyWith(
          underlayStatic: true,
          underlayIpAddress: '198.51.100.10',
          underlaySubnetMask: '255.255.255.0',
          underlayGateway: '198.51.100.1',
          underlayDns1: '8.8.8.8',
        ),
        editing: false);
    expect(find.text('198.51.100.10'), findsOneWidget);
    expect(find.text('198.51.100.1'), findsOneWidget);
  });
}
