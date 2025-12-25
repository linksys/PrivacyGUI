// This is a generated file - do not edit.
//
// Generated from usp_msg.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use msgDescriptor instead')
const Msg$json = {
  '1': 'Msg',
  '2': [
    {
      '1': 'header',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.usp.Header',
      '10': 'header'
    },
    {'1': 'body', '3': 2, '4': 1, '5': 11, '6': '.usp.Body', '10': 'body'},
  ],
};

/// Descriptor for `Msg`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List msgDescriptor = $convert.base64Decode(
    'CgNNc2cSIwoGaGVhZGVyGAEgASgLMgsudXNwLkhlYWRlclIGaGVhZGVyEh0KBGJvZHkYAiABKA'
    'syCS51c3AuQm9keVIEYm9keQ==');

@$core.Deprecated('Use headerDescriptor instead')
const Header$json = {
  '1': 'Header',
  '2': [
    {'1': 'msg_id', '3': 1, '4': 1, '5': 9, '10': 'msgId'},
    {
      '1': 'msg_type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.usp.Header.MsgType',
      '10': 'msgType'
    },
  ],
  '4': [Header_MsgType$json],
};

@$core.Deprecated('Use headerDescriptor instead')
const Header_MsgType$json = {
  '1': 'MsgType',
  '2': [
    {'1': 'ERROR', '2': 0},
    {'1': 'GET', '2': 1},
    {'1': 'GET_RESP', '2': 2},
    {'1': 'NOTIFY', '2': 3},
    {'1': 'SET', '2': 4},
    {'1': 'SET_RESP', '2': 5},
    {'1': 'OPERATE', '2': 6},
    {'1': 'OPERATE_RESP', '2': 7},
    {'1': 'ADD', '2': 8},
    {'1': 'ADD_RESP', '2': 9},
    {'1': 'DELETE', '2': 10},
    {'1': 'DELETE_RESP', '2': 11},
    {'1': 'GET_SUPPORTED_DM', '2': 12},
    {'1': 'GET_SUPPORTED_DM_RESP', '2': 13},
    {'1': 'GET_INSTANCES', '2': 14},
    {'1': 'GET_INSTANCES_RESP', '2': 15},
    {'1': 'NOTIFY_RESP', '2': 16},
    {'1': 'GET_SUPPORTED_PROTO', '2': 17},
    {'1': 'GET_SUPPORTED_PROTO_RESP', '2': 18},
    {'1': 'REGISTER', '2': 19},
    {'1': 'REGISTER_RESP', '2': 20},
    {'1': 'DEREGISTER', '2': 21},
    {'1': 'DEREGISTER_RESP', '2': 22},
  ],
};

/// Descriptor for `Header`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List headerDescriptor = $convert.base64Decode(
    'CgZIZWFkZXISFQoGbXNnX2lkGAEgASgJUgVtc2dJZBIuCghtc2dfdHlwZRgCIAEoDjITLnVzcC'
    '5IZWFkZXIuTXNnVHlwZVIHbXNnVHlwZSKLAwoHTXNnVHlwZRIJCgVFUlJPUhAAEgcKA0dFVBAB'
    'EgwKCEdFVF9SRVNQEAISCgoGTk9USUZZEAMSBwoDU0VUEAQSDAoIU0VUX1JFU1AQBRILCgdPUE'
    'VSQVRFEAYSEAoMT1BFUkFURV9SRVNQEAcSBwoDQUREEAgSDAoIQUREX1JFU1AQCRIKCgZERUxF'
    'VEUQChIPCgtERUxFVEVfUkVTUBALEhQKEEdFVF9TVVBQT1JURURfRE0QDBIZChVHRVRfU1VQUE'
    '9SVEVEX0RNX1JFU1AQDRIRCg1HRVRfSU5TVEFOQ0VTEA4SFgoSR0VUX0lOU1RBTkNFU19SRVNQ'
    'EA8SDwoLTk9USUZZX1JFU1AQEBIXChNHRVRfU1VQUE9SVEVEX1BST1RPEBESHAoYR0VUX1NVUF'
    'BPUlRFRF9QUk9UT19SRVNQEBISDAoIUkVHSVNURVIQExIRCg1SRUdJU1RFUl9SRVNQEBQSDgoK'
    'REVSRUdJU1RFUhAVEhMKD0RFUkVHSVNURVJfUkVTUBAW');

@$core.Deprecated('Use bodyDescriptor instead')
const Body$json = {
  '1': 'Body',
  '2': [
    {
      '1': 'request',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.usp.Request',
      '9': 0,
      '10': 'request'
    },
    {
      '1': 'response',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.usp.Response',
      '9': 0,
      '10': 'response'
    },
    {
      '1': 'error',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.usp.Error',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'msg_body'},
  ],
};

/// Descriptor for `Body`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bodyDescriptor = $convert.base64Decode(
    'CgRCb2R5EigKB3JlcXVlc3QYASABKAsyDC51c3AuUmVxdWVzdEgAUgdyZXF1ZXN0EisKCHJlc3'
    'BvbnNlGAIgASgLMg0udXNwLlJlc3BvbnNlSABSCHJlc3BvbnNlEiIKBWVycm9yGAMgASgLMgou'
    'dXNwLkVycm9ySABSBWVycm9yQgoKCG1zZ19ib2R5');

@$core.Deprecated('Use requestDescriptor instead')
const Request$json = {
  '1': 'Request',
  '2': [
    {'1': 'get', '3': 1, '4': 1, '5': 11, '6': '.usp.Get', '9': 0, '10': 'get'},
    {
      '1': 'get_supported_dm',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.usp.GetSupportedDM',
      '9': 0,
      '10': 'getSupportedDm'
    },
    {
      '1': 'get_instances',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.usp.GetInstances',
      '9': 0,
      '10': 'getInstances'
    },
    {'1': 'set', '3': 4, '4': 1, '5': 11, '6': '.usp.Set', '9': 0, '10': 'set'},
    {'1': 'add', '3': 5, '4': 1, '5': 11, '6': '.usp.Add', '9': 0, '10': 'add'},
    {
      '1': 'delete',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.usp.Delete',
      '9': 0,
      '10': 'delete'
    },
    {
      '1': 'operate',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.usp.Operate',
      '9': 0,
      '10': 'operate'
    },
    {
      '1': 'notify',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.usp.Notify',
      '9': 0,
      '10': 'notify'
    },
    {
      '1': 'get_supported_protocol',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.usp.GetSupportedProtocol',
      '9': 0,
      '10': 'getSupportedProtocol'
    },
    {
      '1': 'register',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.usp.Register',
      '9': 0,
      '10': 'register'
    },
    {
      '1': 'deregister',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.usp.Deregister',
      '9': 0,
      '10': 'deregister'
    },
  ],
  '8': [
    {'1': 'req_type'},
  ],
};

/// Descriptor for `Request`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestDescriptor = $convert.base64Decode(
    'CgdSZXF1ZXN0EhwKA2dldBgBIAEoCzIILnVzcC5HZXRIAFIDZ2V0Ej8KEGdldF9zdXBwb3J0ZW'
    'RfZG0YAiABKAsyEy51c3AuR2V0U3VwcG9ydGVkRE1IAFIOZ2V0U3VwcG9ydGVkRG0SOAoNZ2V0'
    'X2luc3RhbmNlcxgDIAEoCzIRLnVzcC5HZXRJbnN0YW5jZXNIAFIMZ2V0SW5zdGFuY2VzEhwKA3'
    'NldBgEIAEoCzIILnVzcC5TZXRIAFIDc2V0EhwKA2FkZBgFIAEoCzIILnVzcC5BZGRIAFIDYWRk'
    'EiUKBmRlbGV0ZRgGIAEoCzILLnVzcC5EZWxldGVIAFIGZGVsZXRlEigKB29wZXJhdGUYByABKA'
    'syDC51c3AuT3BlcmF0ZUgAUgdvcGVyYXRlEiUKBm5vdGlmeRgIIAEoCzILLnVzcC5Ob3RpZnlI'
    'AFIGbm90aWZ5ElEKFmdldF9zdXBwb3J0ZWRfcHJvdG9jb2wYCSABKAsyGS51c3AuR2V0U3VwcG'
    '9ydGVkUHJvdG9jb2xIAFIUZ2V0U3VwcG9ydGVkUHJvdG9jb2wSKwoIcmVnaXN0ZXIYCiABKAsy'
    'DS51c3AuUmVnaXN0ZXJIAFIIcmVnaXN0ZXISMQoKZGVyZWdpc3RlchgLIAEoCzIPLnVzcC5EZX'
    'JlZ2lzdGVySABSCmRlcmVnaXN0ZXJCCgoIcmVxX3R5cGU=');

@$core.Deprecated('Use responseDescriptor instead')
const Response$json = {
  '1': 'Response',
  '2': [
    {
      '1': 'get_resp',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.usp.GetResp',
      '9': 0,
      '10': 'getResp'
    },
    {
      '1': 'get_supported_dm_resp',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.usp.GetSupportedDMResp',
      '9': 0,
      '10': 'getSupportedDmResp'
    },
    {
      '1': 'get_instances_resp',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.usp.GetInstancesResp',
      '9': 0,
      '10': 'getInstancesResp'
    },
    {
      '1': 'set_resp',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.usp.SetResp',
      '9': 0,
      '10': 'setResp'
    },
    {
      '1': 'add_resp',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.usp.AddResp',
      '9': 0,
      '10': 'addResp'
    },
    {
      '1': 'delete_resp',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.usp.DeleteResp',
      '9': 0,
      '10': 'deleteResp'
    },
    {
      '1': 'operate_resp',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.usp.OperateResp',
      '9': 0,
      '10': 'operateResp'
    },
    {
      '1': 'notify_resp',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.usp.NotifyResp',
      '9': 0,
      '10': 'notifyResp'
    },
    {
      '1': 'get_supported_protocol_resp',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.usp.GetSupportedProtocolResp',
      '9': 0,
      '10': 'getSupportedProtocolResp'
    },
    {
      '1': 'register_resp',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.usp.RegisterResp',
      '9': 0,
      '10': 'registerResp'
    },
    {
      '1': 'deregister_resp',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.usp.DeregisterResp',
      '9': 0,
      '10': 'deregisterResp'
    },
  ],
  '8': [
    {'1': 'resp_type'},
  ],
};

/// Descriptor for `Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseDescriptor = $convert.base64Decode(
    'CghSZXNwb25zZRIpCghnZXRfcmVzcBgBIAEoCzIMLnVzcC5HZXRSZXNwSABSB2dldFJlc3ASTA'
    'oVZ2V0X3N1cHBvcnRlZF9kbV9yZXNwGAIgASgLMhcudXNwLkdldFN1cHBvcnRlZERNUmVzcEgA'
    'UhJnZXRTdXBwb3J0ZWREbVJlc3ASRQoSZ2V0X2luc3RhbmNlc19yZXNwGAMgASgLMhUudXNwLk'
    'dldEluc3RhbmNlc1Jlc3BIAFIQZ2V0SW5zdGFuY2VzUmVzcBIpCghzZXRfcmVzcBgEIAEoCzIM'
    'LnVzcC5TZXRSZXNwSABSB3NldFJlc3ASKQoIYWRkX3Jlc3AYBSABKAsyDC51c3AuQWRkUmVzcE'
    'gAUgdhZGRSZXNwEjIKC2RlbGV0ZV9yZXNwGAYgASgLMg8udXNwLkRlbGV0ZVJlc3BIAFIKZGVs'
    'ZXRlUmVzcBI1CgxvcGVyYXRlX3Jlc3AYByABKAsyEC51c3AuT3BlcmF0ZVJlc3BIAFILb3Blcm'
    'F0ZVJlc3ASMgoLbm90aWZ5X3Jlc3AYCCABKAsyDy51c3AuTm90aWZ5UmVzcEgAUgpub3RpZnlS'
    'ZXNwEl4KG2dldF9zdXBwb3J0ZWRfcHJvdG9jb2xfcmVzcBgJIAEoCzIdLnVzcC5HZXRTdXBwb3'
    'J0ZWRQcm90b2NvbFJlc3BIAFIYZ2V0U3VwcG9ydGVkUHJvdG9jb2xSZXNwEjgKDXJlZ2lzdGVy'
    'X3Jlc3AYCiABKAsyES51c3AuUmVnaXN0ZXJSZXNwSABSDHJlZ2lzdGVyUmVzcBI+Cg9kZXJlZ2'
    'lzdGVyX3Jlc3AYCyABKAsyEy51c3AuRGVyZWdpc3RlclJlc3BIAFIOZGVyZWdpc3RlclJlc3BC'
    'CwoJcmVzcF90eXBl');

@$core.Deprecated('Use errorDescriptor instead')
const Error$json = {
  '1': 'Error',
  '2': [
    {'1': 'err_code', '3': 1, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 2, '4': 1, '5': 9, '10': 'errMsg'},
    {
      '1': 'param_errs',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.usp.Error.ParamError',
      '10': 'paramErrs'
    },
  ],
  '3': [Error_ParamError$json],
};

@$core.Deprecated('Use errorDescriptor instead')
const Error_ParamError$json = {
  '1': 'ParamError',
  '2': [
    {'1': 'param_path', '3': 1, '4': 1, '5': 9, '10': 'paramPath'},
    {'1': 'err_code', '3': 2, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 3, '4': 1, '5': 9, '10': 'errMsg'},
  ],
};

/// Descriptor for `Error`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List errorDescriptor = $convert.base64Decode(
    'CgVFcnJvchIZCghlcnJfY29kZRgBIAEoB1IHZXJyQ29kZRIXCgdlcnJfbXNnGAIgASgJUgZlcn'
    'JNc2cSNAoKcGFyYW1fZXJycxgDIAMoCzIVLnVzcC5FcnJvci5QYXJhbUVycm9yUglwYXJhbUVy'
    'cnMaXwoKUGFyYW1FcnJvchIdCgpwYXJhbV9wYXRoGAEgASgJUglwYXJhbVBhdGgSGQoIZXJyX2'
    'NvZGUYAiABKAdSB2VyckNvZGUSFwoHZXJyX21zZxgDIAEoCVIGZXJyTXNn');

@$core.Deprecated('Use getDescriptor instead')
const Get$json = {
  '1': 'Get',
  '2': [
    {'1': 'param_paths', '3': 1, '4': 3, '5': 9, '10': 'paramPaths'},
    {'1': 'max_depth', '3': 2, '4': 1, '5': 7, '10': 'maxDepth'},
  ],
};

/// Descriptor for `Get`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getDescriptor = $convert.base64Decode(
    'CgNHZXQSHwoLcGFyYW1fcGF0aHMYASADKAlSCnBhcmFtUGF0aHMSGwoJbWF4X2RlcHRoGAIgAS'
    'gHUghtYXhEZXB0aA==');

@$core.Deprecated('Use getRespDescriptor instead')
const GetResp$json = {
  '1': 'GetResp',
  '2': [
    {
      '1': 'req_path_results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.usp.GetResp.RequestedPathResult',
      '10': 'reqPathResults'
    },
  ],
  '3': [GetResp_RequestedPathResult$json, GetResp_ResolvedPathResult$json],
};

@$core.Deprecated('Use getRespDescriptor instead')
const GetResp_RequestedPathResult$json = {
  '1': 'RequestedPathResult',
  '2': [
    {'1': 'requested_path', '3': 1, '4': 1, '5': 9, '10': 'requestedPath'},
    {'1': 'err_code', '3': 2, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 3, '4': 1, '5': 9, '10': 'errMsg'},
    {
      '1': 'resolved_path_results',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.usp.GetResp.ResolvedPathResult',
      '10': 'resolvedPathResults'
    },
  ],
};

@$core.Deprecated('Use getRespDescriptor instead')
const GetResp_ResolvedPathResult$json = {
  '1': 'ResolvedPathResult',
  '2': [
    {'1': 'resolved_path', '3': 1, '4': 1, '5': 9, '10': 'resolvedPath'},
    {
      '1': 'result_params',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.usp.GetResp.ResolvedPathResult.ResultParamsEntry',
      '10': 'resultParams'
    },
  ],
  '3': [GetResp_ResolvedPathResult_ResultParamsEntry$json],
};

@$core.Deprecated('Use getRespDescriptor instead')
const GetResp_ResolvedPathResult_ResultParamsEntry$json = {
  '1': 'ResultParamsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `GetResp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRespDescriptor = $convert.base64Decode(
    'CgdHZXRSZXNwEkoKEHJlcV9wYXRoX3Jlc3VsdHMYASADKAsyIC51c3AuR2V0UmVzcC5SZXF1ZX'
    'N0ZWRQYXRoUmVzdWx0Ug5yZXFQYXRoUmVzdWx0cxrFAQoTUmVxdWVzdGVkUGF0aFJlc3VsdBIl'
    'Cg5yZXF1ZXN0ZWRfcGF0aBgBIAEoCVINcmVxdWVzdGVkUGF0aBIZCghlcnJfY29kZRgCIAEoB1'
    'IHZXJyQ29kZRIXCgdlcnJfbXNnGAMgASgJUgZlcnJNc2cSUwoVcmVzb2x2ZWRfcGF0aF9yZXN1'
    'bHRzGAQgAygLMh8udXNwLkdldFJlc3AuUmVzb2x2ZWRQYXRoUmVzdWx0UhNyZXNvbHZlZFBhdG'
    'hSZXN1bHRzGtIBChJSZXNvbHZlZFBhdGhSZXN1bHQSIwoNcmVzb2x2ZWRfcGF0aBgBIAEoCVIM'
    'cmVzb2x2ZWRQYXRoElYKDXJlc3VsdF9wYXJhbXMYAiADKAsyMS51c3AuR2V0UmVzcC5SZXNvbH'
    'ZlZFBhdGhSZXN1bHQuUmVzdWx0UGFyYW1zRW50cnlSDHJlc3VsdFBhcmFtcxo/ChFSZXN1bHRQ'
    'YXJhbXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');

@$core.Deprecated('Use getSupportedDMDescriptor instead')
const GetSupportedDM$json = {
  '1': 'GetSupportedDM',
  '2': [
    {'1': 'obj_paths', '3': 1, '4': 3, '5': 9, '10': 'objPaths'},
    {'1': 'first_level_only', '3': 2, '4': 1, '5': 8, '10': 'firstLevelOnly'},
    {'1': 'return_commands', '3': 3, '4': 1, '5': 8, '10': 'returnCommands'},
    {'1': 'return_events', '3': 4, '4': 1, '5': 8, '10': 'returnEvents'},
    {'1': 'return_params', '3': 5, '4': 1, '5': 8, '10': 'returnParams'},
    {
      '1': 'return_unique_key_sets',
      '3': 6,
      '4': 1,
      '5': 8,
      '10': 'returnUniqueKeySets'
    },
  ],
};

/// Descriptor for `GetSupportedDM`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSupportedDMDescriptor = $convert.base64Decode(
    'Cg5HZXRTdXBwb3J0ZWRETRIbCglvYmpfcGF0aHMYASADKAlSCG9ialBhdGhzEigKEGZpcnN0X2'
    'xldmVsX29ubHkYAiABKAhSDmZpcnN0TGV2ZWxPbmx5EicKD3JldHVybl9jb21tYW5kcxgDIAEo'
    'CFIOcmV0dXJuQ29tbWFuZHMSIwoNcmV0dXJuX2V2ZW50cxgEIAEoCFIMcmV0dXJuRXZlbnRzEi'
    'MKDXJldHVybl9wYXJhbXMYBSABKAhSDHJldHVyblBhcmFtcxIzChZyZXR1cm5fdW5pcXVlX2tl'
    'eV9zZXRzGAYgASgIUhNyZXR1cm5VbmlxdWVLZXlTZXRz');

@$core.Deprecated('Use getSupportedDMRespDescriptor instead')
const GetSupportedDMResp$json = {
  '1': 'GetSupportedDMResp',
  '2': [
    {
      '1': 'req_obj_results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.usp.GetSupportedDMResp.RequestedObjectResult',
      '10': 'reqObjResults'
    },
  ],
  '3': [
    GetSupportedDMResp_RequestedObjectResult$json,
    GetSupportedDMResp_SupportedObjectResult$json,
    GetSupportedDMResp_SupportedParamResult$json,
    GetSupportedDMResp_SupportedCommandResult$json,
    GetSupportedDMResp_SupportedEventResult$json,
    GetSupportedDMResp_SupportedUniqueKeySet$json
  ],
  '4': [
    GetSupportedDMResp_ParamAccessType$json,
    GetSupportedDMResp_ObjAccessType$json,
    GetSupportedDMResp_ParamValueType$json,
    GetSupportedDMResp_ValueChangeType$json,
    GetSupportedDMResp_CmdType$json
  ],
};

@$core.Deprecated('Use getSupportedDMRespDescriptor instead')
const GetSupportedDMResp_RequestedObjectResult$json = {
  '1': 'RequestedObjectResult',
  '2': [
    {'1': 'req_obj_path', '3': 1, '4': 1, '5': 9, '10': 'reqObjPath'},
    {'1': 'err_code', '3': 2, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 3, '4': 1, '5': 9, '10': 'errMsg'},
    {
      '1': 'data_model_inst_uri',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'dataModelInstUri'
    },
    {
      '1': 'supported_objs',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.usp.GetSupportedDMResp.SupportedObjectResult',
      '10': 'supportedObjs'
    },
  ],
};

@$core.Deprecated('Use getSupportedDMRespDescriptor instead')
const GetSupportedDMResp_SupportedObjectResult$json = {
  '1': 'SupportedObjectResult',
  '2': [
    {
      '1': 'supported_obj_path',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'supportedObjPath'
    },
    {
      '1': 'access',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.usp.GetSupportedDMResp.ObjAccessType',
      '10': 'access'
    },
    {'1': 'is_multi_instance', '3': 3, '4': 1, '5': 8, '10': 'isMultiInstance'},
    {
      '1': 'supported_commands',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.usp.GetSupportedDMResp.SupportedCommandResult',
      '10': 'supportedCommands'
    },
    {
      '1': 'supported_events',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.usp.GetSupportedDMResp.SupportedEventResult',
      '10': 'supportedEvents'
    },
    {
      '1': 'supported_params',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.usp.GetSupportedDMResp.SupportedParamResult',
      '10': 'supportedParams'
    },
    {'1': 'divergent_paths', '3': 7, '4': 3, '5': 9, '10': 'divergentPaths'},
    {
      '1': 'unique_key_sets',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.usp.GetSupportedDMResp.SupportedUniqueKeySet',
      '10': 'uniqueKeySets'
    },
  ],
};

@$core.Deprecated('Use getSupportedDMRespDescriptor instead')
const GetSupportedDMResp_SupportedParamResult$json = {
  '1': 'SupportedParamResult',
  '2': [
    {'1': 'param_name', '3': 1, '4': 1, '5': 9, '10': 'paramName'},
    {
      '1': 'access',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.usp.GetSupportedDMResp.ParamAccessType',
      '10': 'access'
    },
    {
      '1': 'value_type',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.usp.GetSupportedDMResp.ParamValueType',
      '10': 'valueType'
    },
    {
      '1': 'value_change',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.usp.GetSupportedDMResp.ValueChangeType',
      '10': 'valueChange'
    },
  ],
};

@$core.Deprecated('Use getSupportedDMRespDescriptor instead')
const GetSupportedDMResp_SupportedCommandResult$json = {
  '1': 'SupportedCommandResult',
  '2': [
    {'1': 'command_name', '3': 1, '4': 1, '5': 9, '10': 'commandName'},
    {'1': 'input_arg_names', '3': 2, '4': 3, '5': 9, '10': 'inputArgNames'},
    {'1': 'output_arg_names', '3': 3, '4': 3, '5': 9, '10': 'outputArgNames'},
    {
      '1': 'command_type',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.usp.GetSupportedDMResp.CmdType',
      '10': 'commandType'
    },
  ],
};

@$core.Deprecated('Use getSupportedDMRespDescriptor instead')
const GetSupportedDMResp_SupportedEventResult$json = {
  '1': 'SupportedEventResult',
  '2': [
    {'1': 'event_name', '3': 1, '4': 1, '5': 9, '10': 'eventName'},
    {'1': 'arg_names', '3': 2, '4': 3, '5': 9, '10': 'argNames'},
  ],
};

@$core.Deprecated('Use getSupportedDMRespDescriptor instead')
const GetSupportedDMResp_SupportedUniqueKeySet$json = {
  '1': 'SupportedUniqueKeySet',
  '2': [
    {'1': 'key_names', '3': 1, '4': 3, '5': 9, '10': 'keyNames'},
  ],
};

@$core.Deprecated('Use getSupportedDMRespDescriptor instead')
const GetSupportedDMResp_ParamAccessType$json = {
  '1': 'ParamAccessType',
  '2': [
    {'1': 'PARAM_READ_ONLY', '2': 0},
    {'1': 'PARAM_READ_WRITE', '2': 1},
    {'1': 'PARAM_WRITE_ONLY', '2': 2},
  ],
};

@$core.Deprecated('Use getSupportedDMRespDescriptor instead')
const GetSupportedDMResp_ObjAccessType$json = {
  '1': 'ObjAccessType',
  '2': [
    {'1': 'OBJ_READ_ONLY', '2': 0},
    {'1': 'OBJ_ADD_DELETE', '2': 1},
    {'1': 'OBJ_ADD_ONLY', '2': 2},
    {'1': 'OBJ_DELETE_ONLY', '2': 3},
  ],
};

@$core.Deprecated('Use getSupportedDMRespDescriptor instead')
const GetSupportedDMResp_ParamValueType$json = {
  '1': 'ParamValueType',
  '2': [
    {'1': 'PARAM_UNKNOWN', '2': 0},
    {'1': 'PARAM_BASE_64', '2': 1},
    {'1': 'PARAM_BOOLEAN', '2': 2},
    {'1': 'PARAM_DATE_TIME', '2': 3},
    {'1': 'PARAM_DECIMAL', '2': 4},
    {'1': 'PARAM_HEX_BINARY', '2': 5},
    {'1': 'PARAM_INT', '2': 6},
    {'1': 'PARAM_LONG', '2': 7},
    {'1': 'PARAM_STRING', '2': 8},
    {'1': 'PARAM_UNSIGNED_INT', '2': 9},
    {'1': 'PARAM_UNSIGNED_LONG', '2': 10},
  ],
};

@$core.Deprecated('Use getSupportedDMRespDescriptor instead')
const GetSupportedDMResp_ValueChangeType$json = {
  '1': 'ValueChangeType',
  '2': [
    {'1': 'VALUE_CHANGE_UNKNOWN', '2': 0},
    {'1': 'VALUE_CHANGE_ALLOWED', '2': 1},
    {'1': 'VALUE_CHANGE_WILL_IGNORE', '2': 2},
  ],
};

@$core.Deprecated('Use getSupportedDMRespDescriptor instead')
const GetSupportedDMResp_CmdType$json = {
  '1': 'CmdType',
  '2': [
    {'1': 'CMD_UNKNOWN', '2': 0},
    {'1': 'CMD_SYNC', '2': 1},
    {'1': 'CMD_ASYNC', '2': 2},
  ],
};

/// Descriptor for `GetSupportedDMResp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSupportedDMRespDescriptor = $convert.base64Decode(
    'ChJHZXRTdXBwb3J0ZWRETVJlc3ASVQoPcmVxX29ial9yZXN1bHRzGAEgAygLMi0udXNwLkdldF'
    'N1cHBvcnRlZERNUmVzcC5SZXF1ZXN0ZWRPYmplY3RSZXN1bHRSDXJlcU9ialJlc3VsdHMa8gEK'
    'FVJlcXVlc3RlZE9iamVjdFJlc3VsdBIgCgxyZXFfb2JqX3BhdGgYASABKAlSCnJlcU9ialBhdG'
    'gSGQoIZXJyX2NvZGUYAiABKAdSB2VyckNvZGUSFwoHZXJyX21zZxgDIAEoCVIGZXJyTXNnEi0K'
    'E2RhdGFfbW9kZWxfaW5zdF91cmkYBCABKAlSEGRhdGFNb2RlbEluc3RVcmkSVAoOc3VwcG9ydG'
    'VkX29ianMYBSADKAsyLS51c3AuR2V0U3VwcG9ydGVkRE1SZXNwLlN1cHBvcnRlZE9iamVjdFJl'
    'c3VsdFINc3VwcG9ydGVkT2JqcxrBBAoVU3VwcG9ydGVkT2JqZWN0UmVzdWx0EiwKEnN1cHBvcn'
    'RlZF9vYmpfcGF0aBgBIAEoCVIQc3VwcG9ydGVkT2JqUGF0aBI9CgZhY2Nlc3MYAiABKA4yJS51'
    'c3AuR2V0U3VwcG9ydGVkRE1SZXNwLk9iakFjY2Vzc1R5cGVSBmFjY2VzcxIqChFpc19tdWx0aV'
    '9pbnN0YW5jZRgDIAEoCFIPaXNNdWx0aUluc3RhbmNlEl0KEnN1cHBvcnRlZF9jb21tYW5kcxgE'
    'IAMoCzIuLnVzcC5HZXRTdXBwb3J0ZWRETVJlc3AuU3VwcG9ydGVkQ29tbWFuZFJlc3VsdFIRc3'
    'VwcG9ydGVkQ29tbWFuZHMSVwoQc3VwcG9ydGVkX2V2ZW50cxgFIAMoCzIsLnVzcC5HZXRTdXBw'
    'b3J0ZWRETVJlc3AuU3VwcG9ydGVkRXZlbnRSZXN1bHRSD3N1cHBvcnRlZEV2ZW50cxJXChBzdX'
    'Bwb3J0ZWRfcGFyYW1zGAYgAygLMiwudXNwLkdldFN1cHBvcnRlZERNUmVzcC5TdXBwb3J0ZWRQ'
    'YXJhbVJlc3VsdFIPc3VwcG9ydGVkUGFyYW1zEicKD2RpdmVyZ2VudF9wYXRocxgHIAMoCVIOZG'
    'l2ZXJnZW50UGF0aHMSVQoPdW5pcXVlX2tleV9zZXRzGAggAygLMi0udXNwLkdldFN1cHBvcnRl'
    'ZERNUmVzcC5TdXBwb3J0ZWRVbmlxdWVLZXlTZXRSDXVuaXF1ZUtleVNldHMaiQIKFFN1cHBvcn'
    'RlZFBhcmFtUmVzdWx0Eh0KCnBhcmFtX25hbWUYASABKAlSCXBhcmFtTmFtZRI/CgZhY2Nlc3MY'
    'AiABKA4yJy51c3AuR2V0U3VwcG9ydGVkRE1SZXNwLlBhcmFtQWNjZXNzVHlwZVIGYWNjZXNzEk'
    'UKCnZhbHVlX3R5cGUYAyABKA4yJi51c3AuR2V0U3VwcG9ydGVkRE1SZXNwLlBhcmFtVmFsdWVU'
    'eXBlUgl2YWx1ZVR5cGUSSgoMdmFsdWVfY2hhbmdlGAQgASgOMicudXNwLkdldFN1cHBvcnRlZE'
    'RNUmVzcC5WYWx1ZUNoYW5nZVR5cGVSC3ZhbHVlQ2hhbmdlGtEBChZTdXBwb3J0ZWRDb21tYW5k'
    'UmVzdWx0EiEKDGNvbW1hbmRfbmFtZRgBIAEoCVILY29tbWFuZE5hbWUSJgoPaW5wdXRfYXJnX2'
    '5hbWVzGAIgAygJUg1pbnB1dEFyZ05hbWVzEigKEG91dHB1dF9hcmdfbmFtZXMYAyADKAlSDm91'
    'dHB1dEFyZ05hbWVzEkIKDGNvbW1hbmRfdHlwZRgEIAEoDjIfLnVzcC5HZXRTdXBwb3J0ZWRETV'
    'Jlc3AuQ21kVHlwZVILY29tbWFuZFR5cGUaUgoUU3VwcG9ydGVkRXZlbnRSZXN1bHQSHQoKZXZl'
    'bnRfbmFtZRgBIAEoCVIJZXZlbnROYW1lEhsKCWFyZ19uYW1lcxgCIAMoCVIIYXJnTmFtZXMaNA'
    'oVU3VwcG9ydGVkVW5pcXVlS2V5U2V0EhsKCWtleV9uYW1lcxgBIAMoCVIIa2V5TmFtZXMiUgoP'
    'UGFyYW1BY2Nlc3NUeXBlEhMKD1BBUkFNX1JFQURfT05MWRAAEhQKEFBBUkFNX1JFQURfV1JJVE'
    'UQARIUChBQQVJBTV9XUklURV9PTkxZEAIiXQoNT2JqQWNjZXNzVHlwZRIRCg1PQkpfUkVBRF9P'
    'TkxZEAASEgoOT0JKX0FERF9ERUxFVEUQARIQCgxPQkpfQUREX09OTFkQAhITCg9PQkpfREVMRV'
    'RFX09OTFkQAyLpAQoOUGFyYW1WYWx1ZVR5cGUSEQoNUEFSQU1fVU5LTk9XThAAEhEKDVBBUkFN'
    'X0JBU0VfNjQQARIRCg1QQVJBTV9CT09MRUFOEAISEwoPUEFSQU1fREFURV9USU1FEAMSEQoNUE'
    'FSQU1fREVDSU1BTBAEEhQKEFBBUkFNX0hFWF9CSU5BUlkQBRINCglQQVJBTV9JTlQQBhIOCgpQ'
    'QVJBTV9MT05HEAcSEAoMUEFSQU1fU1RSSU5HEAgSFgoSUEFSQU1fVU5TSUdORURfSU5UEAkSFw'
    'oTUEFSQU1fVU5TSUdORURfTE9ORxAKImMKD1ZhbHVlQ2hhbmdlVHlwZRIYChRWQUxVRV9DSEFO'
    'R0VfVU5LTk9XThAAEhgKFFZBTFVFX0NIQU5HRV9BTExPV0VEEAESHAoYVkFMVUVfQ0hBTkdFX1'
    'dJTExfSUdOT1JFEAIiNwoHQ21kVHlwZRIPCgtDTURfVU5LTk9XThAAEgwKCENNRF9TWU5DEAES'
    'DQoJQ01EX0FTWU5DEAI=');

@$core.Deprecated('Use getInstancesDescriptor instead')
const GetInstances$json = {
  '1': 'GetInstances',
  '2': [
    {'1': 'obj_paths', '3': 1, '4': 3, '5': 9, '10': 'objPaths'},
    {'1': 'first_level_only', '3': 2, '4': 1, '5': 8, '10': 'firstLevelOnly'},
  ],
};

/// Descriptor for `GetInstances`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInstancesDescriptor = $convert.base64Decode(
    'CgxHZXRJbnN0YW5jZXMSGwoJb2JqX3BhdGhzGAEgAygJUghvYmpQYXRocxIoChBmaXJzdF9sZX'
    'ZlbF9vbmx5GAIgASgIUg5maXJzdExldmVsT25seQ==');

@$core.Deprecated('Use getInstancesRespDescriptor instead')
const GetInstancesResp$json = {
  '1': 'GetInstancesResp',
  '2': [
    {
      '1': 'req_path_results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.usp.GetInstancesResp.RequestedPathResult',
      '10': 'reqPathResults'
    },
  ],
  '3': [
    GetInstancesResp_RequestedPathResult$json,
    GetInstancesResp_CurrInstance$json
  ],
};

@$core.Deprecated('Use getInstancesRespDescriptor instead')
const GetInstancesResp_RequestedPathResult$json = {
  '1': 'RequestedPathResult',
  '2': [
    {'1': 'requested_path', '3': 1, '4': 1, '5': 9, '10': 'requestedPath'},
    {'1': 'err_code', '3': 2, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 3, '4': 1, '5': 9, '10': 'errMsg'},
    {
      '1': 'curr_insts',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.usp.GetInstancesResp.CurrInstance',
      '10': 'currInsts'
    },
  ],
};

@$core.Deprecated('Use getInstancesRespDescriptor instead')
const GetInstancesResp_CurrInstance$json = {
  '1': 'CurrInstance',
  '2': [
    {
      '1': 'instantiated_obj_path',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'instantiatedObjPath'
    },
    {
      '1': 'unique_keys',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.usp.GetInstancesResp.CurrInstance.UniqueKeysEntry',
      '10': 'uniqueKeys'
    },
  ],
  '3': [GetInstancesResp_CurrInstance_UniqueKeysEntry$json],
};

@$core.Deprecated('Use getInstancesRespDescriptor instead')
const GetInstancesResp_CurrInstance_UniqueKeysEntry$json = {
  '1': 'UniqueKeysEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `GetInstancesResp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInstancesRespDescriptor = $convert.base64Decode(
    'ChBHZXRJbnN0YW5jZXNSZXNwElMKEHJlcV9wYXRoX3Jlc3VsdHMYASADKAsyKS51c3AuR2V0SW'
    '5zdGFuY2VzUmVzcC5SZXF1ZXN0ZWRQYXRoUmVzdWx0Ug5yZXFQYXRoUmVzdWx0cxqzAQoTUmVx'
    'dWVzdGVkUGF0aFJlc3VsdBIlCg5yZXF1ZXN0ZWRfcGF0aBgBIAEoCVINcmVxdWVzdGVkUGF0aB'
    'IZCghlcnJfY29kZRgCIAEoB1IHZXJyQ29kZRIXCgdlcnJfbXNnGAMgASgJUgZlcnJNc2cSQQoK'
    'Y3Vycl9pbnN0cxgEIAMoCzIiLnVzcC5HZXRJbnN0YW5jZXNSZXNwLkN1cnJJbnN0YW5jZVIJY3'
    'Vyckluc3RzGtYBCgxDdXJySW5zdGFuY2USMgoVaW5zdGFudGlhdGVkX29ial9wYXRoGAEgASgJ'
    'UhNpbnN0YW50aWF0ZWRPYmpQYXRoElMKC3VuaXF1ZV9rZXlzGAIgAygLMjIudXNwLkdldEluc3'
    'RhbmNlc1Jlc3AuQ3Vyckluc3RhbmNlLlVuaXF1ZUtleXNFbnRyeVIKdW5pcXVlS2V5cxo9Cg9V'
    'bmlxdWVLZXlzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOg'
    'I4AQ==');

@$core.Deprecated('Use getSupportedProtocolDescriptor instead')
const GetSupportedProtocol$json = {
  '1': 'GetSupportedProtocol',
  '2': [
    {
      '1': 'controller_supported_protocol_versions',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'controllerSupportedProtocolVersions'
    },
  ],
};

/// Descriptor for `GetSupportedProtocol`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSupportedProtocolDescriptor = $convert.base64Decode(
    'ChRHZXRTdXBwb3J0ZWRQcm90b2NvbBJTCiZjb250cm9sbGVyX3N1cHBvcnRlZF9wcm90b2NvbF'
    '92ZXJzaW9ucxgBIAEoCVIjY29udHJvbGxlclN1cHBvcnRlZFByb3RvY29sVmVyc2lvbnM=');

@$core.Deprecated('Use getSupportedProtocolRespDescriptor instead')
const GetSupportedProtocolResp$json = {
  '1': 'GetSupportedProtocolResp',
  '2': [
    {
      '1': 'agent_supported_protocol_versions',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'agentSupportedProtocolVersions'
    },
  ],
};

/// Descriptor for `GetSupportedProtocolResp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSupportedProtocolRespDescriptor =
    $convert.base64Decode(
        'ChhHZXRTdXBwb3J0ZWRQcm90b2NvbFJlc3ASSQohYWdlbnRfc3VwcG9ydGVkX3Byb3RvY29sX3'
        'ZlcnNpb25zGAEgASgJUh5hZ2VudFN1cHBvcnRlZFByb3RvY29sVmVyc2lvbnM=');

@$core.Deprecated('Use addDescriptor instead')
const Add$json = {
  '1': 'Add',
  '2': [
    {'1': 'allow_partial', '3': 1, '4': 1, '5': 8, '10': 'allowPartial'},
    {
      '1': 'create_objs',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.usp.Add.CreateObject',
      '10': 'createObjs'
    },
  ],
  '3': [Add_CreateObject$json, Add_CreateParamSetting$json],
};

@$core.Deprecated('Use addDescriptor instead')
const Add_CreateObject$json = {
  '1': 'CreateObject',
  '2': [
    {'1': 'obj_path', '3': 1, '4': 1, '5': 9, '10': 'objPath'},
    {
      '1': 'param_settings',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.usp.Add.CreateParamSetting',
      '10': 'paramSettings'
    },
  ],
};

@$core.Deprecated('Use addDescriptor instead')
const Add_CreateParamSetting$json = {
  '1': 'CreateParamSetting',
  '2': [
    {'1': 'param', '3': 1, '4': 1, '5': 9, '10': 'param'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
    {'1': 'required', '3': 3, '4': 1, '5': 8, '10': 'required'},
  ],
};

/// Descriptor for `Add`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addDescriptor = $convert.base64Decode(
    'CgNBZGQSIwoNYWxsb3dfcGFydGlhbBgBIAEoCFIMYWxsb3dQYXJ0aWFsEjYKC2NyZWF0ZV9vYm'
    'pzGAIgAygLMhUudXNwLkFkZC5DcmVhdGVPYmplY3RSCmNyZWF0ZU9ianMabQoMQ3JlYXRlT2Jq'
    'ZWN0EhkKCG9ial9wYXRoGAEgASgJUgdvYmpQYXRoEkIKDnBhcmFtX3NldHRpbmdzGAIgAygLMh'
    'sudXNwLkFkZC5DcmVhdGVQYXJhbVNldHRpbmdSDXBhcmFtU2V0dGluZ3MaXAoSQ3JlYXRlUGFy'
    'YW1TZXR0aW5nEhQKBXBhcmFtGAEgASgJUgVwYXJhbRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWUSGg'
    'oIcmVxdWlyZWQYAyABKAhSCHJlcXVpcmVk');

@$core.Deprecated('Use addRespDescriptor instead')
const AddResp$json = {
  '1': 'AddResp',
  '2': [
    {
      '1': 'created_obj_results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.usp.AddResp.CreatedObjectResult',
      '10': 'createdObjResults'
    },
  ],
  '3': [AddResp_CreatedObjectResult$json, AddResp_ParameterError$json],
};

@$core.Deprecated('Use addRespDescriptor instead')
const AddResp_CreatedObjectResult$json = {
  '1': 'CreatedObjectResult',
  '2': [
    {'1': 'requested_path', '3': 1, '4': 1, '5': 9, '10': 'requestedPath'},
    {
      '1': 'oper_status',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.usp.AddResp.CreatedObjectResult.OperationStatus',
      '10': 'operStatus'
    },
  ],
  '3': [AddResp_CreatedObjectResult_OperationStatus$json],
};

@$core.Deprecated('Use addRespDescriptor instead')
const AddResp_CreatedObjectResult_OperationStatus$json = {
  '1': 'OperationStatus',
  '2': [
    {
      '1': 'oper_failure',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.usp.AddResp.CreatedObjectResult.OperationStatus.OperationFailure',
      '9': 0,
      '10': 'operFailure'
    },
    {
      '1': 'oper_success',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.usp.AddResp.CreatedObjectResult.OperationStatus.OperationSuccess',
      '9': 0,
      '10': 'operSuccess'
    },
  ],
  '3': [
    AddResp_CreatedObjectResult_OperationStatus_OperationFailure$json,
    AddResp_CreatedObjectResult_OperationStatus_OperationSuccess$json
  ],
  '8': [
    {'1': 'oper_status'},
  ],
};

@$core.Deprecated('Use addRespDescriptor instead')
const AddResp_CreatedObjectResult_OperationStatus_OperationFailure$json = {
  '1': 'OperationFailure',
  '2': [
    {'1': 'err_code', '3': 1, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 2, '4': 1, '5': 9, '10': 'errMsg'},
  ],
};

@$core.Deprecated('Use addRespDescriptor instead')
const AddResp_CreatedObjectResult_OperationStatus_OperationSuccess$json = {
  '1': 'OperationSuccess',
  '2': [
    {
      '1': 'instantiated_path',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'instantiatedPath'
    },
    {
      '1': 'param_errs',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.usp.AddResp.ParameterError',
      '10': 'paramErrs'
    },
    {
      '1': 'unique_keys',
      '3': 3,
      '4': 3,
      '5': 11,
      '6':
          '.usp.AddResp.CreatedObjectResult.OperationStatus.OperationSuccess.UniqueKeysEntry',
      '10': 'uniqueKeys'
    },
  ],
  '3': [
    AddResp_CreatedObjectResult_OperationStatus_OperationSuccess_UniqueKeysEntry$json
  ],
};

@$core.Deprecated('Use addRespDescriptor instead')
const AddResp_CreatedObjectResult_OperationStatus_OperationSuccess_UniqueKeysEntry$json =
    {
  '1': 'UniqueKeysEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use addRespDescriptor instead')
const AddResp_ParameterError$json = {
  '1': 'ParameterError',
  '2': [
    {'1': 'param', '3': 1, '4': 1, '5': 9, '10': 'param'},
    {'1': 'err_code', '3': 2, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 3, '4': 1, '5': 9, '10': 'errMsg'},
  ],
};

/// Descriptor for `AddResp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addRespDescriptor = $convert.base64Decode(
    'CgdBZGRSZXNwElAKE2NyZWF0ZWRfb2JqX3Jlc3VsdHMYASADKAsyIC51c3AuQWRkUmVzcC5Dcm'
    'VhdGVkT2JqZWN0UmVzdWx0UhFjcmVhdGVkT2JqUmVzdWx0cxr7BQoTQ3JlYXRlZE9iamVjdFJl'
    'c3VsdBIlCg5yZXF1ZXN0ZWRfcGF0aBgBIAEoCVINcmVxdWVzdGVkUGF0aBJRCgtvcGVyX3N0YX'
    'R1cxgCIAEoCzIwLnVzcC5BZGRSZXNwLkNyZWF0ZWRPYmplY3RSZXN1bHQuT3BlcmF0aW9uU3Rh'
    'dHVzUgpvcGVyU3RhdHVzGukECg9PcGVyYXRpb25TdGF0dXMSZgoMb3Blcl9mYWlsdXJlGAEgAS'
    'gLMkEudXNwLkFkZFJlc3AuQ3JlYXRlZE9iamVjdFJlc3VsdC5PcGVyYXRpb25TdGF0dXMuT3Bl'
    'cmF0aW9uRmFpbHVyZUgAUgtvcGVyRmFpbHVyZRJmCgxvcGVyX3N1Y2Nlc3MYAiABKAsyQS51c3'
    'AuQWRkUmVzcC5DcmVhdGVkT2JqZWN0UmVzdWx0Lk9wZXJhdGlvblN0YXR1cy5PcGVyYXRpb25T'
    'dWNjZXNzSABSC29wZXJTdWNjZXNzGkYKEE9wZXJhdGlvbkZhaWx1cmUSGQoIZXJyX2NvZGUYAS'
    'ABKAdSB2VyckNvZGUSFwoHZXJyX21zZxgCIAEoCVIGZXJyTXNnGq4CChBPcGVyYXRpb25TdWNj'
    'ZXNzEisKEWluc3RhbnRpYXRlZF9wYXRoGAEgASgJUhBpbnN0YW50aWF0ZWRQYXRoEjoKCnBhcm'
    'FtX2VycnMYAiADKAsyGy51c3AuQWRkUmVzcC5QYXJhbWV0ZXJFcnJvclIJcGFyYW1FcnJzEnIK'
    'C3VuaXF1ZV9rZXlzGAMgAygLMlEudXNwLkFkZFJlc3AuQ3JlYXRlZE9iamVjdFJlc3VsdC5PcG'
    'VyYXRpb25TdGF0dXMuT3BlcmF0aW9uU3VjY2Vzcy5VbmlxdWVLZXlzRW50cnlSCnVuaXF1ZUtl'
    'eXMaPQoPVW5pcXVlS2V5c0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUg'
    'V2YWx1ZToCOAFCDQoLb3Blcl9zdGF0dXMaWgoOUGFyYW1ldGVyRXJyb3ISFAoFcGFyYW0YASAB'
    'KAlSBXBhcmFtEhkKCGVycl9jb2RlGAIgASgHUgdlcnJDb2RlEhcKB2Vycl9tc2cYAyABKAlSBm'
    'Vyck1zZw==');

@$core.Deprecated('Use deleteDescriptor instead')
const Delete$json = {
  '1': 'Delete',
  '2': [
    {'1': 'allow_partial', '3': 1, '4': 1, '5': 8, '10': 'allowPartial'},
    {'1': 'obj_paths', '3': 2, '4': 3, '5': 9, '10': 'objPaths'},
  ],
};

/// Descriptor for `Delete`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteDescriptor = $convert.base64Decode(
    'CgZEZWxldGUSIwoNYWxsb3dfcGFydGlhbBgBIAEoCFIMYWxsb3dQYXJ0aWFsEhsKCW9ial9wYX'
    'RocxgCIAMoCVIIb2JqUGF0aHM=');

@$core.Deprecated('Use deleteRespDescriptor instead')
const DeleteResp$json = {
  '1': 'DeleteResp',
  '2': [
    {
      '1': 'deleted_obj_results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.usp.DeleteResp.DeletedObjectResult',
      '10': 'deletedObjResults'
    },
  ],
  '3': [
    DeleteResp_DeletedObjectResult$json,
    DeleteResp_UnaffectedPathError$json
  ],
};

@$core.Deprecated('Use deleteRespDescriptor instead')
const DeleteResp_DeletedObjectResult$json = {
  '1': 'DeletedObjectResult',
  '2': [
    {'1': 'requested_path', '3': 1, '4': 1, '5': 9, '10': 'requestedPath'},
    {
      '1': 'oper_status',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.usp.DeleteResp.DeletedObjectResult.OperationStatus',
      '10': 'operStatus'
    },
  ],
  '3': [DeleteResp_DeletedObjectResult_OperationStatus$json],
};

@$core.Deprecated('Use deleteRespDescriptor instead')
const DeleteResp_DeletedObjectResult_OperationStatus$json = {
  '1': 'OperationStatus',
  '2': [
    {
      '1': 'oper_failure',
      '3': 1,
      '4': 1,
      '5': 11,
      '6':
          '.usp.DeleteResp.DeletedObjectResult.OperationStatus.OperationFailure',
      '9': 0,
      '10': 'operFailure'
    },
    {
      '1': 'oper_success',
      '3': 2,
      '4': 1,
      '5': 11,
      '6':
          '.usp.DeleteResp.DeletedObjectResult.OperationStatus.OperationSuccess',
      '9': 0,
      '10': 'operSuccess'
    },
  ],
  '3': [
    DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure$json,
    DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess$json
  ],
  '8': [
    {'1': 'oper_status'},
  ],
};

@$core.Deprecated('Use deleteRespDescriptor instead')
const DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure$json = {
  '1': 'OperationFailure',
  '2': [
    {'1': 'err_code', '3': 1, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 2, '4': 1, '5': 9, '10': 'errMsg'},
  ],
};

@$core.Deprecated('Use deleteRespDescriptor instead')
const DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess$json = {
  '1': 'OperationSuccess',
  '2': [
    {'1': 'affected_paths', '3': 1, '4': 3, '5': 9, '10': 'affectedPaths'},
    {
      '1': 'unaffected_path_errs',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.usp.DeleteResp.UnaffectedPathError',
      '10': 'unaffectedPathErrs'
    },
  ],
};

@$core.Deprecated('Use deleteRespDescriptor instead')
const DeleteResp_UnaffectedPathError$json = {
  '1': 'UnaffectedPathError',
  '2': [
    {'1': 'unaffected_path', '3': 1, '4': 1, '5': 9, '10': 'unaffectedPath'},
    {'1': 'err_code', '3': 2, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 3, '4': 1, '5': 9, '10': 'errMsg'},
  ],
};

/// Descriptor for `DeleteResp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteRespDescriptor = $convert.base64Decode(
    'CgpEZWxldGVSZXNwElMKE2RlbGV0ZWRfb2JqX3Jlc3VsdHMYASADKAsyIy51c3AuRGVsZXRlUm'
    'VzcC5EZWxldGVkT2JqZWN0UmVzdWx0UhFkZWxldGVkT2JqUmVzdWx0cxrmBAoTRGVsZXRlZE9i'
    'amVjdFJlc3VsdBIlCg5yZXF1ZXN0ZWRfcGF0aBgBIAEoCVINcmVxdWVzdGVkUGF0aBJUCgtvcG'
    'VyX3N0YXR1cxgCIAEoCzIzLnVzcC5EZWxldGVSZXNwLkRlbGV0ZWRPYmplY3RSZXN1bHQuT3Bl'
    'cmF0aW9uU3RhdHVzUgpvcGVyU3RhdHVzGtEDCg9PcGVyYXRpb25TdGF0dXMSaQoMb3Blcl9mYW'
    'lsdXJlGAEgASgLMkQudXNwLkRlbGV0ZVJlc3AuRGVsZXRlZE9iamVjdFJlc3VsdC5PcGVyYXRp'
    'b25TdGF0dXMuT3BlcmF0aW9uRmFpbHVyZUgAUgtvcGVyRmFpbHVyZRJpCgxvcGVyX3N1Y2Nlc3'
    'MYAiABKAsyRC51c3AuRGVsZXRlUmVzcC5EZWxldGVkT2JqZWN0UmVzdWx0Lk9wZXJhdGlvblN0'
    'YXR1cy5PcGVyYXRpb25TdWNjZXNzSABSC29wZXJTdWNjZXNzGkYKEE9wZXJhdGlvbkZhaWx1cm'
    'USGQoIZXJyX2NvZGUYASABKAdSB2VyckNvZGUSFwoHZXJyX21zZxgCIAEoCVIGZXJyTXNnGpAB'
    'ChBPcGVyYXRpb25TdWNjZXNzEiUKDmFmZmVjdGVkX3BhdGhzGAEgAygJUg1hZmZlY3RlZFBhdG'
    'hzElUKFHVuYWZmZWN0ZWRfcGF0aF9lcnJzGAIgAygLMiMudXNwLkRlbGV0ZVJlc3AuVW5hZmZl'
    'Y3RlZFBhdGhFcnJvclISdW5hZmZlY3RlZFBhdGhFcnJzQg0KC29wZXJfc3RhdHVzGnIKE1VuYW'
    'ZmZWN0ZWRQYXRoRXJyb3ISJwoPdW5hZmZlY3RlZF9wYXRoGAEgASgJUg51bmFmZmVjdGVkUGF0'
    'aBIZCghlcnJfY29kZRgCIAEoB1IHZXJyQ29kZRIXCgdlcnJfbXNnGAMgASgJUgZlcnJNc2c=');

@$core.Deprecated('Use setDescriptor instead')
const Set$json = {
  '1': 'Set',
  '2': [
    {'1': 'allow_partial', '3': 1, '4': 1, '5': 8, '10': 'allowPartial'},
    {
      '1': 'update_objs',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.usp.Set.UpdateObject',
      '10': 'updateObjs'
    },
  ],
  '3': [Set_UpdateObject$json, Set_UpdateParamSetting$json],
};

@$core.Deprecated('Use setDescriptor instead')
const Set_UpdateObject$json = {
  '1': 'UpdateObject',
  '2': [
    {'1': 'obj_path', '3': 1, '4': 1, '5': 9, '10': 'objPath'},
    {
      '1': 'param_settings',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.usp.Set.UpdateParamSetting',
      '10': 'paramSettings'
    },
  ],
};

@$core.Deprecated('Use setDescriptor instead')
const Set_UpdateParamSetting$json = {
  '1': 'UpdateParamSetting',
  '2': [
    {'1': 'param', '3': 1, '4': 1, '5': 9, '10': 'param'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
    {'1': 'required', '3': 3, '4': 1, '5': 8, '10': 'required'},
  ],
};

/// Descriptor for `Set`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setDescriptor = $convert.base64Decode(
    'CgNTZXQSIwoNYWxsb3dfcGFydGlhbBgBIAEoCFIMYWxsb3dQYXJ0aWFsEjYKC3VwZGF0ZV9vYm'
    'pzGAIgAygLMhUudXNwLlNldC5VcGRhdGVPYmplY3RSCnVwZGF0ZU9ianMabQoMVXBkYXRlT2Jq'
    'ZWN0EhkKCG9ial9wYXRoGAEgASgJUgdvYmpQYXRoEkIKDnBhcmFtX3NldHRpbmdzGAIgAygLMh'
    'sudXNwLlNldC5VcGRhdGVQYXJhbVNldHRpbmdSDXBhcmFtU2V0dGluZ3MaXAoSVXBkYXRlUGFy'
    'YW1TZXR0aW5nEhQKBXBhcmFtGAEgASgJUgVwYXJhbRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWUSGg'
    'oIcmVxdWlyZWQYAyABKAhSCHJlcXVpcmVk');

@$core.Deprecated('Use setRespDescriptor instead')
const SetResp$json = {
  '1': 'SetResp',
  '2': [
    {
      '1': 'updated_obj_results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.usp.SetResp.UpdatedObjectResult',
      '10': 'updatedObjResults'
    },
  ],
  '3': [
    SetResp_UpdatedObjectResult$json,
    SetResp_UpdatedInstanceFailure$json,
    SetResp_UpdatedInstanceResult$json,
    SetResp_ParameterError$json
  ],
};

@$core.Deprecated('Use setRespDescriptor instead')
const SetResp_UpdatedObjectResult$json = {
  '1': 'UpdatedObjectResult',
  '2': [
    {'1': 'requested_path', '3': 1, '4': 1, '5': 9, '10': 'requestedPath'},
    {
      '1': 'oper_status',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.usp.SetResp.UpdatedObjectResult.OperationStatus',
      '10': 'operStatus'
    },
  ],
  '3': [SetResp_UpdatedObjectResult_OperationStatus$json],
};

@$core.Deprecated('Use setRespDescriptor instead')
const SetResp_UpdatedObjectResult_OperationStatus$json = {
  '1': 'OperationStatus',
  '2': [
    {
      '1': 'oper_failure',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.usp.SetResp.UpdatedObjectResult.OperationStatus.OperationFailure',
      '9': 0,
      '10': 'operFailure'
    },
    {
      '1': 'oper_success',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.usp.SetResp.UpdatedObjectResult.OperationStatus.OperationSuccess',
      '9': 0,
      '10': 'operSuccess'
    },
  ],
  '3': [
    SetResp_UpdatedObjectResult_OperationStatus_OperationFailure$json,
    SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess$json
  ],
  '8': [
    {'1': 'oper_status'},
  ],
};

@$core.Deprecated('Use setRespDescriptor instead')
const SetResp_UpdatedObjectResult_OperationStatus_OperationFailure$json = {
  '1': 'OperationFailure',
  '2': [
    {'1': 'err_code', '3': 1, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 2, '4': 1, '5': 9, '10': 'errMsg'},
    {
      '1': 'updated_inst_failures',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.usp.SetResp.UpdatedInstanceFailure',
      '10': 'updatedInstFailures'
    },
  ],
};

@$core.Deprecated('Use setRespDescriptor instead')
const SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess$json = {
  '1': 'OperationSuccess',
  '2': [
    {
      '1': 'updated_inst_results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.usp.SetResp.UpdatedInstanceResult',
      '10': 'updatedInstResults'
    },
  ],
};

@$core.Deprecated('Use setRespDescriptor instead')
const SetResp_UpdatedInstanceFailure$json = {
  '1': 'UpdatedInstanceFailure',
  '2': [
    {'1': 'affected_path', '3': 1, '4': 1, '5': 9, '10': 'affectedPath'},
    {
      '1': 'param_errs',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.usp.SetResp.ParameterError',
      '10': 'paramErrs'
    },
  ],
};

@$core.Deprecated('Use setRespDescriptor instead')
const SetResp_UpdatedInstanceResult$json = {
  '1': 'UpdatedInstanceResult',
  '2': [
    {'1': 'affected_path', '3': 1, '4': 1, '5': 9, '10': 'affectedPath'},
    {
      '1': 'param_errs',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.usp.SetResp.ParameterError',
      '10': 'paramErrs'
    },
    {
      '1': 'updated_params',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.usp.SetResp.UpdatedInstanceResult.UpdatedParamsEntry',
      '10': 'updatedParams'
    },
  ],
  '3': [SetResp_UpdatedInstanceResult_UpdatedParamsEntry$json],
};

@$core.Deprecated('Use setRespDescriptor instead')
const SetResp_UpdatedInstanceResult_UpdatedParamsEntry$json = {
  '1': 'UpdatedParamsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use setRespDescriptor instead')
const SetResp_ParameterError$json = {
  '1': 'ParameterError',
  '2': [
    {'1': 'param', '3': 1, '4': 1, '5': 9, '10': 'param'},
    {'1': 'err_code', '3': 2, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 3, '4': 1, '5': 9, '10': 'errMsg'},
  ],
};

/// Descriptor for `SetResp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setRespDescriptor = $convert.base64Decode(
    'CgdTZXRSZXNwElAKE3VwZGF0ZWRfb2JqX3Jlc3VsdHMYASADKAsyIC51c3AuU2V0UmVzcC5VcG'
    'RhdGVkT2JqZWN0UmVzdWx0UhF1cGRhdGVkT2JqUmVzdWx0cxqOBQoTVXBkYXRlZE9iamVjdFJl'
    'c3VsdBIlCg5yZXF1ZXN0ZWRfcGF0aBgBIAEoCVINcmVxdWVzdGVkUGF0aBJRCgtvcGVyX3N0YX'
    'R1cxgCIAEoCzIwLnVzcC5TZXRSZXNwLlVwZGF0ZWRPYmplY3RSZXN1bHQuT3BlcmF0aW9uU3Rh'
    'dHVzUgpvcGVyU3RhdHVzGvwDCg9PcGVyYXRpb25TdGF0dXMSZgoMb3Blcl9mYWlsdXJlGAEgAS'
    'gLMkEudXNwLlNldFJlc3AuVXBkYXRlZE9iamVjdFJlc3VsdC5PcGVyYXRpb25TdGF0dXMuT3Bl'
    'cmF0aW9uRmFpbHVyZUgAUgtvcGVyRmFpbHVyZRJmCgxvcGVyX3N1Y2Nlc3MYAiABKAsyQS51c3'
    'AuU2V0UmVzcC5VcGRhdGVkT2JqZWN0UmVzdWx0Lk9wZXJhdGlvblN0YXR1cy5PcGVyYXRpb25T'
    'dWNjZXNzSABSC29wZXJTdWNjZXNzGp8BChBPcGVyYXRpb25GYWlsdXJlEhkKCGVycl9jb2RlGA'
    'EgASgHUgdlcnJDb2RlEhcKB2Vycl9tc2cYAiABKAlSBmVyck1zZxJXChV1cGRhdGVkX2luc3Rf'
    'ZmFpbHVyZXMYAyADKAsyIy51c3AuU2V0UmVzcC5VcGRhdGVkSW5zdGFuY2VGYWlsdXJlUhN1cG'
    'RhdGVkSW5zdEZhaWx1cmVzGmgKEE9wZXJhdGlvblN1Y2Nlc3MSVAoUdXBkYXRlZF9pbnN0X3Jl'
    'c3VsdHMYASADKAsyIi51c3AuU2V0UmVzcC5VcGRhdGVkSW5zdGFuY2VSZXN1bHRSEnVwZGF0ZW'
    'RJbnN0UmVzdWx0c0INCgtvcGVyX3N0YXR1cxp5ChZVcGRhdGVkSW5zdGFuY2VGYWlsdXJlEiMK'
    'DWFmZmVjdGVkX3BhdGgYASABKAlSDGFmZmVjdGVkUGF0aBI6CgpwYXJhbV9lcnJzGAIgAygLMh'
    'sudXNwLlNldFJlc3AuUGFyYW1ldGVyRXJyb3JSCXBhcmFtRXJycxqYAgoVVXBkYXRlZEluc3Rh'
    'bmNlUmVzdWx0EiMKDWFmZmVjdGVkX3BhdGgYASABKAlSDGFmZmVjdGVkUGF0aBI6CgpwYXJhbV'
    '9lcnJzGAIgAygLMhsudXNwLlNldFJlc3AuUGFyYW1ldGVyRXJyb3JSCXBhcmFtRXJycxJcCg51'
    'cGRhdGVkX3BhcmFtcxgDIAMoCzI1LnVzcC5TZXRSZXNwLlVwZGF0ZWRJbnN0YW5jZVJlc3VsdC'
    '5VcGRhdGVkUGFyYW1zRW50cnlSDXVwZGF0ZWRQYXJhbXMaQAoSVXBkYXRlZFBhcmFtc0VudHJ5'
    'EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEaWgoOUGFyYW1ldG'
    'VyRXJyb3ISFAoFcGFyYW0YASABKAlSBXBhcmFtEhkKCGVycl9jb2RlGAIgASgHUgdlcnJDb2Rl'
    'EhcKB2Vycl9tc2cYAyABKAlSBmVyck1zZw==');

@$core.Deprecated('Use operateDescriptor instead')
const Operate$json = {
  '1': 'Operate',
  '2': [
    {'1': 'command', '3': 1, '4': 1, '5': 9, '10': 'command'},
    {'1': 'command_key', '3': 2, '4': 1, '5': 9, '10': 'commandKey'},
    {'1': 'send_resp', '3': 3, '4': 1, '5': 8, '10': 'sendResp'},
    {
      '1': 'input_args',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.usp.Operate.InputArgsEntry',
      '10': 'inputArgs'
    },
  ],
  '3': [Operate_InputArgsEntry$json],
};

@$core.Deprecated('Use operateDescriptor instead')
const Operate_InputArgsEntry$json = {
  '1': 'InputArgsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `Operate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List operateDescriptor = $convert.base64Decode(
    'CgdPcGVyYXRlEhgKB2NvbW1hbmQYASABKAlSB2NvbW1hbmQSHwoLY29tbWFuZF9rZXkYAiABKA'
    'lSCmNvbW1hbmRLZXkSGwoJc2VuZF9yZXNwGAMgASgIUghzZW5kUmVzcBI6CgppbnB1dF9hcmdz'
    'GAQgAygLMhsudXNwLk9wZXJhdGUuSW5wdXRBcmdzRW50cnlSCWlucHV0QXJncxo8Cg5JbnB1dE'
    'FyZ3NFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');

@$core.Deprecated('Use operateRespDescriptor instead')
const OperateResp$json = {
  '1': 'OperateResp',
  '2': [
    {
      '1': 'operation_results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.usp.OperateResp.OperationResult',
      '10': 'operationResults'
    },
  ],
  '3': [OperateResp_OperationResult$json],
};

@$core.Deprecated('Use operateRespDescriptor instead')
const OperateResp_OperationResult$json = {
  '1': 'OperationResult',
  '2': [
    {'1': 'executed_command', '3': 1, '4': 1, '5': 9, '10': 'executedCommand'},
    {'1': 'req_obj_path', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'reqObjPath'},
    {
      '1': 'req_output_args',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.usp.OperateResp.OperationResult.OutputArgs',
      '9': 0,
      '10': 'reqOutputArgs'
    },
    {
      '1': 'cmd_failure',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.usp.OperateResp.OperationResult.CommandFailure',
      '9': 0,
      '10': 'cmdFailure'
    },
  ],
  '3': [
    OperateResp_OperationResult_OutputArgs$json,
    OperateResp_OperationResult_CommandFailure$json
  ],
  '8': [
    {'1': 'operation_resp'},
  ],
};

@$core.Deprecated('Use operateRespDescriptor instead')
const OperateResp_OperationResult_OutputArgs$json = {
  '1': 'OutputArgs',
  '2': [
    {
      '1': 'output_args',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.usp.OperateResp.OperationResult.OutputArgs.OutputArgsEntry',
      '10': 'outputArgs'
    },
  ],
  '3': [OperateResp_OperationResult_OutputArgs_OutputArgsEntry$json],
};

@$core.Deprecated('Use operateRespDescriptor instead')
const OperateResp_OperationResult_OutputArgs_OutputArgsEntry$json = {
  '1': 'OutputArgsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use operateRespDescriptor instead')
const OperateResp_OperationResult_CommandFailure$json = {
  '1': 'CommandFailure',
  '2': [
    {'1': 'err_code', '3': 1, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 2, '4': 1, '5': 9, '10': 'errMsg'},
  ],
};

/// Descriptor for `OperateResp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List operateRespDescriptor = $convert.base64Decode(
    'CgtPcGVyYXRlUmVzcBJNChFvcGVyYXRpb25fcmVzdWx0cxgBIAMoCzIgLnVzcC5PcGVyYXRlUm'
    'VzcC5PcGVyYXRpb25SZXN1bHRSEG9wZXJhdGlvblJlc3VsdHMajwQKD09wZXJhdGlvblJlc3Vs'
    'dBIpChBleGVjdXRlZF9jb21tYW5kGAEgASgJUg9leGVjdXRlZENvbW1hbmQSIgoMcmVxX29ial'
    '9wYXRoGAIgASgJSABSCnJlcU9ialBhdGgSVQoPcmVxX291dHB1dF9hcmdzGAMgASgLMisudXNw'
    'Lk9wZXJhdGVSZXNwLk9wZXJhdGlvblJlc3VsdC5PdXRwdXRBcmdzSABSDXJlcU91dHB1dEFyZ3'
    'MSUgoLY21kX2ZhaWx1cmUYBCABKAsyLy51c3AuT3BlcmF0ZVJlc3AuT3BlcmF0aW9uUmVzdWx0'
    'LkNvbW1hbmRGYWlsdXJlSABSCmNtZEZhaWx1cmUaqQEKCk91dHB1dEFyZ3MSXAoLb3V0cHV0X2'
    'FyZ3MYASADKAsyOy51c3AuT3BlcmF0ZVJlc3AuT3BlcmF0aW9uUmVzdWx0Lk91dHB1dEFyZ3Mu'
    'T3V0cHV0QXJnc0VudHJ5UgpvdXRwdXRBcmdzGj0KD091dHB1dEFyZ3NFbnRyeRIQCgNrZXkYAS'
    'ABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGkQKDkNvbW1hbmRGYWlsdXJlEhkK'
    'CGVycl9jb2RlGAEgASgHUgdlcnJDb2RlEhcKB2Vycl9tc2cYAiABKAlSBmVyck1zZ0IQCg5vcG'
    'VyYXRpb25fcmVzcA==');

@$core.Deprecated('Use notifyDescriptor instead')
const Notify$json = {
  '1': 'Notify',
  '2': [
    {'1': 'subscription_id', '3': 1, '4': 1, '5': 9, '10': 'subscriptionId'},
    {'1': 'send_resp', '3': 2, '4': 1, '5': 8, '10': 'sendResp'},
    {
      '1': 'event',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.usp.Notify.Event',
      '9': 0,
      '10': 'event'
    },
    {
      '1': 'value_change',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.usp.Notify.ValueChange',
      '9': 0,
      '10': 'valueChange'
    },
    {
      '1': 'obj_creation',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.usp.Notify.ObjectCreation',
      '9': 0,
      '10': 'objCreation'
    },
    {
      '1': 'obj_deletion',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.usp.Notify.ObjectDeletion',
      '9': 0,
      '10': 'objDeletion'
    },
    {
      '1': 'oper_complete',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.usp.Notify.OperationComplete',
      '9': 0,
      '10': 'operComplete'
    },
    {
      '1': 'on_board_req',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.usp.Notify.OnBoardRequest',
      '9': 0,
      '10': 'onBoardReq'
    },
  ],
  '3': [
    Notify_Event$json,
    Notify_ValueChange$json,
    Notify_ObjectCreation$json,
    Notify_ObjectDeletion$json,
    Notify_OperationComplete$json,
    Notify_OnBoardRequest$json
  ],
  '8': [
    {'1': 'notification'},
  ],
};

@$core.Deprecated('Use notifyDescriptor instead')
const Notify_Event$json = {
  '1': 'Event',
  '2': [
    {'1': 'obj_path', '3': 1, '4': 1, '5': 9, '10': 'objPath'},
    {'1': 'event_name', '3': 2, '4': 1, '5': 9, '10': 'eventName'},
    {
      '1': 'params',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.usp.Notify.Event.ParamsEntry',
      '10': 'params'
    },
  ],
  '3': [Notify_Event_ParamsEntry$json],
};

@$core.Deprecated('Use notifyDescriptor instead')
const Notify_Event_ParamsEntry$json = {
  '1': 'ParamsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use notifyDescriptor instead')
const Notify_ValueChange$json = {
  '1': 'ValueChange',
  '2': [
    {'1': 'param_path', '3': 1, '4': 1, '5': 9, '10': 'paramPath'},
    {'1': 'param_value', '3': 2, '4': 1, '5': 9, '10': 'paramValue'},
  ],
};

@$core.Deprecated('Use notifyDescriptor instead')
const Notify_ObjectCreation$json = {
  '1': 'ObjectCreation',
  '2': [
    {'1': 'obj_path', '3': 1, '4': 1, '5': 9, '10': 'objPath'},
    {
      '1': 'unique_keys',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.usp.Notify.ObjectCreation.UniqueKeysEntry',
      '10': 'uniqueKeys'
    },
  ],
  '3': [Notify_ObjectCreation_UniqueKeysEntry$json],
};

@$core.Deprecated('Use notifyDescriptor instead')
const Notify_ObjectCreation_UniqueKeysEntry$json = {
  '1': 'UniqueKeysEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use notifyDescriptor instead')
const Notify_ObjectDeletion$json = {
  '1': 'ObjectDeletion',
  '2': [
    {'1': 'obj_path', '3': 1, '4': 1, '5': 9, '10': 'objPath'},
  ],
};

@$core.Deprecated('Use notifyDescriptor instead')
const Notify_OperationComplete$json = {
  '1': 'OperationComplete',
  '2': [
    {'1': 'obj_path', '3': 1, '4': 1, '5': 9, '10': 'objPath'},
    {'1': 'command_name', '3': 2, '4': 1, '5': 9, '10': 'commandName'},
    {'1': 'command_key', '3': 3, '4': 1, '5': 9, '10': 'commandKey'},
    {
      '1': 'req_output_args',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.usp.Notify.OperationComplete.OutputArgs',
      '9': 0,
      '10': 'reqOutputArgs'
    },
    {
      '1': 'cmd_failure',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.usp.Notify.OperationComplete.CommandFailure',
      '9': 0,
      '10': 'cmdFailure'
    },
  ],
  '3': [
    Notify_OperationComplete_OutputArgs$json,
    Notify_OperationComplete_CommandFailure$json
  ],
  '8': [
    {'1': 'operation_resp'},
  ],
};

@$core.Deprecated('Use notifyDescriptor instead')
const Notify_OperationComplete_OutputArgs$json = {
  '1': 'OutputArgs',
  '2': [
    {
      '1': 'output_args',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.usp.Notify.OperationComplete.OutputArgs.OutputArgsEntry',
      '10': 'outputArgs'
    },
  ],
  '3': [Notify_OperationComplete_OutputArgs_OutputArgsEntry$json],
};

@$core.Deprecated('Use notifyDescriptor instead')
const Notify_OperationComplete_OutputArgs_OutputArgsEntry$json = {
  '1': 'OutputArgsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use notifyDescriptor instead')
const Notify_OperationComplete_CommandFailure$json = {
  '1': 'CommandFailure',
  '2': [
    {'1': 'err_code', '3': 1, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 2, '4': 1, '5': 9, '10': 'errMsg'},
  ],
};

@$core.Deprecated('Use notifyDescriptor instead')
const Notify_OnBoardRequest$json = {
  '1': 'OnBoardRequest',
  '2': [
    {'1': 'oui', '3': 1, '4': 1, '5': 9, '10': 'oui'},
    {'1': 'product_class', '3': 2, '4': 1, '5': 9, '10': 'productClass'},
    {'1': 'serial_number', '3': 3, '4': 1, '5': 9, '10': 'serialNumber'},
    {
      '1': 'agent_supported_protocol_versions',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'agentSupportedProtocolVersions'
    },
  ],
};

/// Descriptor for `Notify`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notifyDescriptor = $convert.base64Decode(
    'CgZOb3RpZnkSJwoPc3Vic2NyaXB0aW9uX2lkGAEgASgJUg5zdWJzY3JpcHRpb25JZBIbCglzZW'
    '5kX3Jlc3AYAiABKAhSCHNlbmRSZXNwEikKBWV2ZW50GAMgASgLMhEudXNwLk5vdGlmeS5FdmVu'
    'dEgAUgVldmVudBI8Cgx2YWx1ZV9jaGFuZ2UYBCABKAsyFy51c3AuTm90aWZ5LlZhbHVlQ2hhbm'
    'dlSABSC3ZhbHVlQ2hhbmdlEj8KDG9ial9jcmVhdGlvbhgFIAEoCzIaLnVzcC5Ob3RpZnkuT2Jq'
    'ZWN0Q3JlYXRpb25IAFILb2JqQ3JlYXRpb24SPwoMb2JqX2RlbGV0aW9uGAYgASgLMhoudXNwLk'
    '5vdGlmeS5PYmplY3REZWxldGlvbkgAUgtvYmpEZWxldGlvbhJECg1vcGVyX2NvbXBsZXRlGAcg'
    'ASgLMh0udXNwLk5vdGlmeS5PcGVyYXRpb25Db21wbGV0ZUgAUgxvcGVyQ29tcGxldGUSPgoMb2'
    '5fYm9hcmRfcmVxGAggASgLMhoudXNwLk5vdGlmeS5PbkJvYXJkUmVxdWVzdEgAUgpvbkJvYXJk'
    'UmVxGrMBCgVFdmVudBIZCghvYmpfcGF0aBgBIAEoCVIHb2JqUGF0aBIdCgpldmVudF9uYW1lGA'
    'IgASgJUglldmVudE5hbWUSNQoGcGFyYW1zGAMgAygLMh0udXNwLk5vdGlmeS5FdmVudC5QYXJh'
    'bXNFbnRyeVIGcGFyYW1zGjkKC1BhcmFtc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbH'
    'VlGAIgASgJUgV2YWx1ZToCOAEaTQoLVmFsdWVDaGFuZ2USHQoKcGFyYW1fcGF0aBgBIAEoCVIJ'
    'cGFyYW1QYXRoEh8KC3BhcmFtX3ZhbHVlGAIgASgJUgpwYXJhbVZhbHVlGrcBCg5PYmplY3RDcm'
    'VhdGlvbhIZCghvYmpfcGF0aBgBIAEoCVIHb2JqUGF0aBJLCgt1bmlxdWVfa2V5cxgCIAMoCzIq'
    'LnVzcC5Ob3RpZnkuT2JqZWN0Q3JlYXRpb24uVW5pcXVlS2V5c0VudHJ5Ugp1bmlxdWVLZXlzGj'
    '0KD1VuaXF1ZUtleXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFs'
    'dWU6AjgBGisKDk9iamVjdERlbGV0aW9uEhkKCG9ial9wYXRoGAEgASgJUgdvYmpQYXRoGpgECh'
    'FPcGVyYXRpb25Db21wbGV0ZRIZCghvYmpfcGF0aBgBIAEoCVIHb2JqUGF0aBIhCgxjb21tYW5k'
    'X25hbWUYAiABKAlSC2NvbW1hbmROYW1lEh8KC2NvbW1hbmRfa2V5GAMgASgJUgpjb21tYW5kS2'
    'V5ElIKD3JlcV9vdXRwdXRfYXJncxgEIAEoCzIoLnVzcC5Ob3RpZnkuT3BlcmF0aW9uQ29tcGxl'
    'dGUuT3V0cHV0QXJnc0gAUg1yZXFPdXRwdXRBcmdzEk8KC2NtZF9mYWlsdXJlGAUgASgLMiwudX'
    'NwLk5vdGlmeS5PcGVyYXRpb25Db21wbGV0ZS5Db21tYW5kRmFpbHVyZUgAUgpjbWRGYWlsdXJl'
    'GqYBCgpPdXRwdXRBcmdzElkKC291dHB1dF9hcmdzGAEgAygLMjgudXNwLk5vdGlmeS5PcGVyYX'
    'Rpb25Db21wbGV0ZS5PdXRwdXRBcmdzLk91dHB1dEFyZ3NFbnRyeVIKb3V0cHV0QXJncxo9Cg9P'
    'dXRwdXRBcmdzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOg'
    'I4ARpECg5Db21tYW5kRmFpbHVyZRIZCghlcnJfY29kZRgBIAEoB1IHZXJyQ29kZRIXCgdlcnJf'
    'bXNnGAIgASgJUgZlcnJNc2dCEAoOb3BlcmF0aW9uX3Jlc3AatwEKDk9uQm9hcmRSZXF1ZXN0Eh'
    'AKA291aRgBIAEoCVIDb3VpEiMKDXByb2R1Y3RfY2xhc3MYAiABKAlSDHByb2R1Y3RDbGFzcxIj'
    'Cg1zZXJpYWxfbnVtYmVyGAMgASgJUgxzZXJpYWxOdW1iZXISSQohYWdlbnRfc3VwcG9ydGVkX3'
    'Byb3RvY29sX3ZlcnNpb25zGAQgASgJUh5hZ2VudFN1cHBvcnRlZFByb3RvY29sVmVyc2lvbnNC'
    'DgoMbm90aWZpY2F0aW9u');

@$core.Deprecated('Use notifyRespDescriptor instead')
const NotifyResp$json = {
  '1': 'NotifyResp',
  '2': [
    {'1': 'subscription_id', '3': 1, '4': 1, '5': 9, '10': 'subscriptionId'},
  ],
};

/// Descriptor for `NotifyResp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notifyRespDescriptor = $convert.base64Decode(
    'CgpOb3RpZnlSZXNwEicKD3N1YnNjcmlwdGlvbl9pZBgBIAEoCVIOc3Vic2NyaXB0aW9uSWQ=');

@$core.Deprecated('Use registerDescriptor instead')
const Register$json = {
  '1': 'Register',
  '2': [
    {'1': 'allow_partial', '3': 1, '4': 1, '5': 8, '10': 'allowPartial'},
    {
      '1': 'reg_paths',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.usp.Register.RegistrationPath',
      '10': 'regPaths'
    },
  ],
  '3': [Register_RegistrationPath$json],
};

@$core.Deprecated('Use registerDescriptor instead')
const Register_RegistrationPath$json = {
  '1': 'RegistrationPath',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `Register`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerDescriptor = $convert.base64Decode(
    'CghSZWdpc3RlchIjCg1hbGxvd19wYXJ0aWFsGAEgASgIUgxhbGxvd1BhcnRpYWwSOwoJcmVnX3'
    'BhdGhzGAIgAygLMh4udXNwLlJlZ2lzdGVyLlJlZ2lzdHJhdGlvblBhdGhSCHJlZ1BhdGhzGiYK'
    'EFJlZ2lzdHJhdGlvblBhdGgSEgoEcGF0aBgBIAEoCVIEcGF0aA==');

@$core.Deprecated('Use registerRespDescriptor instead')
const RegisterResp$json = {
  '1': 'RegisterResp',
  '2': [
    {
      '1': 'registered_path_results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.usp.RegisterResp.RegisteredPathResult',
      '10': 'registeredPathResults'
    },
  ],
  '3': [RegisterResp_RegisteredPathResult$json],
};

@$core.Deprecated('Use registerRespDescriptor instead')
const RegisterResp_RegisteredPathResult$json = {
  '1': 'RegisteredPathResult',
  '2': [
    {'1': 'requested_path', '3': 1, '4': 1, '5': 9, '10': 'requestedPath'},
    {
      '1': 'oper_status',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.usp.RegisterResp.RegisteredPathResult.OperationStatus',
      '10': 'operStatus'
    },
  ],
  '3': [RegisterResp_RegisteredPathResult_OperationStatus$json],
};

@$core.Deprecated('Use registerRespDescriptor instead')
const RegisterResp_RegisteredPathResult_OperationStatus$json = {
  '1': 'OperationStatus',
  '2': [
    {
      '1': 'oper_failure',
      '3': 1,
      '4': 1,
      '5': 11,
      '6':
          '.usp.RegisterResp.RegisteredPathResult.OperationStatus.OperationFailure',
      '9': 0,
      '10': 'operFailure'
    },
    {
      '1': 'oper_success',
      '3': 2,
      '4': 1,
      '5': 11,
      '6':
          '.usp.RegisterResp.RegisteredPathResult.OperationStatus.OperationSuccess',
      '9': 0,
      '10': 'operSuccess'
    },
  ],
  '3': [
    RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure$json,
    RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess$json
  ],
  '8': [
    {'1': 'oper_status'},
  ],
};

@$core.Deprecated('Use registerRespDescriptor instead')
const RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure$json =
    {
  '1': 'OperationFailure',
  '2': [
    {'1': 'err_code', '3': 1, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 2, '4': 1, '5': 9, '10': 'errMsg'},
  ],
};

@$core.Deprecated('Use registerRespDescriptor instead')
const RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess$json =
    {
  '1': 'OperationSuccess',
  '2': [
    {'1': 'registered_path', '3': 1, '4': 1, '5': 9, '10': 'registeredPath'},
  ],
};

/// Descriptor for `RegisterResp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List registerRespDescriptor = $convert.base64Decode(
    'CgxSZWdpc3RlclJlc3ASXgoXcmVnaXN0ZXJlZF9wYXRoX3Jlc3VsdHMYASADKAsyJi51c3AuUm'
    'VnaXN0ZXJSZXNwLlJlZ2lzdGVyZWRQYXRoUmVzdWx0UhVyZWdpc3RlcmVkUGF0aFJlc3VsdHMa'
    'mgQKFFJlZ2lzdGVyZWRQYXRoUmVzdWx0EiUKDnJlcXVlc3RlZF9wYXRoGAEgASgJUg1yZXF1ZX'
    'N0ZWRQYXRoElcKC29wZXJfc3RhdHVzGAIgASgLMjYudXNwLlJlZ2lzdGVyUmVzcC5SZWdpc3Rl'
    'cmVkUGF0aFJlc3VsdC5PcGVyYXRpb25TdGF0dXNSCm9wZXJTdGF0dXMagQMKD09wZXJhdGlvbl'
    'N0YXR1cxJsCgxvcGVyX2ZhaWx1cmUYASABKAsyRy51c3AuUmVnaXN0ZXJSZXNwLlJlZ2lzdGVy'
    'ZWRQYXRoUmVzdWx0Lk9wZXJhdGlvblN0YXR1cy5PcGVyYXRpb25GYWlsdXJlSABSC29wZXJGYW'
    'lsdXJlEmwKDG9wZXJfc3VjY2VzcxgCIAEoCzJHLnVzcC5SZWdpc3RlclJlc3AuUmVnaXN0ZXJl'
    'ZFBhdGhSZXN1bHQuT3BlcmF0aW9uU3RhdHVzLk9wZXJhdGlvblN1Y2Nlc3NIAFILb3BlclN1Y2'
    'Nlc3MaRgoQT3BlcmF0aW9uRmFpbHVyZRIZCghlcnJfY29kZRgBIAEoB1IHZXJyQ29kZRIXCgdl'
    'cnJfbXNnGAIgASgJUgZlcnJNc2caOwoQT3BlcmF0aW9uU3VjY2VzcxInCg9yZWdpc3RlcmVkX3'
    'BhdGgYASABKAlSDnJlZ2lzdGVyZWRQYXRoQg0KC29wZXJfc3RhdHVz');

@$core.Deprecated('Use deregisterDescriptor instead')
const Deregister$json = {
  '1': 'Deregister',
  '2': [
    {'1': 'paths', '3': 1, '4': 3, '5': 9, '10': 'paths'},
  ],
};

/// Descriptor for `Deregister`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deregisterDescriptor =
    $convert.base64Decode('CgpEZXJlZ2lzdGVyEhQKBXBhdGhzGAEgAygJUgVwYXRocw==');

@$core.Deprecated('Use deregisterRespDescriptor instead')
const DeregisterResp$json = {
  '1': 'DeregisterResp',
  '2': [
    {
      '1': 'deregistered_path_results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.usp.DeregisterResp.DeregisteredPathResult',
      '10': 'deregisteredPathResults'
    },
  ],
  '3': [DeregisterResp_DeregisteredPathResult$json],
};

@$core.Deprecated('Use deregisterRespDescriptor instead')
const DeregisterResp_DeregisteredPathResult$json = {
  '1': 'DeregisteredPathResult',
  '2': [
    {'1': 'requested_path', '3': 1, '4': 1, '5': 9, '10': 'requestedPath'},
    {
      '1': 'oper_status',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.usp.DeregisterResp.DeregisteredPathResult.OperationStatus',
      '10': 'operStatus'
    },
  ],
  '3': [DeregisterResp_DeregisteredPathResult_OperationStatus$json],
};

@$core.Deprecated('Use deregisterRespDescriptor instead')
const DeregisterResp_DeregisteredPathResult_OperationStatus$json = {
  '1': 'OperationStatus',
  '2': [
    {
      '1': 'oper_failure',
      '3': 1,
      '4': 1,
      '5': 11,
      '6':
          '.usp.DeregisterResp.DeregisteredPathResult.OperationStatus.OperationFailure',
      '9': 0,
      '10': 'operFailure'
    },
    {
      '1': 'oper_success',
      '3': 2,
      '4': 1,
      '5': 11,
      '6':
          '.usp.DeregisterResp.DeregisteredPathResult.OperationStatus.OperationSuccess',
      '9': 0,
      '10': 'operSuccess'
    },
  ],
  '3': [
    DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure$json,
    DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess$json
  ],
  '8': [
    {'1': 'oper_status'},
  ],
};

@$core.Deprecated('Use deregisterRespDescriptor instead')
const DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure$json =
    {
  '1': 'OperationFailure',
  '2': [
    {'1': 'err_code', '3': 1, '4': 1, '5': 7, '10': 'errCode'},
    {'1': 'err_msg', '3': 2, '4': 1, '5': 9, '10': 'errMsg'},
  ],
};

@$core.Deprecated('Use deregisterRespDescriptor instead')
const DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess$json =
    {
  '1': 'OperationSuccess',
  '2': [
    {
      '1': 'deregistered_path',
      '3': 1,
      '4': 3,
      '5': 9,
      '10': 'deregisteredPath'
    },
  ],
};

/// Descriptor for `DeregisterResp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deregisterRespDescriptor = $convert.base64Decode(
    'Cg5EZXJlZ2lzdGVyUmVzcBJmChlkZXJlZ2lzdGVyZWRfcGF0aF9yZXN1bHRzGAEgAygLMioudX'
    'NwLkRlcmVnaXN0ZXJSZXNwLkRlcmVnaXN0ZXJlZFBhdGhSZXN1bHRSF2RlcmVnaXN0ZXJlZFBh'
    'dGhSZXN1bHRzGqwEChZEZXJlZ2lzdGVyZWRQYXRoUmVzdWx0EiUKDnJlcXVlc3RlZF9wYXRoGA'
    'EgASgJUg1yZXF1ZXN0ZWRQYXRoElsKC29wZXJfc3RhdHVzGAIgASgLMjoudXNwLkRlcmVnaXN0'
    'ZXJSZXNwLkRlcmVnaXN0ZXJlZFBhdGhSZXN1bHQuT3BlcmF0aW9uU3RhdHVzUgpvcGVyU3RhdH'
    'VzGo0DCg9PcGVyYXRpb25TdGF0dXMScAoMb3Blcl9mYWlsdXJlGAEgASgLMksudXNwLkRlcmVn'
    'aXN0ZXJSZXNwLkRlcmVnaXN0ZXJlZFBhdGhSZXN1bHQuT3BlcmF0aW9uU3RhdHVzLk9wZXJhdG'
    'lvbkZhaWx1cmVIAFILb3BlckZhaWx1cmUScAoMb3Blcl9zdWNjZXNzGAIgASgLMksudXNwLkRl'
    'cmVnaXN0ZXJSZXNwLkRlcmVnaXN0ZXJlZFBhdGhSZXN1bHQuT3BlcmF0aW9uU3RhdHVzLk9wZX'
    'JhdGlvblN1Y2Nlc3NIAFILb3BlclN1Y2Nlc3MaRgoQT3BlcmF0aW9uRmFpbHVyZRIZCghlcnJf'
    'Y29kZRgBIAEoB1IHZXJyQ29kZRIXCgdlcnJfbXNnGAIgASgJUgZlcnJNc2caPwoQT3BlcmF0aW'
    '9uU3VjY2VzcxIrChFkZXJlZ2lzdGVyZWRfcGF0aBgBIAMoCVIQZGVyZWdpc3RlcmVkUGF0aEIN'
    'CgtvcGVyX3N0YXR1cw==');
