import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/views/widgets/auto_ipoe_log_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_section.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/usp_ipv4_section.dart';
import 'package:ui_kit_library/ui_kit.dart';
import '../../providers/usp_internet_ipoe_test.dart' show IPoEFixture;

final _theme = AppTheme.create(
    brightness: Brightness.light,
    seedColor: Colors.blue,
    designThemeBuilder: (_) => CustomDesignTheme.fromJson({'style': 'flat'}));
Widget host(IPoEFixture f) => UncontrolledProviderScope(
    container: f.container,
    child: MaterialApp(
        theme: _theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body:
            SingleChildScrollView(child: Consumer(builder: (context, ref, _) {
          final state = ref.watch(uspInternetSettingsProvider);
          return UspIpv4Section(state: state, isEditing: state.isEditing);
        })))));

void main() {
  // Run this integration suite with --dart-define=auto-ipoe=y.
  group('Auto-IPoE enabled build', _enabledBuildTests,
      skip: !BuildConfig.autoIPoEEnabled);
}

void _enabledBuildTests() {
  setUpAll(() {
    registerFallbackValue(const AutoIPoESubmission('fixture-id', reset: false));
    registerFallbackValue(const AutoIPoESettings.init());
    registerFallbackValue(const UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp));
  });
  testWidgets(
      'log follows selected type even with active IPoE and a remembered submission',
      (tester) async {
    final f = IPoEFixture(managed: true);
    addTearDown(f.dispose);
    await f.ready();
    f.container.read(autoIPoESubmissionProvider.notifier).state =
        const AutoIPoESubmission('previous-operation', reset: false);
    await tester.pumpWidget(host(f));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(AutoIPoELogView), findsOneWidget);
    for (final type in UspWanConnectionType.values
        .where((v) => v != UspWanConnectionType.ipoe)) {
      f.container
          .read(uspInternetSettingsProvider.notifier)
          .updateConnectionType(type);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(AutoIPoELogView), findsNothing, reason: '$type');
    }
    expect(f.calls, isEmpty);
  });
  testWidgets(
      'IPoE appears in existing dropdown and selection renders inline without another card',
      (tester) async {
    final f = IPoEFixture();
    addTearDown(f.dispose);
    await f.ready();
    await tester.pumpWidget(host(f));
    await tester.pumpAndSettle();
    final selector = find.byWidgetPredicate((w) =>
        w is AppDropdown<UspWanConnectionType> &&
        w.identifier == 'internet-connection-type');
    final dropdown = tester.widget<AppDropdown<UspWanConnectionType>>(selector);
    expect(
        dropdown.items,
        containsAll([
          UspWanConnectionType.dhcp,
          UspWanConnectionType.pppoe,
          UspWanConnectionType.ipoe
        ]));
    dropdown.onChanged?.call(UspWanConnectionType.ipoe);
    await tester.pumpAndSettle();
    expect(find.byType(AutoIPoESection), findsOneWidget);
    expect(find.byType(AppCard), findsOneWidget);
    expect(
        find.byWidgetPredicate((w) =>
            w is AppButton &&
            ['internet-auto-ipoe', 'auto-ipoe-apply', 'auto-ipoe-reset']
                .contains(w.identifier)),
        findsNothing);
    expect(f.calls, isEmpty);
  });
  testWidgets(
      'current managed IPoE is selected and other connection choices remain available',
      (tester) async {
    final f = IPoEFixture(managed: true);
    addTearDown(f.dispose);
    await f.ready();
    await tester.pumpWidget(host(f));
    await tester.pumpAndSettle();
    final dropdown = tester.widget<AppDropdown<UspWanConnectionType>>(
        find.byWidgetPredicate((w) =>
            w is AppDropdown<UspWanConnectionType> &&
            w.identifier == 'internet-connection-type'));
    expect(dropdown.value, UspWanConnectionType.ipoe);
    expect(dropdown.onChanged, isNotNull);
    expect(dropdown.items, contains(UspWanConnectionType.dhcp));
    expect(find.byType(AutoIPoESection), findsOneWidget);
    expect(f.calls, isEmpty);
  });
  testWidgets(
      'partial capabilities retain IPoE and show current settings read only',
      (tester) async {
    final f = IPoEFixture(managed: true);
    addTearDown(f.dispose);
    final active = f.latest;
    f.latest = AutoIPoESnapshot(
        capabilitiesAvailable: false,
        settings: active.settings,
        runtime: active.runtime);
    await f.ready();
    await tester.pumpWidget(host(f));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final dropdown = tester.widget<AppDropdown<UspWanConnectionType>>(
        find.byWidgetPredicate((w) =>
            w is AppDropdown<UspWanConnectionType> &&
            w.identifier == 'internet-connection-type'));
    expect(dropdown.value, UspWanConnectionType.ipoe);
    expect(dropdown.items, contains(UspWanConnectionType.dhcp));
    expect(
        tester.widget<AutoIPoESection>(find.byType(AutoIPoESection)).isEditing,
        false);
    expect(f.calls, isEmpty);
    await f.publish(active);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
        tester.widget<AutoIPoESection>(find.byType(AutoIPoESection)).isEditing,
        true);
  });
  testWidgets(
      'unsupported optional backend does not add IPoE to ordinary selector',
      (tester) async {
    final f = IPoEFixture();
    addTearDown(f.dispose);
    f.latest = const AutoIPoESnapshot();
    await f.ready();
    await tester.pumpWidget(host(f));
    await tester.pumpAndSettle();
    final dropdown = tester.widget<AppDropdown<UspWanConnectionType>>(
        find.byWidgetPredicate((w) =>
            w is AppDropdown<UspWanConnectionType> &&
            w.identifier == 'internet-connection-type'));
    expect(dropdown.items, isNot(contains(UspWanConnectionType.ipoe)));
    expect(find.byType(AutoIPoESection), findsNothing);
    expect(find.byType(AppCard), findsOneWidget);
  });
}
