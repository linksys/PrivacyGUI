// This is a generated file - do not edit.
//
// Generated from usp_transport.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use uspTransportRequestDescriptor instead')
const UspTransportRequest$json = {
  '1': 'UspTransportRequest',
  '2': [
    {
      '1': 'usp_record_payload',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'uspRecordPayload'
    },
  ],
};

/// Descriptor for `UspTransportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uspTransportRequestDescriptor = $convert.base64Decode(
    'ChNVc3BUcmFuc3BvcnRSZXF1ZXN0EiwKEnVzcF9yZWNvcmRfcGF5bG9hZBgBIAEoDFIQdXNwUm'
    'Vjb3JkUGF5bG9hZA==');

@$core.Deprecated('Use uspTransportResponseDescriptor instead')
const UspTransportResponse$json = {
  '1': 'UspTransportResponse',
  '2': [
    {
      '1': 'usp_record_response',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'uspRecordResponse'
    },
  ],
};

/// Descriptor for `UspTransportResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uspTransportResponseDescriptor = $convert.base64Decode(
    'ChRVc3BUcmFuc3BvcnRSZXNwb25zZRIuChN1c3BfcmVjb3JkX3Jlc3BvbnNlGAEgASgMUhF1c3'
    'BSZWNvcmRSZXNwb25zZQ==');
