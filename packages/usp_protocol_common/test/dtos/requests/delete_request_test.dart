import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspDeleteRequest', () {
    test('should correctly assign properties', () {
      final paths = [UspPath.parse('Device.WiFi.AccessPoint.1')];
      final request = UspDeleteRequest(paths, allowPartial: true);

      expect(request.objPaths, equals(paths));
      expect(request.allowPartial, isTrue);
    });

    test('should have allowPartial default to false', () {
      final paths = [UspPath.parse('Device.WiFi.AccessPoint.1')];
      final request = UspDeleteRequest(paths);
      expect(request.allowPartial, isFalse);
    });

    test('should support value equality', () {
      final paths1 = [UspPath.parse('Device.WiFi.AccessPoint.1')];
      final request1 = UspDeleteRequest(paths1, allowPartial: true);

      final paths2 = [UspPath.parse('Device.WiFi.AccessPoint.1')];
      final request2 = UspDeleteRequest(paths2, allowPartial: true);

      final paths3 = [UspPath.parse('Device.LocalAgent.1')];
      final request3 = UspDeleteRequest(paths3, allowPartial: true);

      final request4 = UspDeleteRequest(paths1, allowPartial: false);

      expect(request1, equals(request2));
      expect(request1, isNot(equals(request3)));
      expect(request1, isNot(equals(request4)));
    });
  });
}
