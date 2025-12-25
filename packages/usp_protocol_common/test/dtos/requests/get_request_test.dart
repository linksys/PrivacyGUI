import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspGetRequest', () {
    test('should correctly assign properties', () {
      final paths = [UspPath.parse('Device.DeviceInfo.')];
      final request = UspGetRequest(paths);

      expect(request.paths, equals(paths));
    });

    test('should support value equality', () {
      final paths1 = [UspPath.parse('Device.DeviceInfo.')];
      final request1 = UspGetRequest(paths1);

      final paths2 = [UspPath.parse('Device.DeviceInfo.')];
      final request2 = UspGetRequest(paths2);

      final paths3 = [UspPath.parse('Device.LocalAgent.')];
      final request3 = UspGetRequest(paths3);

      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
    });
  });
}
