import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspProtobufConverter - GetSupportedDM', () {
    final converter = UspProtobufConverter();
    final msgId = "test-id";

    test('Request Round Trip', () {
      // Arrange
      final dto = UspGetSupportedDMRequest(
        [UspPath.parse('Device.WiFi.')],
        firstLevelOnly: true,
        returnCommands: false,
      );

      // Act: DTO -> Proto -> DTO
      final msg = converter.toProto(dto, msgId: msgId);
      final decodedDto = converter.fromProto(msg) as UspGetSupportedDMRequest;

      // Assert
      expect(decodedDto.objPaths.first.fullPath, 'Device.WiFi');
      expect(decodedDto.objPaths.first, UspPath.parse('Device.WiFi'));
      expect(decodedDto.firstLevelOnly, true);
      expect(decodedDto.returnCommands, false);
      expect(decodedDto.returnParams, true); // default
    });
  });
}
