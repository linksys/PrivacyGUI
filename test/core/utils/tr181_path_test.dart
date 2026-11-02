import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/tr181_path.dart';

void main() {
  group('withoutTrailingDot', () {
    test('drops the dot, the form a LowerLayers reference holds', () {
      expect(withoutTrailingDot('Device.GRE.Tunnel.3.Interface.2.'),
          'Device.GRE.Tunnel.3.Interface.2');
    });

    test('leaves a path with no dot, and the empty path, unchanged', () {
      expect(withoutTrailingDot('Device.PPP.Interface.1'),
          'Device.PPP.Interface.1');
      expect(withoutTrailingDot(''), '');
    });
  });

  group('interfacePathsByAlias', () {
    test('maps each Alias to its dot-terminated interface path', () {
      expect(
        interfacePathsByAlias({
          'Device.IP.Interface.3.Alias': lanInterfaceAlias,
          'Device.IP.Interface.5.Alias': wanInterfaceAlias,
        }),
        {
          lanInterfaceAlias: 'Device.IP.Interface.3.',
          wanInterfaceAlias: 'Device.IP.Interface.5.',
        },
      );
    });

    test('leaves out an interface with no Alias', () {
      expect(
        interfacePathsByAlias({
          'Device.IP.Interface.1.Alias': wanInterfaceAlias,
          'Device.IP.Interface.6.Alias': '',
          'Device.IP.Interface.7.Alias': null,
        }),
        {wanInterfaceAlias: 'Device.IP.Interface.1.'},
      );
    });

    test('of two interfaces with one Alias, keeps the first in the response',
        () {
      expect(
        interfacePathsByAlias({
          'Device.IP.Interface.4.Alias': wanInterfaceAlias,
          'Device.IP.Interface.2.Alias': wanInterfaceAlias,
        }),
        {wanInterfaceAlias: 'Device.IP.Interface.4.'},
      );
    });

    test('ignores keys that are not an interface Alias', () {
      expect(
        interfacePathsByAlias({
          'Device.IP.Interface.2.Name': wanInterfaceAlias,
          'Device.IP.Interface.2.IPv4Address.1.Alias': 'cpe-1',
          'Device.Ethernet.Interface.2.Alias': wanInterfaceAlias,
        }),
        isEmpty,
      );
    });
  });
}
