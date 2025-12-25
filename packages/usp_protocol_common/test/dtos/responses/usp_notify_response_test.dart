import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspNotifyResponse', () {
    test('should correctly assign properties', () {
      const subscriptionId = 'sub123';
      final response = UspNotifyResponse(subscriptionId: subscriptionId);
      expect(response.subscriptionId, equals(subscriptionId));
    });

    test('should support value equality', () {
      const subscriptionId1 = 'sub123';
      final response1 = UspNotifyResponse(subscriptionId: subscriptionId1);
      final response2 = UspNotifyResponse(subscriptionId: subscriptionId1);
      const subscriptionId3 = 'sub456';
      final response3 = UspNotifyResponse(subscriptionId: subscriptionId3);

      expect(response1, equals(response2));
      expect(response1, isNot(equals(response3)));
    });
  });
}
