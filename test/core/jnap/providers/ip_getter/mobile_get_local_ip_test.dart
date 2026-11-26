// On a device (and in these tests, which build for one) the router's address
// is the gateway the connectivity check found.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/providers/ip_getter/mobile_get_local_ip.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';

class _Connectivity extends ConnectivityNotifier {
  _Connectivity(this.gatewayIp);

  final String? gatewayIp;

  @override
  ConnectivityState build() => ConnectivityState(
        hasInternet: true,
        connectivityInfo: ConnectivityInfo(gatewayIp: gatewayIp),
      );
}

final _localIp = Provider((ref) => getLocalIp(ref));
final _fullLocation = Provider((ref) => getFullLocation(ref));

void main() {
  ProviderContainer on(String? gatewayIp) {
    final container = ProviderContainer(overrides: [
      connectivityProvider.overrideWith(() => _Connectivity(gatewayIp)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('the router is the gateway the device is on', () {
    expect(on('192.168.1.1').read(_localIp), '192.168.1.1');
  });

  test('no gateway yet gives no address', () {
    expect(on(null).read(_localIp), '');
  });

  test('a device has no page location to give', () {
    expect(() => on('192.168.1.1').read(_fullLocation),
        throwsA(isA<UnsupportedError>()));
  });
}
