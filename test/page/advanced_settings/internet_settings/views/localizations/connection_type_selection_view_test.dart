import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/connection_type_selection_view.dart';
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
  testLocalizations('InternetSettings - connection type selection - ipv4', (tester, locale) async {
    final state = InternetSettingsState.fromMap(internetSettingsStateDHCP);
    when(mockInternetSettingsNotifier.build()).thenReturn(state);

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        internetSettingsProvider
            .overrideWith(() => mockInternetSettingsNotifier),
      ],
      locale: locale,
      child: ConnectionTypeSelectionView(
        args: {
          'supportedList': state.ipv4Setting.supportedIPv4ConnectionType,
          'selected': state.ipv4Setting.ipv4ConnectionType,
        },
      ),
    );
    await tester.pumpWidget(widget);
  });

  testLocalizations('InternetSettings - connection type selection - ipv6', (tester, locale) async {
    final state = InternetSettingsState.fromMap(internetSettingsStateDHCP);
    when(mockInternetSettingsNotifier.build()).thenReturn(state);

    final disabled = state.ipv6Setting.supportedIPv6ConnectionType
        .where((ipv6) => !state.ipv4Setting.supportedWANCombinations.any(
            (combine) =>
                combine.wanType == state.ipv4Setting.ipv4ConnectionType &&
                combine.wanIPv6Type == ipv6))
        .toList();

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        internetSettingsProvider
            .overrideWith(() => mockInternetSettingsNotifier),
      ],
      locale: locale,
      child: ConnectionTypeSelectionView(
        args: {
          'supportedList': state.ipv6Setting.supportedIPv6ConnectionType,
          'selected': state.ipv6Setting.ipv6ConnectionType,
          'disabled': disabled,
        },
      ),
    );
    await tester.pumpWidget(widget);
  });
}
