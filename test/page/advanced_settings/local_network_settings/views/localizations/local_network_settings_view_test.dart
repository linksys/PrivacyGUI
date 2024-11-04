import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/local_network_settings_state.dart';
import '../../../../../mocks/local_network_settings_notifier_mocks.dart';

void main() {
  late MockLocalNetworkSettingsNotifier mockLocalNetworkSettingsNotifier;

  setUp(() {
    mockLocalNetworkSettingsNotifier = MockLocalNetworkSettingsNotifier();
  });

  testLocalizations('Local network settings view test - Overview',
      (tester, locale) async {
    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
    when(mockLocalNetworkSettingsNotifier.fetch(fetchRemote: true)).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState);
    });
    when(mockLocalNetworkSettingsNotifier.currentSettings()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
      ],
      locale: locale,
      child: const LocalNetworkSettingsView(),
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  });

  testLocalizations('Local network settings view test - Tap host name',
      (tester, locale) async {
    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
    when(mockLocalNetworkSettingsNotifier.fetch(fetchRemote: true)).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState);
    });
    when(mockLocalNetworkSettingsNotifier.currentSettings()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
      ],
      locale: locale,
      child: const LocalNetworkSettingsView(),
    );
    await tester.pumpWidget(widget);

    final hostNameFinder = find.byType(AppCard).at(0);
    expect(hostNameFinder, findsOneWidget);
    await tester.tap(hostNameFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Local network settings view test - Tap IP address',
      (tester, locale) async {
    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
    when(mockLocalNetworkSettingsNotifier.fetch(fetchRemote: true)).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState);
    });
    when(mockLocalNetworkSettingsNotifier.currentSettings()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
      ],
      locale: locale,
      child: const LocalNetworkSettingsView(),
    );
    await tester.pumpWidget(widget);

    final ipAddressFinder = find.byType(AppCard).at(1);
    expect(ipAddressFinder, findsOneWidget);
    await tester.tap(ipAddressFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Local network settings view test - Tap subnet mask',
      (tester, locale) async {
    when(mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));
    when(mockLocalNetworkSettingsNotifier.fetch(fetchRemote: true)).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState);
    });
    when(mockLocalNetworkSettingsNotifier.currentSettings()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState));

    final widget = testableSingleRoute(
      config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
      overrides: [
        localNetworkSettingProvider
            .overrideWith(() => mockLocalNetworkSettingsNotifier),
      ],
      locale: locale,
      child: const LocalNetworkSettingsView(),
    );
    await tester.pumpWidget(widget);

    final subnetFinder = find.byType(AppCard).at(2);
    expect(subnetFinder, findsOneWidget);
    await tester.tap(subnetFinder);
    await tester.pumpAndSettle();
  });
}
