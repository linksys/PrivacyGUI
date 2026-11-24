import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/local_network/models/local_network_feature_state.dart';
import 'package:privacy_gui/page/local_network/models/local_network_settings.dart';
import 'package:privacy_gui/page/local_network/models/local_network_status.dart';
import 'package:privacy_gui/page/local_network/models/local_network_ui_model.dart';

const _saved = LocalNetworkUIModel(
  hostName: 'MyRouter',
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  dhcpEnabled: true,
  minAddress: '192.168.1.100',
  maxAddress: '192.168.1.249',
  leaseTimeMinutes: 720,
  dnsServer1: '',
  dnsServer2: '',
  dnsServer3: '',
);

/// The page with [edit] applied to the saved values.
LocalNetworkFeatureState _edited(
        LocalNetworkUIModel Function(LocalNetworkUIModel) edit) =>
    LocalNetworkFeatureState(
      settings: Preservable(
        original: const LocalNetworkSettings(model: _saved),
        current: LocalNetworkSettings(model: edit(_saved)),
      ),
      status: const LocalNetworkStatus(isLoading: false),
    );

void main() {
  group('LocalNetworkFeatureState change checks', () {
    test('an IP change is a network change and an IP change only', () {
      final state = _edited((m) => m.copyWith(ipAddress: '192.168.2.1'));

      expect(state.hasNetworkChange, isTrue);
      expect(state.hasIpAddressChange, isTrue);
      expect(state.hasSubnetMaskChange, isFalse);
    });

    test('a mask change is a network change, not an IP change', () {
      // Save asks before a mask change too, since the router restarts the LAN
      // (PrivacyGUI#1729).
      final state = _edited((m) => m.copyWith(subnetMask: '255.255.0.0'));

      expect(state.hasNetworkChange, isTrue);
      expect(state.hasSubnetMaskChange, isTrue);
      expect(state.hasIpAddressChange, isFalse);
    });

    test('an IP and a mask change together set both', () {
      final state = _edited((m) =>
          m.copyWith(ipAddress: '192.168.2.1', subnetMask: '255.255.0.0'));

      expect(state.hasIpAddressChange, isTrue);
      expect(state.hasSubnetMaskChange, isTrue);
      expect(state.hasNetworkChange, isTrue);
    });

    test('a host name change is not a network change', () {
      final state = _edited((m) => m.copyWith(hostName: 'NewRouter'));

      expect(state.hasHostNameChange, isTrue);
      expect(state.hasNetworkChange, isFalse);
    });

    test('a pool or DNS change alone is none of them', () {
      final state = _edited(
          (m) => m.copyWith(minAddress: '192.168.1.50', dnsServer1: '9.9.9.9'));

      expect(state.hasNetworkChange, isFalse);
      expect(state.hasIpAddressChange, isFalse);
      expect(state.hasSubnetMaskChange, isFalse);
      expect(state.hasHostNameChange, isFalse);
    });
  });
}
