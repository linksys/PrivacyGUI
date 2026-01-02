import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/providers/connectivity/availability_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_state.dart';

void main() {
  // ============================================================================
  // ConnectivityState tests
  // ============================================================================

  group('ConnectivityState', () {
    test('can be instantiated with required parameters', () {
      // Arrange & Act
      const state = ConnectivityState(
        hasInternet: true,
        connectivityInfo: ConnectivityInfo(),
      );

      // Assert
      expect(state.hasInternet, true);
      expect(state.connectivityInfo, const ConnectivityInfo());
      expect(state.cloudAvailabilityInfo, isNull);
    });

    test('can be instantiated with all parameters', () {
      // Arrange & Act
      const state = ConnectivityState(
        hasInternet: true,
        connectivityInfo: ConnectivityInfo(
          type: ConnectivityResult.wifi,
          gatewayIp: '192.168.1.1',
          ssid: 'TestNetwork',
          routerType: RouterType.behindManaged,
        ),
        cloudAvailabilityInfo: AvailabilityInfo(isCloudOk: true),
      );

      // Assert
      expect(state.hasInternet, true);
      expect(state.connectivityInfo.type, ConnectivityResult.wifi);
      expect(state.connectivityInfo.gatewayIp, '192.168.1.1');
      expect(state.connectivityInfo.ssid, 'TestNetwork');
      expect(state.connectivityInfo.routerType, RouterType.behindManaged);
      expect(state.cloudAvailabilityInfo?.isCloudOk, true);
    });

    group('copyWith', () {
      test('copies hasInternet when provided', () {
        // Arrange
        const original = ConnectivityState(
          hasInternet: false,
          connectivityInfo: ConnectivityInfo(),
        );

        // Act
        final copied = original.copyWith(hasInternet: true);

        // Assert
        expect(copied.hasInternet, true);
        expect(copied.connectivityInfo, original.connectivityInfo);
      });

      test('copies connectivityInfo when provided', () {
        // Arrange
        const original = ConnectivityState(
          hasInternet: true,
          connectivityInfo: ConnectivityInfo(),
        );
        const newInfo = ConnectivityInfo(
          type: ConnectivityResult.wifi,
          routerType: RouterType.behind,
        );

        // Act
        final copied = original.copyWith(connectivityInfo: newInfo);

        // Assert
        expect(copied.hasInternet, true);
        expect(copied.connectivityInfo, newInfo);
        expect(copied.connectivityInfo.routerType, RouterType.behind);
      });

      test('copies cloudAvailabilityInfo when provided', () {
        // Arrange
        const original = ConnectivityState(
          hasInternet: true,
          connectivityInfo: ConnectivityInfo(),
        );
        const newAvailability = AvailabilityInfo(isCloudOk: false);

        // Act
        final copied = original.copyWith(cloudAvailabilityInfo: newAvailability);

        // Assert
        expect(copied.cloudAvailabilityInfo, newAvailability);
        expect(copied.cloudAvailabilityInfo?.isCloudOk, false);
      });

      test('preserves original values when no parameters provided', () {
        // Arrange
        const original = ConnectivityState(
          hasInternet: true,
          connectivityInfo: ConnectivityInfo(
            type: ConnectivityResult.wifi,
            routerType: RouterType.behindManaged,
          ),
          cloudAvailabilityInfo: AvailabilityInfo(isCloudOk: true),
        );

        // Act
        final copied = original.copyWith();

        // Assert
        expect(copied.hasInternet, original.hasInternet);
        expect(copied.connectivityInfo, original.connectivityInfo);
        expect(copied.cloudAvailabilityInfo, original.cloudAvailabilityInfo);
      });
    });

    group('equality', () {
      test('two states with same values are equal', () {
        // Arrange
        const state1 = ConnectivityState(
          hasInternet: true,
          connectivityInfo: ConnectivityInfo(
            type: ConnectivityResult.wifi,
            gatewayIp: '192.168.1.1',
          ),
        );
        const state2 = ConnectivityState(
          hasInternet: true,
          connectivityInfo: ConnectivityInfo(
            type: ConnectivityResult.wifi,
            gatewayIp: '192.168.1.1',
          ),
        );

        // Assert
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('two states with different hasInternet are not equal', () {
        // Arrange
        const state1 = ConnectivityState(
          hasInternet: true,
          connectivityInfo: ConnectivityInfo(),
        );
        const state2 = ConnectivityState(
          hasInternet: false,
          connectivityInfo: ConnectivityInfo(),
        );

        // Assert
        expect(state1, isNot(equals(state2)));
      });

      test('two states with different connectivityInfo are not equal', () {
        // Arrange
        const state1 = ConnectivityState(
          hasInternet: true,
          connectivityInfo: ConnectivityInfo(routerType: RouterType.behind),
        );
        const state2 = ConnectivityState(
          hasInternet: true,
          connectivityInfo:
              ConnectivityInfo(routerType: RouterType.behindManaged),
        );

        // Assert
        expect(state1, isNot(equals(state2)));
      });
    });
  });

  // ============================================================================
  // ConnectivityInfo tests
  // ============================================================================

  group('ConnectivityInfo', () {
    test('has correct default values', () {
      // Arrange & Act
      const info = ConnectivityInfo();

      // Assert
      expect(info.type, ConnectivityResult.none);
      expect(info.gatewayIp, isNull);
      expect(info.ssid, isNull);
      expect(info.routerType, RouterType.others);
    });

    test('can be instantiated with all parameters', () {
      // Arrange & Act
      const info = ConnectivityInfo(
        type: ConnectivityResult.wifi,
        gatewayIp: '192.168.1.1',
        ssid: 'MyNetwork',
        routerType: RouterType.behindManaged,
      );

      // Assert
      expect(info.type, ConnectivityResult.wifi);
      expect(info.gatewayIp, '192.168.1.1');
      expect(info.ssid, 'MyNetwork');
      expect(info.routerType, RouterType.behindManaged);
    });

    group('copyWith', () {
      test('copies type when provided', () {
        // Arrange
        const original = ConnectivityInfo(type: ConnectivityResult.none);

        // Act
        final copied = original.copyWith(type: ConnectivityResult.wifi);

        // Assert
        expect(copied.type, ConnectivityResult.wifi);
      });

      test('copies gatewayIp when provided', () {
        // Arrange
        const original = ConnectivityInfo();

        // Act
        final copied = original.copyWith(gatewayIp: '10.0.0.1');

        // Assert
        expect(copied.gatewayIp, '10.0.0.1');
      });

      test('copies ssid when provided', () {
        // Arrange
        const original = ConnectivityInfo();

        // Act
        final copied = original.copyWith(ssid: 'NewNetwork');

        // Assert
        expect(copied.ssid, 'NewNetwork');
      });

      test('copies routerType when provided', () {
        // Arrange
        const original = ConnectivityInfo(routerType: RouterType.others);

        // Act
        final copied = original.copyWith(routerType: RouterType.behind);

        // Assert
        expect(copied.routerType, RouterType.behind);
      });

      test('preserves original values when no parameters provided', () {
        // Arrange
        const original = ConnectivityInfo(
          type: ConnectivityResult.wifi,
          gatewayIp: '192.168.1.1',
          ssid: 'TestSSID',
          routerType: RouterType.behindManaged,
        );

        // Act
        final copied = original.copyWith();

        // Assert
        expect(copied, equals(original));
      });
    });

    group('equality', () {
      test('two infos with same values are equal', () {
        // Arrange
        const info1 = ConnectivityInfo(
          type: ConnectivityResult.wifi,
          gatewayIp: '192.168.1.1',
          ssid: 'Network',
          routerType: RouterType.behind,
        );
        const info2 = ConnectivityInfo(
          type: ConnectivityResult.wifi,
          gatewayIp: '192.168.1.1',
          ssid: 'Network',
          routerType: RouterType.behind,
        );

        // Assert
        expect(info1, equals(info2));
        expect(info1.hashCode, equals(info2.hashCode));
      });

      test('two infos with different routerType are not equal', () {
        // Arrange
        const info1 = ConnectivityInfo(routerType: RouterType.others);
        const info2 = ConnectivityInfo(routerType: RouterType.behind);

        // Assert
        expect(info1, isNot(equals(info2)));
      });
    });
  });

  // ============================================================================
  // RouterType tests
  // ============================================================================

  group('RouterType', () {
    test('has three values', () {
      expect(RouterType.values.length, 3);
    });

    test('contains behind value', () {
      expect(RouterType.values, contains(RouterType.behind));
    });

    test('contains behindManaged value', () {
      expect(RouterType.values, contains(RouterType.behindManaged));
    });

    test('contains others value', () {
      expect(RouterType.values, contains(RouterType.others));
    });
  });

  // ============================================================================
  // AvailabilityInfo tests
  // ============================================================================

  group('AvailabilityInfo', () {
    test('can be instantiated with required parameter', () {
      // Arrange & Act
      const info = AvailabilityInfo(isCloudOk: true);

      // Assert
      expect(info.isCloudOk, true);
    });

    test('factory init creates instance with isCloudOk true', () {
      // Arrange & Act
      final info = AvailabilityInfo.init();

      // Assert
      expect(info.isCloudOk, true);
    });

    group('copyWith', () {
      test('copies isCloudOk when provided', () {
        // Arrange
        const original = AvailabilityInfo(isCloudOk: true);

        // Act
        final copied = original.copyWith(isCloudOk: false);

        // Assert
        expect(copied.isCloudOk, false);
      });

      test('preserves original value when no parameter provided', () {
        // Arrange
        const original = AvailabilityInfo(isCloudOk: false);

        // Act
        final copied = original.copyWith();

        // Assert
        expect(copied.isCloudOk, false);
      });
    });

    group('equality', () {
      test('two infos with same isCloudOk are equal', () {
        // Arrange
        const info1 = AvailabilityInfo(isCloudOk: true);
        const info2 = AvailabilityInfo(isCloudOk: true);

        // Assert
        expect(info1, equals(info2));
        expect(info1.hashCode, equals(info2.hashCode));
      });

      test('two infos with different isCloudOk are not equal', () {
        // Arrange
        const info1 = AvailabilityInfo(isCloudOk: true);
        const info2 = AvailabilityInfo(isCloudOk: false);

        // Assert
        expect(info1, isNot(equals(info2)));
      });
    });
  });
}
