import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/firewall_settings.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_state.dart';

const _settings = FirewallSettings(
  blockAnonymousRequests: true,
  blockIDENT: false,
  blockIPSec: true,
  blockL2TP: false,
  blockMulticast: true,
  blockNATRedirection: false,
  blockPPTP: true,
  isIPv4FirewallEnabled: true,
  isIPv6FirewallEnabled: false,
);

void main() {
  test('survives a trip through JSON text', () {
    const state = FirewallState(settings: _settings);

    expect(FirewallState.fromJson(state.toJson()), state);
  });

  test('copyWith changes only what it names', () {
    const state = FirewallState(settings: _settings);
    final off = _settings.copyWith(isIPv4FirewallEnabled: false);

    expect(state.copyWith(settings: off).settings, off);
    expect(state.copyWith(), state);
  });
}
