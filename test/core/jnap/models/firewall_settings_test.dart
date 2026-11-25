import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/firewall_settings.dart';

/// `GetFirewallSettings` output, the spec's sample.
const _output = <String, dynamic>{
  'isIPv4FirewallEnabled': true,
  'isIPv6FirewallEnabled': true,
  'blockMulticast': false,
  'blockNATRedirection': false,
  'blockIDENT': true,
  'blockAnonymousRequests': true,
  'blockIPSec': true,
  'blockPPTP': true,
  'blockL2TP': false,
};

void main() {
  test('reads each switch by its own name', () {
    final settings = FirewallSettings.fromMap(_output);

    expect(settings.isIPv4FirewallEnabled, isTrue);
    expect(settings.isIPv6FirewallEnabled, isTrue);
    expect(settings.blockMulticast, isFalse);
    expect(settings.blockNATRedirection, isFalse);
    expect(settings.blockIDENT, isTrue);
    expect(settings.blockAnonymousRequests, isTrue);
    expect(settings.blockIPSec, isTrue);
    expect(settings.blockPPTP, isTrue);
    expect(settings.blockL2TP, isFalse);
  });

  test('writes the fields it read', () {
    expect(FirewallSettings.fromMap(_output).toMap(), _output);
  });

  test('survives a trip through JSON text', () {
    final settings = FirewallSettings.fromMap(_output);

    expect(FirewallSettings.fromJson(settings.toJson()), settings);
  });

  test('copyWith changes only what it names', () {
    final settings = FirewallSettings.fromMap(_output);

    final changed = settings.copyWith(
      blockAnonymousRequests: false,
      blockIDENT: false,
      blockIPSec: false,
      blockL2TP: true,
      blockMulticast: true,
      blockNATRedirection: true,
      blockPPTP: false,
      isIPv4FirewallEnabled: false,
      isIPv6FirewallEnabled: false,
    );

    expect(changed.toMap(), {
      'isIPv4FirewallEnabled': false,
      'isIPv6FirewallEnabled': false,
      'blockMulticast': true,
      'blockNATRedirection': true,
      'blockIDENT': false,
      'blockAnonymousRequests': false,
      'blockIPSec': false,
      'blockPPTP': false,
      'blockL2TP': true,
    });
    expect(settings.copyWith(), settings);
  });
}
