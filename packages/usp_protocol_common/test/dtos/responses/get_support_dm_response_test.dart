import 'package:test/test.dart';
import 'package:usp_protocol_common/usp_protocol_common.dart';
import 'package:usp_protocol_common/src/generated/usp_msg.pb.dart' as pb;

void main() {
  group('UspProtobufConverter - GetSupportedDM', () {
    final converter = UspProtobufConverter();
    final msgId = "test-id";

    test('Response Round Trip with Complex Structure', () {
      // Arrange
      final paramDef = UspParamDefinition(
        name: 'Channel',
        type: UspValueType.unsignedInt,
        isWritable: true,
        constraints: UspParamConstraints(),
      );
      final commandDef = UspCommandDefinition(
        name: 'Reset',
        inputArgs: {},
        outputArgs: {},
      );

      final objDef = UspObjectDefinition(
        path: 'Device.WiFi.Radio.{i}.',
        isMultiInstance: true,
        access: 'ReadWrite', // Should map to OBJ_ADD_DELETE
        supportedParams: {'Channel': paramDef},
        supportedCommands: {'Reset': commandDef},
      );

      final dto = UspGetSupportedDMResponse({'Device.WiFi.Radio.{i}.': objDef});

      // Act: DTO -> Proto
      final msg = converter.toProto(dto, msgId: msgId);

      // Assert Proto Intermediate State (Enum Mapping Check)
      final protoObj = msg
          .body
          .response
          .getSupportedDmResp
          .reqObjResults[0]
          .supportedObjs[0];
      expect(
        protoObj.access,
        pb.GetSupportedDMResp_ObjAccessType.OBJ_ADD_DELETE,
      );
      expect(
        protoObj.supportedParams[0].valueType,
        pb.GetSupportedDMResp_ParamValueType.PARAM_UNSIGNED_INT,
      );

      // Act: Proto -> DTO
      final decodedDto = converter.fromProto(msg) as UspGetSupportedDMResponse;
      final decodedObj = decodedDto.results['Device.WiFi.Radio.{i}.']!;

      // Assert Final DTO
      expect(decodedObj.isMultiInstance, true);
      expect(decodedObj.access, 'ReadWrite'); // Reverse mapping check

      final decodedParam = decodedObj.supportedParams['Channel']!;
      expect(decodedParam.type, UspValueType.unsignedInt);
      expect(decodedParam.isWritable, true);

      expect(decodedObj.supportedCommands.containsKey('Reset'), true);
    });
  });
}
