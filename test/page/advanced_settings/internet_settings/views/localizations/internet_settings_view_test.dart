import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/internet_settings_view.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/internet_settings_state_data.dart';
import '../../../../../mocks/internet_settings_notifier_mocks.dart';

Future<void> main() async {
  late InternetSettingsNotifier mockInternetSettingsNotifier;

  setUp(() {
    mockInternetSettingsNotifier = MockInternetSettingsNotifier();
  });

  group('InternetSettings - init', () {
    testLocalizations('InternetSettings - mac address clone on',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromJson(internetSettingsStateData)
              .copyWith(macClone: true));
      when(mockInternetSettingsNotifier.fetch())
          .thenAnswer((realInvocation) async {
        await Future.delayed(const Duration(seconds: 1));
        return InternetSettingsState.fromJson(internetSettingsStateData)
            .copyWith(macClone: true);
      });
      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const InternetSettingsView(),
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('InternetSettings - mac address clone off',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromJson(internetSettingsStateData));
      when(mockInternetSettingsNotifier.fetch())
          .thenAnswer((realInvocation) async {
        await Future.delayed(const Duration(seconds: 1));
        return InternetSettingsState.fromJson(internetSettingsStateData);
      });
      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const InternetSettingsView(),
      );
      await tester.pumpWidget(widget);
    });
  });
}
