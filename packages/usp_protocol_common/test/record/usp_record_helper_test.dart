import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_protocol_common/src/generated/usp_record.pb.dart'
    as pb_record;

void main() {
  group('UspRecordHelper', () {
    final recordHelper = UspRecordHelper();
    final converter = UspProtobufConverter();
    const fromId = 'controller-id';
    const toId = 'agent-id';
    const msgId = 'test-msg-id';

    test('should correctly wrap and unwrap a USP message', () {
      // 1. Create a DTO and convert to a Protobuf Msg
      final getRequestDto = UspGetRequest([
        UspPath.parse('Device.DeviceInfo.'),
      ]);
      final originalMsg = converter.toProto(getRequestDto, msgId: msgId);

      // 2. Wrap the Msg into a Record and get binary data
      final record = recordHelper.wrap(originalMsg, fromId: fromId, toId: toId);
      final recordBytes = record.writeToBuffer();

      // 3. Unwrap the binary data back to a Msg
      final unwrappedMsg = recordHelper.unwrap(recordBytes);

      // 4. Assert
      // Protobuf objects don't have inherent equality, so we compare their binary form.
      expect(unwrappedMsg.writeToBuffer(), equals(originalMsg.writeToBuffer()));

      // Also check some header fields on the record itself
      expect(record.fromId, fromId);
      expect(record.toId, toId);
      expect(
        record.payloadSecurity,
        pb_record.Record_PayloadSecurity.PLAINTEXT,
      );
    });

    test(
      'unwrap should throw UspException for PLAINTEXT security but missing noSessionContext',
      () {
        final record = pb_record.Record()
          ..version = "1.0"
          ..fromId = fromId
          ..toId = toId
          ..payloadSecurity = pb_record.Record_PayloadSecurity.PLAINTEXT;

        final recordBytes = record.writeToBuffer();
        expect(
          () => recordHelper.unwrap(recordBytes),
          throwsA(isA<UspException>()),
        );
      },
    );

    test('unwrap should throw UspException for TLS12 security', () {
      final record = pb_record.Record()
        ..version = "1.0"
        ..fromId = fromId
        ..toId = toId
        ..payloadSecurity = pb_record.Record_PayloadSecurity.TLS12;

      final recordBytes = record.writeToBuffer();
      expect(
        () => recordHelper.unwrap(recordBytes),
        throwsA(isA<UspException>()),
      );
    });

    test('unwrap should throw UspException for empty payload', () {
      final record = pb_record.Record()
        ..version = "1.0"
        ..fromId = fromId
        ..toId = toId
        ..payloadSecurity = pb_record.Record_PayloadSecurity.PLAINTEXT
        ..noSessionContext = pb_record.NoSessionContextRecord();

      final recordBytes = record.writeToBuffer();
      expect(
        () => recordHelper.unwrap(recordBytes),
        throwsA(isA<UspException>()),
      );
    });

    test('unwrap should throw UspException for invalid record bytes', () {
      final invalidBytes = [1, 2, 3];
      expect(
        () => recordHelper.unwrap(invalidBytes),
        throwsA(isA<UspException>()),
      );
    });

    test('peekHeader should correctly parse record header', () {
      final getRequestDto = UspGetRequest([
        UspPath.parse('Device.DeviceInfo.'),
      ]);
      final originalMsg = converter.toProto(getRequestDto, msgId: msgId);

      final record = recordHelper.wrap(originalMsg, fromId: fromId, toId: toId);
      final recordBytes = record.writeToBuffer();

      final peekedRecord = recordHelper.peekHeader(recordBytes);
      expect(peekedRecord.fromId, fromId);
      expect(peekedRecord.toId, toId);
      expect(peekedRecord.version, "1.0");
    });
  });
}
