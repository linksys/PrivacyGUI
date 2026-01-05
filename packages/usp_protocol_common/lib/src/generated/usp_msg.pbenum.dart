// This is a generated file - do not edit.
//
// Generated from usp_msg.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Header_MsgType extends $pb.ProtobufEnum {
  static const Header_MsgType ERROR =
      Header_MsgType._(0, _omitEnumNames ? '' : 'ERROR');
  static const Header_MsgType GET =
      Header_MsgType._(1, _omitEnumNames ? '' : 'GET');
  static const Header_MsgType GET_RESP =
      Header_MsgType._(2, _omitEnumNames ? '' : 'GET_RESP');
  static const Header_MsgType NOTIFY =
      Header_MsgType._(3, _omitEnumNames ? '' : 'NOTIFY');
  static const Header_MsgType SET =
      Header_MsgType._(4, _omitEnumNames ? '' : 'SET');
  static const Header_MsgType SET_RESP =
      Header_MsgType._(5, _omitEnumNames ? '' : 'SET_RESP');
  static const Header_MsgType OPERATE =
      Header_MsgType._(6, _omitEnumNames ? '' : 'OPERATE');
  static const Header_MsgType OPERATE_RESP =
      Header_MsgType._(7, _omitEnumNames ? '' : 'OPERATE_RESP');
  static const Header_MsgType ADD =
      Header_MsgType._(8, _omitEnumNames ? '' : 'ADD');
  static const Header_MsgType ADD_RESP =
      Header_MsgType._(9, _omitEnumNames ? '' : 'ADD_RESP');
  static const Header_MsgType DELETE =
      Header_MsgType._(10, _omitEnumNames ? '' : 'DELETE');
  static const Header_MsgType DELETE_RESP =
      Header_MsgType._(11, _omitEnumNames ? '' : 'DELETE_RESP');
  static const Header_MsgType GET_SUPPORTED_DM =
      Header_MsgType._(12, _omitEnumNames ? '' : 'GET_SUPPORTED_DM');
  static const Header_MsgType GET_SUPPORTED_DM_RESP =
      Header_MsgType._(13, _omitEnumNames ? '' : 'GET_SUPPORTED_DM_RESP');
  static const Header_MsgType GET_INSTANCES =
      Header_MsgType._(14, _omitEnumNames ? '' : 'GET_INSTANCES');
  static const Header_MsgType GET_INSTANCES_RESP =
      Header_MsgType._(15, _omitEnumNames ? '' : 'GET_INSTANCES_RESP');
  static const Header_MsgType NOTIFY_RESP =
      Header_MsgType._(16, _omitEnumNames ? '' : 'NOTIFY_RESP');
  static const Header_MsgType GET_SUPPORTED_PROTO =
      Header_MsgType._(17, _omitEnumNames ? '' : 'GET_SUPPORTED_PROTO');
  static const Header_MsgType GET_SUPPORTED_PROTO_RESP =
      Header_MsgType._(18, _omitEnumNames ? '' : 'GET_SUPPORTED_PROTO_RESP');
  static const Header_MsgType REGISTER =
      Header_MsgType._(19, _omitEnumNames ? '' : 'REGISTER');
  static const Header_MsgType REGISTER_RESP =
      Header_MsgType._(20, _omitEnumNames ? '' : 'REGISTER_RESP');
  static const Header_MsgType DEREGISTER =
      Header_MsgType._(21, _omitEnumNames ? '' : 'DEREGISTER');
  static const Header_MsgType DEREGISTER_RESP =
      Header_MsgType._(22, _omitEnumNames ? '' : 'DEREGISTER_RESP');

  static const $core.List<Header_MsgType> values = <Header_MsgType>[
    ERROR,
    GET,
    GET_RESP,
    NOTIFY,
    SET,
    SET_RESP,
    OPERATE,
    OPERATE_RESP,
    ADD,
    ADD_RESP,
    DELETE,
    DELETE_RESP,
    GET_SUPPORTED_DM,
    GET_SUPPORTED_DM_RESP,
    GET_INSTANCES,
    GET_INSTANCES_RESP,
    NOTIFY_RESP,
    GET_SUPPORTED_PROTO,
    GET_SUPPORTED_PROTO_RESP,
    REGISTER,
    REGISTER_RESP,
    DEREGISTER,
    DEREGISTER_RESP,
  ];

  static final $core.List<Header_MsgType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 22);
  static Header_MsgType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Header_MsgType._(super.value, super.name);
}

class GetSupportedDMResp_ParamAccessType extends $pb.ProtobufEnum {
  static const GetSupportedDMResp_ParamAccessType PARAM_READ_ONLY =
      GetSupportedDMResp_ParamAccessType._(
          0, _omitEnumNames ? '' : 'PARAM_READ_ONLY');
  static const GetSupportedDMResp_ParamAccessType PARAM_READ_WRITE =
      GetSupportedDMResp_ParamAccessType._(
          1, _omitEnumNames ? '' : 'PARAM_READ_WRITE');
  static const GetSupportedDMResp_ParamAccessType PARAM_WRITE_ONLY =
      GetSupportedDMResp_ParamAccessType._(
          2, _omitEnumNames ? '' : 'PARAM_WRITE_ONLY');

  static const $core.List<GetSupportedDMResp_ParamAccessType> values =
      <GetSupportedDMResp_ParamAccessType>[
    PARAM_READ_ONLY,
    PARAM_READ_WRITE,
    PARAM_WRITE_ONLY,
  ];

  static final $core.List<GetSupportedDMResp_ParamAccessType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static GetSupportedDMResp_ParamAccessType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GetSupportedDMResp_ParamAccessType._(super.value, super.name);
}

class GetSupportedDMResp_ObjAccessType extends $pb.ProtobufEnum {
  static const GetSupportedDMResp_ObjAccessType OBJ_READ_ONLY =
      GetSupportedDMResp_ObjAccessType._(
          0, _omitEnumNames ? '' : 'OBJ_READ_ONLY');
  static const GetSupportedDMResp_ObjAccessType OBJ_ADD_DELETE =
      GetSupportedDMResp_ObjAccessType._(
          1, _omitEnumNames ? '' : 'OBJ_ADD_DELETE');
  static const GetSupportedDMResp_ObjAccessType OBJ_ADD_ONLY =
      GetSupportedDMResp_ObjAccessType._(
          2, _omitEnumNames ? '' : 'OBJ_ADD_ONLY');
  static const GetSupportedDMResp_ObjAccessType OBJ_DELETE_ONLY =
      GetSupportedDMResp_ObjAccessType._(
          3, _omitEnumNames ? '' : 'OBJ_DELETE_ONLY');

  static const $core.List<GetSupportedDMResp_ObjAccessType> values =
      <GetSupportedDMResp_ObjAccessType>[
    OBJ_READ_ONLY,
    OBJ_ADD_DELETE,
    OBJ_ADD_ONLY,
    OBJ_DELETE_ONLY,
  ];

  static final $core.List<GetSupportedDMResp_ObjAccessType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static GetSupportedDMResp_ObjAccessType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GetSupportedDMResp_ObjAccessType._(super.value, super.name);
}

class GetSupportedDMResp_ParamValueType extends $pb.ProtobufEnum {
  static const GetSupportedDMResp_ParamValueType PARAM_UNKNOWN =
      GetSupportedDMResp_ParamValueType._(
          0, _omitEnumNames ? '' : 'PARAM_UNKNOWN');
  static const GetSupportedDMResp_ParamValueType PARAM_BASE_64 =
      GetSupportedDMResp_ParamValueType._(
          1, _omitEnumNames ? '' : 'PARAM_BASE_64');
  static const GetSupportedDMResp_ParamValueType PARAM_BOOLEAN =
      GetSupportedDMResp_ParamValueType._(
          2, _omitEnumNames ? '' : 'PARAM_BOOLEAN');
  static const GetSupportedDMResp_ParamValueType PARAM_DATE_TIME =
      GetSupportedDMResp_ParamValueType._(
          3, _omitEnumNames ? '' : 'PARAM_DATE_TIME');
  static const GetSupportedDMResp_ParamValueType PARAM_DECIMAL =
      GetSupportedDMResp_ParamValueType._(
          4, _omitEnumNames ? '' : 'PARAM_DECIMAL');
  static const GetSupportedDMResp_ParamValueType PARAM_HEX_BINARY =
      GetSupportedDMResp_ParamValueType._(
          5, _omitEnumNames ? '' : 'PARAM_HEX_BINARY');
  static const GetSupportedDMResp_ParamValueType PARAM_INT =
      GetSupportedDMResp_ParamValueType._(6, _omitEnumNames ? '' : 'PARAM_INT');
  static const GetSupportedDMResp_ParamValueType PARAM_LONG =
      GetSupportedDMResp_ParamValueType._(
          7, _omitEnumNames ? '' : 'PARAM_LONG');
  static const GetSupportedDMResp_ParamValueType PARAM_STRING =
      GetSupportedDMResp_ParamValueType._(
          8, _omitEnumNames ? '' : 'PARAM_STRING');
  static const GetSupportedDMResp_ParamValueType PARAM_UNSIGNED_INT =
      GetSupportedDMResp_ParamValueType._(
          9, _omitEnumNames ? '' : 'PARAM_UNSIGNED_INT');
  static const GetSupportedDMResp_ParamValueType PARAM_UNSIGNED_LONG =
      GetSupportedDMResp_ParamValueType._(
          10, _omitEnumNames ? '' : 'PARAM_UNSIGNED_LONG');

  static const $core.List<GetSupportedDMResp_ParamValueType> values =
      <GetSupportedDMResp_ParamValueType>[
    PARAM_UNKNOWN,
    PARAM_BASE_64,
    PARAM_BOOLEAN,
    PARAM_DATE_TIME,
    PARAM_DECIMAL,
    PARAM_HEX_BINARY,
    PARAM_INT,
    PARAM_LONG,
    PARAM_STRING,
    PARAM_UNSIGNED_INT,
    PARAM_UNSIGNED_LONG,
  ];

  static final $core.List<GetSupportedDMResp_ParamValueType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 10);
  static GetSupportedDMResp_ParamValueType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GetSupportedDMResp_ParamValueType._(super.value, super.name);
}

class GetSupportedDMResp_ValueChangeType extends $pb.ProtobufEnum {
  static const GetSupportedDMResp_ValueChangeType VALUE_CHANGE_UNKNOWN =
      GetSupportedDMResp_ValueChangeType._(
          0, _omitEnumNames ? '' : 'VALUE_CHANGE_UNKNOWN');
  static const GetSupportedDMResp_ValueChangeType VALUE_CHANGE_ALLOWED =
      GetSupportedDMResp_ValueChangeType._(
          1, _omitEnumNames ? '' : 'VALUE_CHANGE_ALLOWED');
  static const GetSupportedDMResp_ValueChangeType VALUE_CHANGE_WILL_IGNORE =
      GetSupportedDMResp_ValueChangeType._(
          2, _omitEnumNames ? '' : 'VALUE_CHANGE_WILL_IGNORE');

  static const $core.List<GetSupportedDMResp_ValueChangeType> values =
      <GetSupportedDMResp_ValueChangeType>[
    VALUE_CHANGE_UNKNOWN,
    VALUE_CHANGE_ALLOWED,
    VALUE_CHANGE_WILL_IGNORE,
  ];

  static final $core.List<GetSupportedDMResp_ValueChangeType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static GetSupportedDMResp_ValueChangeType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GetSupportedDMResp_ValueChangeType._(super.value, super.name);
}

class GetSupportedDMResp_CmdType extends $pb.ProtobufEnum {
  static const GetSupportedDMResp_CmdType CMD_UNKNOWN =
      GetSupportedDMResp_CmdType._(0, _omitEnumNames ? '' : 'CMD_UNKNOWN');
  static const GetSupportedDMResp_CmdType CMD_SYNC =
      GetSupportedDMResp_CmdType._(1, _omitEnumNames ? '' : 'CMD_SYNC');
  static const GetSupportedDMResp_CmdType CMD_ASYNC =
      GetSupportedDMResp_CmdType._(2, _omitEnumNames ? '' : 'CMD_ASYNC');

  static const $core.List<GetSupportedDMResp_CmdType> values =
      <GetSupportedDMResp_CmdType>[
    CMD_UNKNOWN,
    CMD_SYNC,
    CMD_ASYNC,
  ];

  static final $core.List<GetSupportedDMResp_CmdType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static GetSupportedDMResp_CmdType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const GetSupportedDMResp_CmdType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
