// This is a generated file - do not edit.
//
// Generated from usp_record.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Record_PayloadSecurity extends $pb.ProtobufEnum {
  static const Record_PayloadSecurity PLAINTEXT =
      Record_PayloadSecurity._(0, _omitEnumNames ? '' : 'PLAINTEXT');
  static const Record_PayloadSecurity TLS12 =
      Record_PayloadSecurity._(1, _omitEnumNames ? '' : 'TLS12');

  static const $core.List<Record_PayloadSecurity> values =
      <Record_PayloadSecurity>[
    PLAINTEXT,
    TLS12,
  ];

  static final $core.List<Record_PayloadSecurity?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static Record_PayloadSecurity? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Record_PayloadSecurity._(super.value, super.name);
}

class SessionContextRecord_PayloadSARState extends $pb.ProtobufEnum {
  static const SessionContextRecord_PayloadSARState NONE =
      SessionContextRecord_PayloadSARState._(0, _omitEnumNames ? '' : 'NONE');
  static const SessionContextRecord_PayloadSARState BEGIN =
      SessionContextRecord_PayloadSARState._(1, _omitEnumNames ? '' : 'BEGIN');
  static const SessionContextRecord_PayloadSARState INPROCESS =
      SessionContextRecord_PayloadSARState._(
          2, _omitEnumNames ? '' : 'INPROCESS');
  static const SessionContextRecord_PayloadSARState COMPLETE =
      SessionContextRecord_PayloadSARState._(
          3, _omitEnumNames ? '' : 'COMPLETE');

  static const $core.List<SessionContextRecord_PayloadSARState> values =
      <SessionContextRecord_PayloadSARState>[
    NONE,
    BEGIN,
    INPROCESS,
    COMPLETE,
  ];

  static final $core.List<SessionContextRecord_PayloadSARState?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static SessionContextRecord_PayloadSARState? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SessionContextRecord_PayloadSARState._(super.value, super.name);
}

class MQTTConnectRecord_MQTTVersion extends $pb.ProtobufEnum {
  static const MQTTConnectRecord_MQTTVersion V3_1_1 =
      MQTTConnectRecord_MQTTVersion._(0, _omitEnumNames ? '' : 'V3_1_1');
  static const MQTTConnectRecord_MQTTVersion V5 =
      MQTTConnectRecord_MQTTVersion._(1, _omitEnumNames ? '' : 'V5');

  static const $core.List<MQTTConnectRecord_MQTTVersion> values =
      <MQTTConnectRecord_MQTTVersion>[
    V3_1_1,
    V5,
  ];

  static final $core.List<MQTTConnectRecord_MQTTVersion?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static MQTTConnectRecord_MQTTVersion? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MQTTConnectRecord_MQTTVersion._(super.value, super.name);
}

class STOMPConnectRecord_STOMPVersion extends $pb.ProtobufEnum {
  static const STOMPConnectRecord_STOMPVersion V1_2 =
      STOMPConnectRecord_STOMPVersion._(0, _omitEnumNames ? '' : 'V1_2');

  static const $core.List<STOMPConnectRecord_STOMPVersion> values =
      <STOMPConnectRecord_STOMPVersion>[
    V1_2,
  ];

  static final $core.List<STOMPConnectRecord_STOMPVersion?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 0);
  static STOMPConnectRecord_STOMPVersion? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const STOMPConnectRecord_STOMPVersion._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
