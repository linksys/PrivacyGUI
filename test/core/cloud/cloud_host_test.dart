import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/cloud/cloud_host.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';

// The host both cloud clients send to (#1861): the router's local address, or
// null for the cloud's own base URL.
void main() {
  /// [cloudHost] for [force] and [routerType], with the router at [ip]. It
  /// records whether it read the router type and the local address.
  ({String? host, bool readRouterType, bool readIp}) hostFor(
    ForceCommand force,
    RouterType routerType, {
    String ip = '192.168.1.1',
  }) {
    var readRouterType = false;
    var readIp = false;
    final host = cloudHost(
      force: force,
      routerType: () {
        readRouterType = true;
        return routerType;
      },
      localIp: () {
        readIp = true;
        return ip;
      },
    );
    return (host: host, readRouterType: readRouterType, readIp: readIp);
  }

  group('a forced local build', () {
    test('goes through the router, without asking which router it is', () {
      final result = hostFor(ForceCommand.local, RouterType.behindManaged);

      expect(result.host, 'https://192.168.1.1');
      expect(result.readRouterType, isFalse);
    });

    test('goes through the router even when the phone is not on one of ours',
        () {
      expect(hostFor(ForceCommand.local, RouterType.others).host,
          'https://192.168.1.1');
    });
  });

  group('any other build', () {
    for (final routerType in [RouterType.behind, RouterType.behindManaged]) {
      test('goes through the router when the phone is behind it ($routerType)',
          () {
        for (final force in [ForceCommand.none, ForceCommand.remote]) {
          expect(hostFor(force, routerType).host, 'https://192.168.1.1',
              reason: '$force');
        }
      });
    }

    test('goes to the cloud when the phone is not on one of our routers', () {
      for (final force in [ForceCommand.none, ForceCommand.remote]) {
        final result = hostFor(force, RouterType.others);

        expect(result.host, isNull, reason: '$force');
        expect(result.readIp, isFalse, reason: '$force');
      }
    });
  });

  test('keeps the scheme of a local address that already has one', () {
    expect(
        hostFor(ForceCommand.local, RouterType.behind,
                ip: 'http://myrouter.local')
            .host,
        'http://myrouter.local');
  });
}
