import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/internet_settings_mac_clone_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/internet_settings_state_data.dart';
import '../../../../../mocks/internet_settings_notifier_mocks.dart';

Future<void> main() async {
  late InternetSettingsNotifier mockInternetSettingsNotifier;

  setUp(() {
    mockInternetSettingsNotifier = MockInternetSettingsNotifier();
  });

  testLocalizations('MAC address clone - disable', (tester, locale) async {
    when(mockInternetSettingsNotifier.build())
        .thenReturn(InternetSettingsState.fromJson(internetSettingsStateData));

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        internetSettingsProvider
            .overrideWith(() => mockInternetSettingsNotifier),
      ],
      locale: locale,
      child: const MACCloneView(),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('MAC address clone - enable', (tester, locale) async {
    when(mockInternetSettingsNotifier.build()).thenReturn(
        InternetSettingsState.fromJson(internetSettingsStateData)
            .copyWith(macClone: true));

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        internetSettingsProvider
            .overrideWith(() => mockInternetSettingsNotifier),
      ],
      locale: locale,
      child: const MACCloneView(),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('MAC address clone - input mac address',
      (tester, locale) async {
    when(mockInternetSettingsNotifier.build()).thenReturn(
        InternetSettingsState.fromJson(internetSettingsStateData)
            .copyWith(macClone: true, macCloneAddress: 'A4:83:E7:11:8A:19'));

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        internetSettingsProvider
            .overrideWith(() => mockInternetSettingsNotifier),
      ],
      locale: locale,
      child: const MACCloneView(),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('MAC address clone - enable save button',
      (tester, locale) async {
    when(mockInternetSettingsNotifier.build()).thenReturn(
        InternetSettingsState.fromJson(internetSettingsStateData)
            .copyWith(macCloneAddress: 'A4:83:E7:11:8A:19'));

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        internetSettingsProvider
            .overrideWith(() => mockInternetSettingsNotifier),
      ],
      locale: locale,
      child: const MACCloneView(),
    );
    await tester.pumpWidget(widget);

    final appSwitch = find.byType(AppSwitch);
    await tester.tap(appSwitch);
    await tester.pumpAndSettle();
  });

  testLocalizations('MAC address clone - save success', (tester, locale) async {
    when(mockInternetSettingsNotifier.build()).thenReturn(
        InternetSettingsState.fromJson(internetSettingsStateData)
            .copyWith(macCloneAddress: 'A4:83:E7:11:8A:19'));
    when(mockInternetSettingsNotifier.setMacAddressClone(true, 'A4:83:E7:11:8A:19'))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
    });

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        internetSettingsProvider
            .overrideWith(() => mockInternetSettingsNotifier),
      ],
      locale: locale,
      child: const MACCloneView(),
    );
    await tester.pumpWidget(widget);

    final appSwitchFinder = find.byType(AppSwitch);
    await tester.tap(appSwitchFinder);
    await tester.pumpAndSettle();

    final saveBtnFinder = find.byType(AppFilledButton);
    await tester.tap(saveBtnFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('MAC address clone - save failed', (tester, locale) async {
    when(mockInternetSettingsNotifier.build()).thenReturn(
        InternetSettingsState.fromJson(internetSettingsStateData)
            .copyWith(macCloneAddress: 'A4:83:E7:11:8A:19'));
    when(mockInternetSettingsNotifier.setMacAddressClone(true, 'A4:83:E7:11:8A:19'))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      throw Exception();
    });

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        internetSettingsProvider
            .overrideWith(() => mockInternetSettingsNotifier),
      ],
      locale: locale,
      child: const MACCloneView(),
    );
    await tester.pumpWidget(widget);

    final appSwitchFinder = find.byType(AppSwitch);
    await tester.tap(appSwitchFinder);
    await tester.pumpAndSettle();

    final saveBtnFinder = find.byType(AppFilledButton);
    await tester.tap(saveBtnFinder);
    await tester.pumpAndSettle();
  });
}
