import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_notifier.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';

import '../../../mocks/provider_overrides/mock_mac_filter.dart';
import '../../../mocks/test_data/scenes/mac_filter_scene_data.dart';

/// The Wi-Fi page's route guard is one proxy over all of its tabs, so leaving
/// the page with an unsaved edit on **any** tab prompts — including MAC
/// Filtering, the third tab (#1636), whose edits a proxy over the first two
/// would let the user walk away from silently.
void main() {
  ProviderContainer container() {
    final c = ProviderContainer(overrides: wifiMacFilterTabOverrides());
    addTearDown(c.dispose);
    // Keep every autoDispose tab notifier alive for the length of the test.
    c.listen(preservableUspWifiPageProvider, (_, __) {});
    c.listen(uspMacFilterProvider, (_, __) {});
    return c;
  }

  test('clean when no tab is edited', () {
    final c = container();

    expect(c.read(preservableUspWifiPageProvider).isDirty(), isFalse);
  });

  test('a MAC Filtering edit makes the page dirty, and revert clears it', () {
    final c = container();

    c
        .read(uspMacFilterProvider.notifier)
        .removeMac(gateMacFilterState.settings.current.macs.first);
    expect(c.read(preservableUspWifiPageProvider).isDirty(), isTrue,
        reason: 'leaving Wi-Fi Settings now must ask about the unsaved edit');

    c.read(preservableUspWifiPageProvider).revert();
    expect(c.read(uspMacFilterProvider).isDirty, isFalse);
    expect(c.read(preservableUspWifiPageProvider).isDirty(), isFalse);
  });
}
