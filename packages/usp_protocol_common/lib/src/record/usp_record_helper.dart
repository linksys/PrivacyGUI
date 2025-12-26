import '../generated/usp_msg.pb.dart' as pb_msg;
import '../generated/usp_record.pb.dart' as pb_record;
import '../exceptions/usp_exception.dart';

/// A utility class for wrapping and unwrapping USP messages in USP records.
class UspRecordHelper {
  /// Wraps a [pb_msg.Msg] in a [pb_record.Record].
  pb_record.Record wrap(
    pb_msg.Msg msg, {
    required String fromId,
    required String toId,
    String version = "1.0",
  }) {
    // 1. Serialize the inner Msg
    final payloadBytes = msg.writeToBuffer();

    // 2. Construct the outer Record
    // Note: Since this is PLAINTEXT, NoSessionContextRecord must be used
    final noSessionRecord = pb_record.NoSessionContextRecord()
      ..payload = payloadBytes;

    return pb_record.Record()
      ..version = version
      ..fromId = fromId
      ..toId = toId
      ..payloadSecurity = pb_record.Record_PayloadSecurity.PLAINTEXT
      ..noSessionContext = noSessionRecord;
  }

  /// Unwraps a [pb_msg.Msg] from a binary [pb_record.Record].
  pb_msg.Msg unwrap(List<int> recordBytes) {
    try {
      // 1. Deserialize the outer Record
      final record = pb_record.Record.fromBuffer(recordBytes);

      // 2. Check security and extract the payload
      List<int> payloadBytes;

      if (record.payloadSecurity ==
          pb_record.Record_PayloadSecurity.PLAINTEXT) {
        if (!record.hasNoSessionContext()) {
          throw UspException(
            7002,
            "Record has PLAINTEXT security but noSessionContext is missing",
          );
        }
        payloadBytes = record.noSessionContext.payload;
      } else if (record.payloadSecurity ==
          pb_record.Record_PayloadSecurity.TLS12) {
        // TODO: Implement E2E decryption logic
        // if (!record.hasSessionContext()) ...
        throw UspException(7000, "E2E Encryption not supported yet");
      } else {
        throw UspException(
          7000,
          "Unsupported security type: ${record.payloadSecurity}",
        );
      }

      // 3. Deserialize the inner Msg
      if (payloadBytes.isEmpty) {
        throw UspException(7002, "Record payload is empty");
      }

      return pb_msg.Msg.fromBuffer(payloadBytes);
    } catch (e) {
      if (e is UspException) rethrow;
      throw UspException(7000, "Failed to parse USP Record: $e");
    }
  }

  /// Peeks at the header of a binary [pb_record.Record] without unwrapping the payload.
  pb_record.Record peekHeader(List<int> recordBytes) {
    return pb_record.Record.fromBuffer(recordBytes);
  }
}
