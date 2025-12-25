// This is a generated file - do not edit.
//
// Generated from usp_record.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use recordDescriptor instead')
const Record$json = {
  '1': 'Record',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 9, '10': 'version'},
    {'1': 'to_id', '3': 2, '4': 1, '5': 9, '10': 'toId'},
    {'1': 'from_id', '3': 3, '4': 1, '5': 9, '10': 'fromId'},
    {
      '1': 'payload_security',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.usp_record.Record.PayloadSecurity',
      '10': 'payloadSecurity'
    },
    {'1': 'mac_signature', '3': 5, '4': 1, '5': 12, '10': 'macSignature'},
    {'1': 'sender_cert', '3': 6, '4': 1, '5': 12, '10': 'senderCert'},
    {
      '1': 'no_session_context',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.usp_record.NoSessionContextRecord',
      '9': 0,
      '10': 'noSessionContext'
    },
    {
      '1': 'session_context',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.usp_record.SessionContextRecord',
      '9': 0,
      '10': 'sessionContext'
    },
    {
      '1': 'websocket_connect',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.usp_record.WebSocketConnectRecord',
      '9': 0,
      '10': 'websocketConnect'
    },
    {
      '1': 'mqtt_connect',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.usp_record.MQTTConnectRecord',
      '9': 0,
      '10': 'mqttConnect'
    },
    {
      '1': 'stomp_connect',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.usp_record.STOMPConnectRecord',
      '9': 0,
      '10': 'stompConnect'
    },
    {
      '1': 'disconnect',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.usp_record.DisconnectRecord',
      '9': 0,
      '10': 'disconnect'
    },
    {
      '1': 'uds_connect',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.usp_record.UDSConnectRecord',
      '9': 0,
      '10': 'udsConnect'
    },
  ],
  '4': [Record_PayloadSecurity$json],
  '8': [
    {'1': 'record_type'},
  ],
};

@$core.Deprecated('Use recordDescriptor instead')
const Record_PayloadSecurity$json = {
  '1': 'PayloadSecurity',
  '2': [
    {'1': 'PLAINTEXT', '2': 0},
    {'1': 'TLS12', '2': 1},
  ],
};

/// Descriptor for `Record`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recordDescriptor = $convert.base64Decode(
    'CgZSZWNvcmQSGAoHdmVyc2lvbhgBIAEoCVIHdmVyc2lvbhITCgV0b19pZBgCIAEoCVIEdG9JZB'
    'IXCgdmcm9tX2lkGAMgASgJUgZmcm9tSWQSTQoQcGF5bG9hZF9zZWN1cml0eRgEIAEoDjIiLnVz'
    'cF9yZWNvcmQuUmVjb3JkLlBheWxvYWRTZWN1cml0eVIPcGF5bG9hZFNlY3VyaXR5EiMKDW1hY1'
    '9zaWduYXR1cmUYBSABKAxSDG1hY1NpZ25hdHVyZRIfCgtzZW5kZXJfY2VydBgGIAEoDFIKc2Vu'
    'ZGVyQ2VydBJSChJub19zZXNzaW9uX2NvbnRleHQYByABKAsyIi51c3BfcmVjb3JkLk5vU2Vzc2'
    'lvbkNvbnRleHRSZWNvcmRIAFIQbm9TZXNzaW9uQ29udGV4dBJLCg9zZXNzaW9uX2NvbnRleHQY'
    'CCABKAsyIC51c3BfcmVjb3JkLlNlc3Npb25Db250ZXh0UmVjb3JkSABSDnNlc3Npb25Db250ZX'
    'h0ElEKEXdlYnNvY2tldF9jb25uZWN0GAkgASgLMiIudXNwX3JlY29yZC5XZWJTb2NrZXRDb25u'
    'ZWN0UmVjb3JkSABSEHdlYnNvY2tldENvbm5lY3QSQgoMbXF0dF9jb25uZWN0GAogASgLMh0udX'
    'NwX3JlY29yZC5NUVRUQ29ubmVjdFJlY29yZEgAUgttcXR0Q29ubmVjdBJFCg1zdG9tcF9jb25u'
    'ZWN0GAsgASgLMh4udXNwX3JlY29yZC5TVE9NUENvbm5lY3RSZWNvcmRIAFIMc3RvbXBDb25uZW'
    'N0Ej4KCmRpc2Nvbm5lY3QYDCABKAsyHC51c3BfcmVjb3JkLkRpc2Nvbm5lY3RSZWNvcmRIAFIK'
    'ZGlzY29ubmVjdBI/Cgt1ZHNfY29ubmVjdBgNIAEoCzIcLnVzcF9yZWNvcmQuVURTQ29ubmVjdF'
    'JlY29yZEgAUgp1ZHNDb25uZWN0IisKD1BheWxvYWRTZWN1cml0eRINCglQTEFJTlRFWFQQABIJ'
    'CgVUTFMxMhABQg0KC3JlY29yZF90eXBl');

@$core.Deprecated('Use noSessionContextRecordDescriptor instead')
const NoSessionContextRecord$json = {
  '1': 'NoSessionContextRecord',
  '2': [
    {'1': 'payload', '3': 2, '4': 1, '5': 12, '10': 'payload'},
  ],
};

/// Descriptor for `NoSessionContextRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List noSessionContextRecordDescriptor =
    $convert.base64Decode(
        'ChZOb1Nlc3Npb25Db250ZXh0UmVjb3JkEhgKB3BheWxvYWQYAiABKAxSB3BheWxvYWQ=');

@$core.Deprecated('Use sessionContextRecordDescriptor instead')
const SessionContextRecord$json = {
  '1': 'SessionContextRecord',
  '2': [
    {'1': 'session_id', '3': 1, '4': 1, '5': 4, '10': 'sessionId'},
    {'1': 'sequence_id', '3': 2, '4': 1, '5': 4, '10': 'sequenceId'},
    {'1': 'expected_id', '3': 3, '4': 1, '5': 4, '10': 'expectedId'},
    {'1': 'retransmit_id', '3': 4, '4': 1, '5': 4, '10': 'retransmitId'},
    {
      '1': 'payload_sar_state',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.usp_record.SessionContextRecord.PayloadSARState',
      '10': 'payloadSarState'
    },
    {
      '1': 'payloadrec_sar_state',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.usp_record.SessionContextRecord.PayloadSARState',
      '10': 'payloadrecSarState'
    },
    {'1': 'payload', '3': 7, '4': 3, '5': 12, '10': 'payload'},
  ],
  '4': [SessionContextRecord_PayloadSARState$json],
};

@$core.Deprecated('Use sessionContextRecordDescriptor instead')
const SessionContextRecord_PayloadSARState$json = {
  '1': 'PayloadSARState',
  '2': [
    {'1': 'NONE', '2': 0},
    {'1': 'BEGIN', '2': 1},
    {'1': 'INPROCESS', '2': 2},
    {'1': 'COMPLETE', '2': 3},
  ],
};

/// Descriptor for `SessionContextRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionContextRecordDescriptor = $convert.base64Decode(
    'ChRTZXNzaW9uQ29udGV4dFJlY29yZBIdCgpzZXNzaW9uX2lkGAEgASgEUglzZXNzaW9uSWQSHw'
    'oLc2VxdWVuY2VfaWQYAiABKARSCnNlcXVlbmNlSWQSHwoLZXhwZWN0ZWRfaWQYAyABKARSCmV4'
    'cGVjdGVkSWQSIwoNcmV0cmFuc21pdF9pZBgEIAEoBFIMcmV0cmFuc21pdElkElwKEXBheWxvYW'
    'Rfc2FyX3N0YXRlGAUgASgOMjAudXNwX3JlY29yZC5TZXNzaW9uQ29udGV4dFJlY29yZC5QYXls'
    'b2FkU0FSU3RhdGVSD3BheWxvYWRTYXJTdGF0ZRJiChRwYXlsb2FkcmVjX3Nhcl9zdGF0ZRgGIA'
    'EoDjIwLnVzcF9yZWNvcmQuU2Vzc2lvbkNvbnRleHRSZWNvcmQuUGF5bG9hZFNBUlN0YXRlUhJw'
    'YXlsb2FkcmVjU2FyU3RhdGUSGAoHcGF5bG9hZBgHIAMoDFIHcGF5bG9hZCJDCg9QYXlsb2FkU0'
    'FSU3RhdGUSCAoETk9ORRAAEgkKBUJFR0lOEAESDQoJSU5QUk9DRVNTEAISDAoIQ09NUExFVEUQ'
    'Aw==');

@$core.Deprecated('Use webSocketConnectRecordDescriptor instead')
const WebSocketConnectRecord$json = {
  '1': 'WebSocketConnectRecord',
};

/// Descriptor for `WebSocketConnectRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List webSocketConnectRecordDescriptor =
    $convert.base64Decode('ChZXZWJTb2NrZXRDb25uZWN0UmVjb3Jk');

@$core.Deprecated('Use mQTTConnectRecordDescriptor instead')
const MQTTConnectRecord$json = {
  '1': 'MQTTConnectRecord',
  '2': [
    {
      '1': 'version',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.usp_record.MQTTConnectRecord.MQTTVersion',
      '10': 'version'
    },
    {'1': 'subscribed_topic', '3': 2, '4': 1, '5': 9, '10': 'subscribedTopic'},
  ],
  '4': [MQTTConnectRecord_MQTTVersion$json],
};

@$core.Deprecated('Use mQTTConnectRecordDescriptor instead')
const MQTTConnectRecord_MQTTVersion$json = {
  '1': 'MQTTVersion',
  '2': [
    {'1': 'V3_1_1', '2': 0},
    {'1': 'V5', '2': 1},
  ],
};

/// Descriptor for `MQTTConnectRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mQTTConnectRecordDescriptor = $convert.base64Decode(
    'ChFNUVRUQ29ubmVjdFJlY29yZBJDCgd2ZXJzaW9uGAEgASgOMikudXNwX3JlY29yZC5NUVRUQ2'
    '9ubmVjdFJlY29yZC5NUVRUVmVyc2lvblIHdmVyc2lvbhIpChBzdWJzY3JpYmVkX3RvcGljGAIg'
    'ASgJUg9zdWJzY3JpYmVkVG9waWMiIQoLTVFUVFZlcnNpb24SCgoGVjNfMV8xEAASBgoCVjUQAQ'
    '==');

@$core.Deprecated('Use sTOMPConnectRecordDescriptor instead')
const STOMPConnectRecord$json = {
  '1': 'STOMPConnectRecord',
  '2': [
    {
      '1': 'version',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.usp_record.STOMPConnectRecord.STOMPVersion',
      '10': 'version'
    },
    {
      '1': 'subscribed_destination',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'subscribedDestination'
    },
  ],
  '4': [STOMPConnectRecord_STOMPVersion$json],
};

@$core.Deprecated('Use sTOMPConnectRecordDescriptor instead')
const STOMPConnectRecord_STOMPVersion$json = {
  '1': 'STOMPVersion',
  '2': [
    {'1': 'V1_2', '2': 0},
  ],
};

/// Descriptor for `STOMPConnectRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sTOMPConnectRecordDescriptor = $convert.base64Decode(
    'ChJTVE9NUENvbm5lY3RSZWNvcmQSRQoHdmVyc2lvbhgBIAEoDjIrLnVzcF9yZWNvcmQuU1RPTV'
    'BDb25uZWN0UmVjb3JkLlNUT01QVmVyc2lvblIHdmVyc2lvbhI1ChZzdWJzY3JpYmVkX2Rlc3Rp'
    'bmF0aW9uGAIgASgJUhVzdWJzY3JpYmVkRGVzdGluYXRpb24iGAoMU1RPTVBWZXJzaW9uEggKBF'
    'YxXzIQAA==');

@$core.Deprecated('Use uDSConnectRecordDescriptor instead')
const UDSConnectRecord$json = {
  '1': 'UDSConnectRecord',
};

/// Descriptor for `UDSConnectRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uDSConnectRecordDescriptor =
    $convert.base64Decode('ChBVRFNDb25uZWN0UmVjb3Jk');

@$core.Deprecated('Use disconnectRecordDescriptor instead')
const DisconnectRecord$json = {
  '1': 'DisconnectRecord',
  '2': [
    {'1': 'reason', '3': 1, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'reason_code', '3': 2, '4': 1, '5': 7, '10': 'reasonCode'},
  ],
};

/// Descriptor for `DisconnectRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disconnectRecordDescriptor = $convert.base64Decode(
    'ChBEaXNjb25uZWN0UmVjb3JkEhYKBnJlYXNvbhgBIAEoCVIGcmVhc29uEh8KC3JlYXNvbl9jb2'
    'RlGAIgASgHUgpyZWFzb25Db2Rl');
