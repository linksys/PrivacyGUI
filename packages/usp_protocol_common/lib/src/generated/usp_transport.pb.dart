// This is a generated file - do not edit.
//
// Generated from usp_transport.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// This is the request sent by the Client to the Router Gateway/Proxy
class UspTransportRequest extends $pb.GeneratedMessage {
  factory UspTransportRequest({
    $core.List<$core.int>? uspRecordPayload,
  }) {
    final result = create();
    if (uspRecordPayload != null) result.uspRecordPayload = uspRecordPayload;
    return result;
  }

  UspTransportRequest._();

  factory UspTransportRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UspTransportRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UspTransportRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp_transport'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'uspRecordPayload', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UspTransportRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UspTransportRequest copyWith(void Function(UspTransportRequest) updates) =>
      super.copyWith((message) => updates(message as UspTransportRequest))
          as UspTransportRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UspTransportRequest create() => UspTransportRequest._();
  @$core.override
  UspTransportRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UspTransportRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UspTransportRequest>(create);
  static UspTransportRequest? _defaultInstance;

  /// The serialized USP Record binary data
  @$pb.TagNumber(1)
  $core.List<$core.int> get uspRecordPayload => $_getN(0);
  @$pb.TagNumber(1)
  set uspRecordPayload($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUspRecordPayload() => $_has(0);
  @$pb.TagNumber(1)
  void clearUspRecordPayload() => $_clearField(1);
}

/// This is the response returned by the Proxy to the Client
class UspTransportResponse extends $pb.GeneratedMessage {
  factory UspTransportResponse({
    $core.List<$core.int>? uspRecordResponse,
  }) {
    final result = create();
    if (uspRecordResponse != null) result.uspRecordResponse = uspRecordResponse;
    return result;
  }

  UspTransportResponse._();

  factory UspTransportResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UspTransportResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UspTransportResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp_transport'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'uspRecordResponse', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UspTransportResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UspTransportResponse copyWith(void Function(UspTransportResponse) updates) =>
      super.copyWith((message) => updates(message as UspTransportResponse))
          as UspTransportResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UspTransportResponse create() => UspTransportResponse._();
  @$core.override
  UspTransportResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UspTransportResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UspTransportResponse>(create);
  static UspTransportResponse? _defaultInstance;

  /// The USP Record binary data returned after Agent processing
  @$pb.TagNumber(1)
  $core.List<$core.int> get uspRecordResponse => $_getN(0);
  @$pb.TagNumber(1)
  set uspRecordResponse($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUspRecordResponse() => $_has(0);
  @$pb.TagNumber(1)
  void clearUspRecordResponse() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
