import 'package:test/test.dart';
import 'package:usp_protocol_common/src/generated/usp_msg.pb.dart' as pb;
import 'package:usp_protocol_common/usp_protocol_common.dart';

void main() {
  group('UspProtobufConverter', () {
    final converter = UspProtobufConverter();
    const msgId = 'test-id';

    void testRoundTrip(String description, UspMessage originalDto) {
      test(description, () {
        // DTO -> Proto -> DTO
        final protoMsg = converter.toProto(originalDto, msgId: msgId);
        final convertedDto = converter.fromProto(protoMsg);

        // Assert
        expect(convertedDto, equals(originalDto));
      });
    }

    group('Get', () {
      final dto = UspGetRequest([UspPath.parse('Device.DeviceInfo.')]);
      testRoundTrip('should correctly round-trip UspGetRequest', dto);
    });

    group('GetResponse', () {
      final dto = UspGetResponse({
        UspPath.parse('Device.DeviceInfo.SerialNumber'): UspValue(
          '12345',
          UspValueType.string,
        ),
      });
      testRoundTrip('should correctly round-trip UspGetResponse', dto);
    });

    group('Set', () {
      final dto = UspSetRequest({
        UspPath.parse('Device.WiFi.SSID'): UspValue(
          'MyWiFi',
          UspValueType.string,
        ),
      }, allowPartial: true);
      testRoundTrip('should correctly round-trip UspSetRequest', dto);
    });

    group('SetResponse', () {
      final dto = UspSetResponse(
        successPaths: [UspPath.parse('Device.WiFi.SSID')],
        failurePaths: {
          UspPath.parse('Device.WiFi.Password'): UspException(
            9007,
            'Invalid Value',
          ),
        },
      );
      testRoundTrip('should correctly round-trip UspSetResponse', dto);
    });

    group('Add', () {
      final dto = UspAddRequest([
        UspObjectCreation(
          UspPath.parse('Device.History.1.'),
          parameters: {'Name': UspValue('New', UspValueType.string)},
        ),
      ]);
      testRoundTrip('should correctly round-trip UspAddRequest', dto);
    });

    group('AddResponse', () {
      final dto = UspAddResponse(
        createdObjects: [UspCreatedObject(UspPath.parse('Device.History.1.2'))],
        errors: [UspException(9000, 'Failed')],
      );
      testRoundTrip('should correctly round-trip UspAddResponse', dto);
    });

    group('Delete', () {
      final dto = UspDeleteRequest([
        UspPath.parse('Device.History.1.2'),
      ], allowPartial: true);
      testRoundTrip('should correctly round-trip UspDeleteRequest', dto);
    });

    group('DeleteResponse', () {
      final dto = UspDeleteResponse(
        deletedPaths: [UspPath.parse('Device.History.1.2')],
        errors: [UspException(9000, 'Failed')],
      );
      testRoundTrip('should correctly round-trip UspDeleteResponse', dto);
    });

    group('Operate', () {
      final dto = UspOperateRequest(
        command: UspPath.parse('Device.Reboot()'),
        inputArgs: {'delay': UspValue('10', UspValueType.string)},
      );
      // This test is expected to fail until Operate is implemented in the converter
      testRoundTrip('should correctly round-trip UspOperateRequest', dto);
    });

    group('OperateResponse', () {
      final dto = UspOperateResponse(
        outputArgs: {'status': UspValue('OK', UspValueType.string)},
      );
      testRoundTrip('should correctly round-trip UspOperateResponse', dto);
    });

    group('Notify', () {
      testRoundTrip(
        'should correctly round-trip UspValueChangeNotify',
        UspValueChangeNotify(
          paramPath: UspPath.parse('Device.WiFi.SSID'),
          paramValue: 'NewNetwork',
          subscriptionId: 'sub1',
          sendResp: true,
        ),
      );

      testRoundTrip(
        'should correctly round-trip UspObjectCreationNotify',
        UspObjectCreationNotify(
          objPath: UspPath.parse('Device.Hosts.Host.1'),
          uniqueKeys: {'ID': '1', 'MAC': 'AA:BB:CC:DD:EE:FF'},
          subscriptionId: 'sub2',
          sendResp: false,
        ),
      );

      testRoundTrip(
        'should correctly round-trip UspObjectDeletionNotify',
        UspObjectDeletionNotify(
          objPath: UspPath.parse('Device.Hosts.Host.1'),
          subscriptionId: 'sub3',
          sendResp: true,
        ),
      );

      testRoundTrip(
        'should correctly round-trip UspOperationCompleteNotify (success)',
        UspOperationCompleteNotify(
          objPath: UspPath.parse('Device.LocalAgent.'),
          commandName: 'Reboot',
          commandKey: 'cmd123',
          outputArgs: {'status': 'Success', 'uptime': '123'},
          subscriptionId: 'sub4',
          sendResp: true,
        ),
      );

      testRoundTrip(
        'should correctly round-trip UspOperationCompleteNotify (failure)',
        UspOperationCompleteNotify(
          objPath: UspPath.parse('Device.LocalAgent.'),
          commandName: 'Reboot',
          commandKey: 'cmd123',
          commandFailure: UspException(7000, 'Device offline'),
          subscriptionId: 'sub5',
          sendResp: true,
        ),
      );

      testRoundTrip(
        'should correctly round-trip UspOnBoardRequestNotify',
        UspOnBoardRequestNotify(
          oui: 'ABCDEF',
          productClass: 'MyProduct',
          serialNumber: '123456789',
          agentProtocolVersions: '1.0',
          sendResp: true,
        ),
      );

      testRoundTrip(
        'should correctly round-trip UspNotifyResponse',
        UspNotifyResponse(subscriptionId: 'sub123'),
      );
    });

    group('Error', () {
      final dto = UspErrorResponse(UspException(7000, 'Internal Error'));
      testRoundTrip('should correctly round-trip UspErrorResponse', dto);
    });
  });

  group('UspProtobufConverter - Capability & Instance Discovery', () {
    final converter = UspProtobufConverter();
    const msgId = "test-cap-id";

    // --- 1. GetSupportedDM (Metadata Test) ----------------------------------

    test('1.1 Request Round Trip (DTO -> Proto -> DTO)', () {
      // Arrange
      final requestDto = UspGetSupportedDMRequest(
        [UspPath.parse('Device.Time.'), UspPath.parse('Device.WiFi.Radio.')],
        firstLevelOnly: true,
        returnCommands: false,
      );

      // Act
      final msg = converter.toProto(requestDto, msgId: msgId);
      final decodedDto = converter.fromProto(msg) as UspGetSupportedDMRequest;

      // Assert
      expect(decodedDto.objPaths.length, 2);
      // 驗證路徑已被 UspPath 標準化 (移除尾部點)
      expect(decodedDto.objPaths.first.fullPath, 'Device.Time');
      expect(decodedDto.firstLevelOnly, isTrue);
      expect(decodedDto.returnCommands, isFalse);
    });

    test('1.2 Response Round Trip (Deep Structure & Enum Mapping)', () {
      // Arrange
      final paramDef = UspParamDefinition(
        name: 'Channel',
        type: UspValueType.unsignedInt,
        isWritable: true,
        constraints: UspParamConstraints(),
      );
      final commandDef = UspCommandDefinition(
        name: 'Reset',
        inputArgs: {
          'ResetType': UspArgumentDefinition(
            name: 'ResetType',
            type: UspValueType.string,
          ),
        },
        outputArgs: {
          'Result': UspArgumentDefinition(
            name: 'Result',
            type: UspValueType.string,
          ),
        },
      );

      final objDef = UspObjectDefinition(
        path: 'Device.WiFi.Radio.{i}.',
        isMultiInstance: true,
        access: 'ReadWrite', // Maps to OBJ_ADD_DELETE (Lifecycle Access)
        supportedParams: {'Channel': paramDef},
        supportedCommands: {'Reset': commandDef},
      );

      final responseDto = UspGetSupportedDMResponse({
        'Device.WiFi.Radio.{i}.': objDef,
      });

      // Act: DTO -> Proto (Ensures Enum Mapping is Correct)
      final msg = converter.toProto(responseDto, msgId: msgId);
      final protoObj = msg
          .body
          .response
          .getSupportedDmResp
          .reqObjResults[0]
          .supportedObjs[0];

      // Assert Intermediate State
      expect(
        protoObj.access,
        pb.GetSupportedDMResp_ObjAccessType.OBJ_ADD_DELETE,
      ); // ReadWrite -> ADD_DELETE
      expect(
        protoObj.supportedParams[0].valueType,
        pb.GetSupportedDMResp_ParamValueType.PARAM_UNSIGNED_INT,
      );

      // Act: Proto -> DTO (Round Trip)
      final decodedDto = converter.fromProto(msg) as UspGetSupportedDMResponse;
      final decodedObj = decodedDto.results['Device.WiFi.Radio.{i}.']!;

      // Assert Final DTO Integrity
      expect(decodedObj.isMultiInstance, true);
      expect(decodedObj.access, 'ReadWrite'); // Reverse mapping check
      final resetCmd = decodedObj.supportedCommands['Reset']!;

      expect(resetCmd.inputArgs.containsKey('ResetType'), isTrue);
      expect(resetCmd.inputArgs['ResetType']!.type, UspValueType.string);
      final decodedParam = decodedObj.supportedParams['Channel']!;
      expect(decodedParam.type, UspValueType.unsignedInt);
      expect(decodedParam.isWritable, true);
    });

    // --- 2. GetInstances (Instance Discovery Test) ----------------------------

    test('2.1 Request Round Trip (DTO -> Proto -> DTO)', () {
      // Arrange
      final requestDto = UspGetInstancesRequest([
        UspPath.parse('Device.IP.Interface.'),
      ], firstLevelOnly: false);

      // Act
      final msg = converter.toProto(requestDto, msgId: msgId);
      final decodedDto = converter.fromProto(msg) as UspGetInstancesRequest;

      // Assert Final DTO
      expect(decodedDto.objPaths.length, 1);
      // 驗證 Path Normalization
      expect(decodedDto.objPaths.first.fullPath, 'Device.IP.Interface');
      expect(decodedDto.firstLevelOnly, false);
    });

    test('2.2 Response Round Trip (Instance & Unique Keys)', () {
      // Arrange
      final instance1 = const UspInstanceResult(
        'Device.WiFi.Radio.1',
        uniqueKeys: {'ID': '1', 'Alias': '2.4G'},
      );
      final instance2 = const UspInstanceResult(
        'Device.WiFi.Radio.2',
        uniqueKeys: {'ID': '2'},
      );

      final responseDto = UspGetInstancesResponse({
        'Device.WiFi.Radio.': [instance1, instance2],
        'Device.IP.Interface.': [
          const UspInstanceResult('Device.IP.Interface.1', uniqueKeys: {}),
        ],
      });

      // Act
      final msg = converter.toProto(responseDto, msgId: msgId);
      final decodedDto = converter.fromProto(msg) as UspGetInstancesResponse;

      // Assert Final DTO Integrity
      expect(decodedDto.results.length, 2);

      final decodedRadioList = decodedDto.results['Device.WiFi.Radio.']!;
      expect(decodedRadioList.length, 2);

      // Check Instance 1 details
      expect(decodedRadioList[0].instantiatedPath, 'Device.WiFi.Radio.1');
      expect(
        decodedRadioList[0].uniqueKeys,
        containsPair('Alias', '2.4G'),
      ); // Checks map transfer

      // Check Instance 2 details
      expect(decodedRadioList[1].instantiatedPath, 'Device.WiFi.Radio.2');
      expect(decodedRadioList[1].uniqueKeys, {'ID': '2'});
    });
  });

  group('UspProtobufConverter - GetInstances', () {
    final converter = UspProtobufConverter();
    const msgId = "test-get-instances-id";

    // ----------------------------------------------------------------
    // 1. Request Test
    // ----------------------------------------------------------------
    test('Request Round Trip (DTO -> Proto -> DTO)', () {
      // Arrange
      final requestDto = UspGetInstancesRequest([
        UspPath.parse('Device.WiFi.Radio.'),
        UspPath.parse('Device.IP.Interface.'),
      ], firstLevelOnly: true);

      // Act: DTO -> Proto
      final protoMsg = converter.toProto(requestDto, msgId: msgId);

      // Assert Proto Structure
      expect(protoMsg.header.msgType, pb.Header_MsgType.GET_INSTANCES);
      expect(
        protoMsg.body.request.getInstances.objPaths,
        containsAll(['Device.WiFi.Radio', 'Device.IP.Interface']),
      );
      expect(protoMsg.body.request.getInstances.firstLevelOnly, isTrue);

      // Act: Proto -> DTO
      final decodedDto =
          converter.fromProto(protoMsg) as UspGetInstancesRequest;

      // Assert Final DTO
      expect(decodedDto.objPaths.length, 2);
      expect(decodedDto.objPaths[0].fullPath, 'Device.WiFi.Radio');
      expect(decodedDto.firstLevelOnly, true);
    });

    // ----------------------------------------------------------------
    // 2. Response Test (Complex Structure)
    // ----------------------------------------------------------------
    test('Response Round Trip (DTO -> Proto -> DTO)', () {
      // Arrange
      // 模擬查詢 Device.WiFi.Radio. 回傳了兩個實例
      final radioInstances = [
        const UspInstanceResult(
          'Device.WiFi.Radio.1',
          uniqueKeys: {'Name': 'Radio2.4G', 'Alias': 'cpe-1'},
        ),
        const UspInstanceResult(
          'Device.WiFi.Radio.2',
          uniqueKeys: {'Name': 'Radio5G'}, // 只有一個 key
        ),
      ];

      // 模擬查詢 Device.IP.Interface. 回傳了一個實例
      final ipInstances = [
        const UspInstanceResult(
          'Device.IP.Interface.1',
          uniqueKeys: {}, // 沒有 unique keys
        ),
      ];

      final responseDto = UspGetInstancesResponse({
        'Device.WiFi.Radio.': radioInstances,
        'Device.IP.Interface.': ipInstances,
      });

      // Act: DTO -> Proto
      final protoMsg = converter.toProto(responseDto, msgId: msgId);

      // Assert Proto Structure
      expect(protoMsg.header.msgType, pb.Header_MsgType.GET_INSTANCES_RESP);
      final reqPathResults =
          protoMsg.body.response.getInstancesResp.reqPathResults;
      expect(reqPathResults.length, 2);

      // 檢查其中一個結果 (WiFi)
      final wifiResult = reqPathResults.firstWhere(
        (r) => r.requestedPath == 'Device.WiFi.Radio.',
      );
      expect(wifiResult.currInsts.length, 2);
      expect(
        wifiResult.currInsts[0].instantiatedObjPath,
        'Device.WiFi.Radio.1',
      );
      expect(wifiResult.currInsts[0].uniqueKeys['Name'], 'Radio2.4G');

      // Act: Proto -> DTO
      final decodedDto =
          converter.fromProto(protoMsg) as UspGetInstancesResponse;

      // Assert Final DTO
      expect(decodedDto.results.length, 2);

      // 驗證 Radio 1
      final decodedRadio1 = decodedDto.results['Device.WiFi.Radio.']![0];
      expect(decodedRadio1.instantiatedPath, 'Device.WiFi.Radio.1');
      expect(decodedRadio1.uniqueKeys, {'Name': 'Radio2.4G', 'Alias': 'cpe-1'});

      // 驗證 Radio 2
      final decodedRadio2 = decodedDto.results['Device.WiFi.Radio.']![1];
      expect(decodedRadio2.instantiatedPath, 'Device.WiFi.Radio.2');
      expect(decodedRadio2.uniqueKeys, {'Name': 'Radio5G'});

      // 驗證 IP Interface (Empty keys)
      final decodedIp = decodedDto.results['Device.IP.Interface.']![0];
      expect(decodedIp.instantiatedPath, 'Device.IP.Interface.1');
      expect(decodedIp.uniqueKeys, isEmpty);
    });
  });
}
