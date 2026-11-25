// Wi-Fi Settings keeps one unsaved-changes flag per tab, which decides whether
// leaving the tab asks first.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';

void main() {
  late ProviderContainer container;

  WiFiViewNotifier notifier() => container.read(wifiViewProvider.notifier);
  WiFiViewState flags() => container.read(wifiViewProvider);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('starts with no tab changed', () {
    expect(flags().isWifiListViewStateChanged, isFalse);
    expect(flags().isWifiAdvancedSettingsViewStateChanged, isFalse);
    expect(flags().isMacFilteringViewStateChanged, isFalse);
  });

  test('each tab sets and clears its own flag, and no other', () {
    notifier().setWifiListViewStateChanged(true);
    expect(flags(), const WiFiViewState(isWifiListViewStateChanged: true));

    notifier().setWifiAdvancedSettingsViewChanged(true);
    notifier().setWifiListViewStateChanged(false);
    expect(flags(),
        const WiFiViewState(isWifiAdvancedSettingsViewStateChanged: true));

    notifier().setMacFilteringViewChanged(true);
    notifier().setWifiAdvancedSettingsViewChanged(false);
    expect(flags(), const WiFiViewState(isMacFilteringViewStateChanged: true));

    notifier().setMacFilteringViewChanged(false);
    expect(flags(), const WiFiViewState());
  });
}
