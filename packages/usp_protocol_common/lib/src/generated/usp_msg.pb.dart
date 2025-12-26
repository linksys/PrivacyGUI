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

import 'usp_msg.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'usp_msg.pbenum.dart';

class Msg extends $pb.GeneratedMessage {
  factory Msg({
    Header? header,
    Body? body,
  }) {
    final result = create();
    if (header != null) result.header = header;
    if (body != null) result.body = body;
    return result;
  }

  Msg._();

  factory Msg.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Msg.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Msg',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOM<Header>(1, _omitFieldNames ? '' : 'header', subBuilder: Header.create)
    ..aOM<Body>(2, _omitFieldNames ? '' : 'body', subBuilder: Body.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Msg clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Msg copyWith(void Function(Msg) updates) =>
      super.copyWith((message) => updates(message as Msg)) as Msg;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Msg create() => Msg._();
  @$core.override
  Msg createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Msg getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Msg>(create);
  static Msg? _defaultInstance;

  @$pb.TagNumber(1)
  Header get header => $_getN(0);
  @$pb.TagNumber(1)
  set header(Header value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasHeader() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeader() => $_clearField(1);
  @$pb.TagNumber(1)
  Header ensureHeader() => $_ensure(0);

  @$pb.TagNumber(2)
  Body get body => $_getN(1);
  @$pb.TagNumber(2)
  set body(Body value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearBody() => $_clearField(2);
  @$pb.TagNumber(2)
  Body ensureBody() => $_ensure(1);
}

class Header extends $pb.GeneratedMessage {
  factory Header({
    $core.String? msgId,
    Header_MsgType? msgType,
  }) {
    final result = create();
    if (msgId != null) result.msgId = msgId;
    if (msgType != null) result.msgType = msgType;
    return result;
  }

  Header._();

  factory Header.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Header.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Header',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'msgId')
    ..aE<Header_MsgType>(2, _omitFieldNames ? '' : 'msgType',
        enumValues: Header_MsgType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Header clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Header copyWith(void Function(Header) updates) =>
      super.copyWith((message) => updates(message as Header)) as Header;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Header create() => Header._();
  @$core.override
  Header createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Header getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Header>(create);
  static Header? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get msgId => $_getSZ(0);
  @$pb.TagNumber(1)
  set msgId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMsgId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMsgId() => $_clearField(1);

  @$pb.TagNumber(2)
  Header_MsgType get msgType => $_getN(1);
  @$pb.TagNumber(2)
  set msgType(Header_MsgType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasMsgType() => $_has(1);
  @$pb.TagNumber(2)
  void clearMsgType() => $_clearField(2);
}

enum Body_MsgBody { request, response, error, notSet }

class Body extends $pb.GeneratedMessage {
  factory Body({
    Request? request,
    Response? response,
    Error? error,
  }) {
    final result = create();
    if (request != null) result.request = request;
    if (response != null) result.response = response;
    if (error != null) result.error = error;
    return result;
  }

  Body._();

  factory Body.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Body.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Body_MsgBody> _Body_MsgBodyByTag = {
    1: Body_MsgBody.request,
    2: Body_MsgBody.response,
    3: Body_MsgBody.error,
    0: Body_MsgBody.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Body',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<Request>(1, _omitFieldNames ? '' : 'request',
        subBuilder: Request.create)
    ..aOM<Response>(2, _omitFieldNames ? '' : 'response',
        subBuilder: Response.create)
    ..aOM<Error>(3, _omitFieldNames ? '' : 'error', subBuilder: Error.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Body clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Body copyWith(void Function(Body) updates) =>
      super.copyWith((message) => updates(message as Body)) as Body;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Body create() => Body._();
  @$core.override
  Body createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Body getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Body>(create);
  static Body? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  Body_MsgBody whichMsgBody() => _Body_MsgBodyByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  void clearMsgBody() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Request get request => $_getN(0);
  @$pb.TagNumber(1)
  set request(Request value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRequest() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequest() => $_clearField(1);
  @$pb.TagNumber(1)
  Request ensureRequest() => $_ensure(0);

  @$pb.TagNumber(2)
  Response get response => $_getN(1);
  @$pb.TagNumber(2)
  set response(Response value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasResponse() => $_has(1);
  @$pb.TagNumber(2)
  void clearResponse() => $_clearField(2);
  @$pb.TagNumber(2)
  Response ensureResponse() => $_ensure(1);

  @$pb.TagNumber(3)
  Error get error => $_getN(2);
  @$pb.TagNumber(3)
  set error(Error value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  Error ensureError() => $_ensure(2);
}

enum Request_ReqType {
  get,
  getSupportedDm,
  getInstances,
  set,
  add,
  delete,
  operate,
  notify,
  getSupportedProtocol,
  register,
  deregister,
  notSet
}

class Request extends $pb.GeneratedMessage {
  factory Request({
    Get? get,
    GetSupportedDM? getSupportedDm,
    GetInstances? getInstances,
    Set? set,
    Add? add,
    Delete? delete,
    Operate? operate,
    Notify? notify,
    GetSupportedProtocol? getSupportedProtocol,
    Register? register,
    Deregister? deregister,
  }) {
    final result = create();
    if (get != null) result.get = get;
    if (getSupportedDm != null) result.getSupportedDm = getSupportedDm;
    if (getInstances != null) result.getInstances = getInstances;
    if (set != null) result.set = set;
    if (add != null) result.add = add;
    if (delete != null) result.delete = delete;
    if (operate != null) result.operate = operate;
    if (notify != null) result.notify = notify;
    if (getSupportedProtocol != null)
      result.getSupportedProtocol = getSupportedProtocol;
    if (register != null) result.register = register;
    if (deregister != null) result.deregister = deregister;
    return result;
  }

  Request._();

  factory Request.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Request.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Request_ReqType> _Request_ReqTypeByTag = {
    1: Request_ReqType.get,
    2: Request_ReqType.getSupportedDm,
    3: Request_ReqType.getInstances,
    4: Request_ReqType.set,
    5: Request_ReqType.add,
    6: Request_ReqType.delete,
    7: Request_ReqType.operate,
    8: Request_ReqType.notify,
    9: Request_ReqType.getSupportedProtocol,
    10: Request_ReqType.register,
    11: Request_ReqType.deregister,
    0: Request_ReqType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Request',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
    ..aOM<Get>(1, _omitFieldNames ? '' : 'get', subBuilder: Get.create)
    ..aOM<GetSupportedDM>(2, _omitFieldNames ? '' : 'getSupportedDm',
        subBuilder: GetSupportedDM.create)
    ..aOM<GetInstances>(3, _omitFieldNames ? '' : 'getInstances',
        subBuilder: GetInstances.create)
    ..aOM<Set>(4, _omitFieldNames ? '' : 'set', subBuilder: Set.create)
    ..aOM<Add>(5, _omitFieldNames ? '' : 'add', subBuilder: Add.create)
    ..aOM<Delete>(6, _omitFieldNames ? '' : 'delete', subBuilder: Delete.create)
    ..aOM<Operate>(7, _omitFieldNames ? '' : 'operate',
        subBuilder: Operate.create)
    ..aOM<Notify>(8, _omitFieldNames ? '' : 'notify', subBuilder: Notify.create)
    ..aOM<GetSupportedProtocol>(
        9, _omitFieldNames ? '' : 'getSupportedProtocol',
        subBuilder: GetSupportedProtocol.create)
    ..aOM<Register>(10, _omitFieldNames ? '' : 'register',
        subBuilder: Register.create)
    ..aOM<Deregister>(11, _omitFieldNames ? '' : 'deregister',
        subBuilder: Deregister.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Request clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Request copyWith(void Function(Request) updates) =>
      super.copyWith((message) => updates(message as Request)) as Request;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Request create() => Request._();
  @$core.override
  Request createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Request getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Request>(create);
  static Request? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  Request_ReqType whichReqType() => _Request_ReqTypeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  void clearReqType() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Get get get => $_getN(0);
  @$pb.TagNumber(1)
  set get(Get value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasGet() => $_has(0);
  @$pb.TagNumber(1)
  void clearGet() => $_clearField(1);
  @$pb.TagNumber(1)
  Get ensureGet() => $_ensure(0);

  @$pb.TagNumber(2)
  GetSupportedDM get getSupportedDm => $_getN(1);
  @$pb.TagNumber(2)
  set getSupportedDm(GetSupportedDM value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasGetSupportedDm() => $_has(1);
  @$pb.TagNumber(2)
  void clearGetSupportedDm() => $_clearField(2);
  @$pb.TagNumber(2)
  GetSupportedDM ensureGetSupportedDm() => $_ensure(1);

  @$pb.TagNumber(3)
  GetInstances get getInstances => $_getN(2);
  @$pb.TagNumber(3)
  set getInstances(GetInstances value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasGetInstances() => $_has(2);
  @$pb.TagNumber(3)
  void clearGetInstances() => $_clearField(3);
  @$pb.TagNumber(3)
  GetInstances ensureGetInstances() => $_ensure(2);

  @$pb.TagNumber(4)
  Set get set => $_getN(3);
  @$pb.TagNumber(4)
  set set(Set value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSet() => $_has(3);
  @$pb.TagNumber(4)
  void clearSet() => $_clearField(4);
  @$pb.TagNumber(4)
  Set ensureSet() => $_ensure(3);

  @$pb.TagNumber(5)
  Add get add => $_getN(4);
  @$pb.TagNumber(5)
  set add(Add value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAdd() => $_has(4);
  @$pb.TagNumber(5)
  void clearAdd() => $_clearField(5);
  @$pb.TagNumber(5)
  Add ensureAdd() => $_ensure(4);

  @$pb.TagNumber(6)
  Delete get delete => $_getN(5);
  @$pb.TagNumber(6)
  set delete(Delete value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasDelete() => $_has(5);
  @$pb.TagNumber(6)
  void clearDelete() => $_clearField(6);
  @$pb.TagNumber(6)
  Delete ensureDelete() => $_ensure(5);

  @$pb.TagNumber(7)
  Operate get operate => $_getN(6);
  @$pb.TagNumber(7)
  set operate(Operate value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasOperate() => $_has(6);
  @$pb.TagNumber(7)
  void clearOperate() => $_clearField(7);
  @$pb.TagNumber(7)
  Operate ensureOperate() => $_ensure(6);

  @$pb.TagNumber(8)
  Notify get notify => $_getN(7);
  @$pb.TagNumber(8)
  set notify(Notify value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasNotify() => $_has(7);
  @$pb.TagNumber(8)
  void clearNotify() => $_clearField(8);
  @$pb.TagNumber(8)
  Notify ensureNotify() => $_ensure(7);

  @$pb.TagNumber(9)
  GetSupportedProtocol get getSupportedProtocol => $_getN(8);
  @$pb.TagNumber(9)
  set getSupportedProtocol(GetSupportedProtocol value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasGetSupportedProtocol() => $_has(8);
  @$pb.TagNumber(9)
  void clearGetSupportedProtocol() => $_clearField(9);
  @$pb.TagNumber(9)
  GetSupportedProtocol ensureGetSupportedProtocol() => $_ensure(8);

  @$pb.TagNumber(10)
  Register get register => $_getN(9);
  @$pb.TagNumber(10)
  set register(Register value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasRegister() => $_has(9);
  @$pb.TagNumber(10)
  void clearRegister() => $_clearField(10);
  @$pb.TagNumber(10)
  Register ensureRegister() => $_ensure(9);

  @$pb.TagNumber(11)
  Deregister get deregister => $_getN(10);
  @$pb.TagNumber(11)
  set deregister(Deregister value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasDeregister() => $_has(10);
  @$pb.TagNumber(11)
  void clearDeregister() => $_clearField(11);
  @$pb.TagNumber(11)
  Deregister ensureDeregister() => $_ensure(10);
}

enum Response_RespType {
  getResp,
  getSupportedDmResp,
  getInstancesResp,
  setResp,
  addResp,
  deleteResp,
  operateResp,
  notifyResp,
  getSupportedProtocolResp,
  registerResp,
  deregisterResp,
  notSet
}

class Response extends $pb.GeneratedMessage {
  factory Response({
    GetResp? getResp,
    GetSupportedDMResp? getSupportedDmResp,
    GetInstancesResp? getInstancesResp,
    SetResp? setResp,
    AddResp? addResp,
    DeleteResp? deleteResp,
    OperateResp? operateResp,
    NotifyResp? notifyResp,
    GetSupportedProtocolResp? getSupportedProtocolResp,
    RegisterResp? registerResp,
    DeregisterResp? deregisterResp,
  }) {
    final result = create();
    if (getResp != null) result.getResp = getResp;
    if (getSupportedDmResp != null)
      result.getSupportedDmResp = getSupportedDmResp;
    if (getInstancesResp != null) result.getInstancesResp = getInstancesResp;
    if (setResp != null) result.setResp = setResp;
    if (addResp != null) result.addResp = addResp;
    if (deleteResp != null) result.deleteResp = deleteResp;
    if (operateResp != null) result.operateResp = operateResp;
    if (notifyResp != null) result.notifyResp = notifyResp;
    if (getSupportedProtocolResp != null)
      result.getSupportedProtocolResp = getSupportedProtocolResp;
    if (registerResp != null) result.registerResp = registerResp;
    if (deregisterResp != null) result.deregisterResp = deregisterResp;
    return result;
  }

  Response._();

  factory Response.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Response_RespType> _Response_RespTypeByTag =
      {
    1: Response_RespType.getResp,
    2: Response_RespType.getSupportedDmResp,
    3: Response_RespType.getInstancesResp,
    4: Response_RespType.setResp,
    5: Response_RespType.addResp,
    6: Response_RespType.deleteResp,
    7: Response_RespType.operateResp,
    8: Response_RespType.notifyResp,
    9: Response_RespType.getSupportedProtocolResp,
    10: Response_RespType.registerResp,
    11: Response_RespType.deregisterResp,
    0: Response_RespType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
    ..aOM<GetResp>(1, _omitFieldNames ? '' : 'getResp',
        subBuilder: GetResp.create)
    ..aOM<GetSupportedDMResp>(2, _omitFieldNames ? '' : 'getSupportedDmResp',
        subBuilder: GetSupportedDMResp.create)
    ..aOM<GetInstancesResp>(3, _omitFieldNames ? '' : 'getInstancesResp',
        subBuilder: GetInstancesResp.create)
    ..aOM<SetResp>(4, _omitFieldNames ? '' : 'setResp',
        subBuilder: SetResp.create)
    ..aOM<AddResp>(5, _omitFieldNames ? '' : 'addResp',
        subBuilder: AddResp.create)
    ..aOM<DeleteResp>(6, _omitFieldNames ? '' : 'deleteResp',
        subBuilder: DeleteResp.create)
    ..aOM<OperateResp>(7, _omitFieldNames ? '' : 'operateResp',
        subBuilder: OperateResp.create)
    ..aOM<NotifyResp>(8, _omitFieldNames ? '' : 'notifyResp',
        subBuilder: NotifyResp.create)
    ..aOM<GetSupportedProtocolResp>(
        9, _omitFieldNames ? '' : 'getSupportedProtocolResp',
        subBuilder: GetSupportedProtocolResp.create)
    ..aOM<RegisterResp>(10, _omitFieldNames ? '' : 'registerResp',
        subBuilder: RegisterResp.create)
    ..aOM<DeregisterResp>(11, _omitFieldNames ? '' : 'deregisterResp',
        subBuilder: DeregisterResp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response copyWith(void Function(Response) updates) =>
      super.copyWith((message) => updates(message as Response)) as Response;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response create() => Response._();
  @$core.override
  Response createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response>(create);
  static Response? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  Response_RespType whichRespType() =>
      _Response_RespTypeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  void clearRespType() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  GetResp get getResp => $_getN(0);
  @$pb.TagNumber(1)
  set getResp(GetResp value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasGetResp() => $_has(0);
  @$pb.TagNumber(1)
  void clearGetResp() => $_clearField(1);
  @$pb.TagNumber(1)
  GetResp ensureGetResp() => $_ensure(0);

  @$pb.TagNumber(2)
  GetSupportedDMResp get getSupportedDmResp => $_getN(1);
  @$pb.TagNumber(2)
  set getSupportedDmResp(GetSupportedDMResp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasGetSupportedDmResp() => $_has(1);
  @$pb.TagNumber(2)
  void clearGetSupportedDmResp() => $_clearField(2);
  @$pb.TagNumber(2)
  GetSupportedDMResp ensureGetSupportedDmResp() => $_ensure(1);

  @$pb.TagNumber(3)
  GetInstancesResp get getInstancesResp => $_getN(2);
  @$pb.TagNumber(3)
  set getInstancesResp(GetInstancesResp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasGetInstancesResp() => $_has(2);
  @$pb.TagNumber(3)
  void clearGetInstancesResp() => $_clearField(3);
  @$pb.TagNumber(3)
  GetInstancesResp ensureGetInstancesResp() => $_ensure(2);

  @$pb.TagNumber(4)
  SetResp get setResp => $_getN(3);
  @$pb.TagNumber(4)
  set setResp(SetResp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSetResp() => $_has(3);
  @$pb.TagNumber(4)
  void clearSetResp() => $_clearField(4);
  @$pb.TagNumber(4)
  SetResp ensureSetResp() => $_ensure(3);

  @$pb.TagNumber(5)
  AddResp get addResp => $_getN(4);
  @$pb.TagNumber(5)
  set addResp(AddResp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasAddResp() => $_has(4);
  @$pb.TagNumber(5)
  void clearAddResp() => $_clearField(5);
  @$pb.TagNumber(5)
  AddResp ensureAddResp() => $_ensure(4);

  @$pb.TagNumber(6)
  DeleteResp get deleteResp => $_getN(5);
  @$pb.TagNumber(6)
  set deleteResp(DeleteResp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasDeleteResp() => $_has(5);
  @$pb.TagNumber(6)
  void clearDeleteResp() => $_clearField(6);
  @$pb.TagNumber(6)
  DeleteResp ensureDeleteResp() => $_ensure(5);

  @$pb.TagNumber(7)
  OperateResp get operateResp => $_getN(6);
  @$pb.TagNumber(7)
  set operateResp(OperateResp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasOperateResp() => $_has(6);
  @$pb.TagNumber(7)
  void clearOperateResp() => $_clearField(7);
  @$pb.TagNumber(7)
  OperateResp ensureOperateResp() => $_ensure(6);

  @$pb.TagNumber(8)
  NotifyResp get notifyResp => $_getN(7);
  @$pb.TagNumber(8)
  set notifyResp(NotifyResp value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasNotifyResp() => $_has(7);
  @$pb.TagNumber(8)
  void clearNotifyResp() => $_clearField(8);
  @$pb.TagNumber(8)
  NotifyResp ensureNotifyResp() => $_ensure(7);

  @$pb.TagNumber(9)
  GetSupportedProtocolResp get getSupportedProtocolResp => $_getN(8);
  @$pb.TagNumber(9)
  set getSupportedProtocolResp(GetSupportedProtocolResp value) =>
      $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasGetSupportedProtocolResp() => $_has(8);
  @$pb.TagNumber(9)
  void clearGetSupportedProtocolResp() => $_clearField(9);
  @$pb.TagNumber(9)
  GetSupportedProtocolResp ensureGetSupportedProtocolResp() => $_ensure(8);

  @$pb.TagNumber(10)
  RegisterResp get registerResp => $_getN(9);
  @$pb.TagNumber(10)
  set registerResp(RegisterResp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasRegisterResp() => $_has(9);
  @$pb.TagNumber(10)
  void clearRegisterResp() => $_clearField(10);
  @$pb.TagNumber(10)
  RegisterResp ensureRegisterResp() => $_ensure(9);

  @$pb.TagNumber(11)
  DeregisterResp get deregisterResp => $_getN(10);
  @$pb.TagNumber(11)
  set deregisterResp(DeregisterResp value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasDeregisterResp() => $_has(10);
  @$pb.TagNumber(11)
  void clearDeregisterResp() => $_clearField(11);
  @$pb.TagNumber(11)
  DeregisterResp ensureDeregisterResp() => $_ensure(10);
}

class Error_ParamError extends $pb.GeneratedMessage {
  factory Error_ParamError({
    $core.String? paramPath,
    $core.int? errCode,
    $core.String? errMsg,
  }) {
    final result = create();
    if (paramPath != null) result.paramPath = paramPath;
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    return result;
  }

  Error_ParamError._();

  factory Error_ParamError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Error_ParamError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Error.ParamError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'paramPath')
    ..aI(2, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(3, _omitFieldNames ? '' : 'errMsg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Error_ParamError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Error_ParamError copyWith(void Function(Error_ParamError) updates) =>
      super.copyWith((message) => updates(message as Error_ParamError))
          as Error_ParamError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Error_ParamError create() => Error_ParamError._();
  @$core.override
  Error_ParamError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Error_ParamError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Error_ParamError>(create);
  static Error_ParamError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get paramPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set paramPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParamPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearParamPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get errCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set errCode($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get errMsg => $_getSZ(2);
  @$pb.TagNumber(3)
  set errMsg($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasErrMsg() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrMsg() => $_clearField(3);
}

class Error extends $pb.GeneratedMessage {
  factory Error({
    $core.int? errCode,
    $core.String? errMsg,
    $core.Iterable<Error_ParamError>? paramErrs,
  }) {
    final result = create();
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    if (paramErrs != null) result.paramErrs.addAll(paramErrs);
    return result;
  }

  Error._();

  factory Error.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Error.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Error',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(2, _omitFieldNames ? '' : 'errMsg')
    ..pPM<Error_ParamError>(3, _omitFieldNames ? '' : 'paramErrs',
        subBuilder: Error_ParamError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Error clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Error copyWith(void Function(Error) updates) =>
      super.copyWith((message) => updates(message as Error)) as Error;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Error create() => Error._();
  @$core.override
  Error createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Error getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Error>(create);
  static Error? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get errCode => $_getIZ(0);
  @$pb.TagNumber(1)
  set errCode($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasErrCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearErrCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errMsg => $_getSZ(1);
  @$pb.TagNumber(2)
  set errMsg($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrMsg() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrMsg() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<Error_ParamError> get paramErrs => $_getList(2);
}

class Get extends $pb.GeneratedMessage {
  factory Get({
    $core.Iterable<$core.String>? paramPaths,
    $core.int? maxDepth,
  }) {
    final result = create();
    if (paramPaths != null) result.paramPaths.addAll(paramPaths);
    if (maxDepth != null) result.maxDepth = maxDepth;
    return result;
  }

  Get._();

  factory Get.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Get.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Get',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'paramPaths')
    ..aI(2, _omitFieldNames ? '' : 'maxDepth', fieldType: $pb.PbFieldType.OF3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Get clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Get copyWith(void Function(Get) updates) =>
      super.copyWith((message) => updates(message as Get)) as Get;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Get create() => Get._();
  @$core.override
  Get createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Get getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Get>(create);
  static Get? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get paramPaths => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get maxDepth => $_getIZ(1);
  @$pb.TagNumber(2)
  set maxDepth($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMaxDepth() => $_has(1);
  @$pb.TagNumber(2)
  void clearMaxDepth() => $_clearField(2);
}

class GetResp_RequestedPathResult extends $pb.GeneratedMessage {
  factory GetResp_RequestedPathResult({
    $core.String? requestedPath,
    $core.int? errCode,
    $core.String? errMsg,
    $core.Iterable<GetResp_ResolvedPathResult>? resolvedPathResults,
  }) {
    final result = create();
    if (requestedPath != null) result.requestedPath = requestedPath;
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    if (resolvedPathResults != null)
      result.resolvedPathResults.addAll(resolvedPathResults);
    return result;
  }

  GetResp_RequestedPathResult._();

  factory GetResp_RequestedPathResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetResp_RequestedPathResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetResp.RequestedPathResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestedPath')
    ..aI(2, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(3, _omitFieldNames ? '' : 'errMsg')
    ..pPM<GetResp_ResolvedPathResult>(
        4, _omitFieldNames ? '' : 'resolvedPathResults',
        subBuilder: GetResp_ResolvedPathResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetResp_RequestedPathResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetResp_RequestedPathResult copyWith(
          void Function(GetResp_RequestedPathResult) updates) =>
      super.copyWith(
              (message) => updates(message as GetResp_RequestedPathResult))
          as GetResp_RequestedPathResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetResp_RequestedPathResult create() =>
      GetResp_RequestedPathResult._();
  @$core.override
  GetResp_RequestedPathResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetResp_RequestedPathResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetResp_RequestedPathResult>(create);
  static GetResp_RequestedPathResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestedPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestedPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestedPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestedPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get errCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set errCode($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get errMsg => $_getSZ(2);
  @$pb.TagNumber(3)
  set errMsg($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasErrMsg() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrMsg() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<GetResp_ResolvedPathResult> get resolvedPathResults =>
      $_getList(3);
}

class GetResp_ResolvedPathResult extends $pb.GeneratedMessage {
  factory GetResp_ResolvedPathResult({
    $core.String? resolvedPath,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? resultParams,
  }) {
    final result = create();
    if (resolvedPath != null) result.resolvedPath = resolvedPath;
    if (resultParams != null) result.resultParams.addEntries(resultParams);
    return result;
  }

  GetResp_ResolvedPathResult._();

  factory GetResp_ResolvedPathResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetResp_ResolvedPathResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetResp.ResolvedPathResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'resolvedPath')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'resultParams',
        entryClassName: 'GetResp.ResolvedPathResult.ResultParamsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('usp'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetResp_ResolvedPathResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetResp_ResolvedPathResult copyWith(
          void Function(GetResp_ResolvedPathResult) updates) =>
      super.copyWith(
              (message) => updates(message as GetResp_ResolvedPathResult))
          as GetResp_ResolvedPathResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetResp_ResolvedPathResult create() => GetResp_ResolvedPathResult._();
  @$core.override
  GetResp_ResolvedPathResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetResp_ResolvedPathResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetResp_ResolvedPathResult>(create);
  static GetResp_ResolvedPathResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get resolvedPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set resolvedPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasResolvedPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearResolvedPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get resultParams => $_getMap(1);
}

class GetResp extends $pb.GeneratedMessage {
  factory GetResp({
    $core.Iterable<GetResp_RequestedPathResult>? reqPathResults,
  }) {
    final result = create();
    if (reqPathResults != null) result.reqPathResults.addAll(reqPathResults);
    return result;
  }

  GetResp._();

  factory GetResp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetResp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetResp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPM<GetResp_RequestedPathResult>(
        1, _omitFieldNames ? '' : 'reqPathResults',
        subBuilder: GetResp_RequestedPathResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetResp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetResp copyWith(void Function(GetResp) updates) =>
      super.copyWith((message) => updates(message as GetResp)) as GetResp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetResp create() => GetResp._();
  @$core.override
  GetResp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetResp getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetResp>(create);
  static GetResp? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<GetResp_RequestedPathResult> get reqPathResults => $_getList(0);
}

class GetSupportedDM extends $pb.GeneratedMessage {
  factory GetSupportedDM({
    $core.Iterable<$core.String>? objPaths,
    $core.bool? firstLevelOnly,
    $core.bool? returnCommands,
    $core.bool? returnEvents,
    $core.bool? returnParams,
    $core.bool? returnUniqueKeySets,
  }) {
    final result = create();
    if (objPaths != null) result.objPaths.addAll(objPaths);
    if (firstLevelOnly != null) result.firstLevelOnly = firstLevelOnly;
    if (returnCommands != null) result.returnCommands = returnCommands;
    if (returnEvents != null) result.returnEvents = returnEvents;
    if (returnParams != null) result.returnParams = returnParams;
    if (returnUniqueKeySets != null)
      result.returnUniqueKeySets = returnUniqueKeySets;
    return result;
  }

  GetSupportedDM._();

  factory GetSupportedDM.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSupportedDM.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSupportedDM',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'objPaths')
    ..aOB(2, _omitFieldNames ? '' : 'firstLevelOnly')
    ..aOB(3, _omitFieldNames ? '' : 'returnCommands')
    ..aOB(4, _omitFieldNames ? '' : 'returnEvents')
    ..aOB(5, _omitFieldNames ? '' : 'returnParams')
    ..aOB(6, _omitFieldNames ? '' : 'returnUniqueKeySets')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDM clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDM copyWith(void Function(GetSupportedDM) updates) =>
      super.copyWith((message) => updates(message as GetSupportedDM))
          as GetSupportedDM;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSupportedDM create() => GetSupportedDM._();
  @$core.override
  GetSupportedDM createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSupportedDM getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSupportedDM>(create);
  static GetSupportedDM? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get objPaths => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get firstLevelOnly => $_getBF(1);
  @$pb.TagNumber(2)
  set firstLevelOnly($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFirstLevelOnly() => $_has(1);
  @$pb.TagNumber(2)
  void clearFirstLevelOnly() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get returnCommands => $_getBF(2);
  @$pb.TagNumber(3)
  set returnCommands($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReturnCommands() => $_has(2);
  @$pb.TagNumber(3)
  void clearReturnCommands() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get returnEvents => $_getBF(3);
  @$pb.TagNumber(4)
  set returnEvents($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReturnEvents() => $_has(3);
  @$pb.TagNumber(4)
  void clearReturnEvents() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get returnParams => $_getBF(4);
  @$pb.TagNumber(5)
  set returnParams($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReturnParams() => $_has(4);
  @$pb.TagNumber(5)
  void clearReturnParams() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get returnUniqueKeySets => $_getBF(5);
  @$pb.TagNumber(6)
  set returnUniqueKeySets($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReturnUniqueKeySets() => $_has(5);
  @$pb.TagNumber(6)
  void clearReturnUniqueKeySets() => $_clearField(6);
}

class GetSupportedDMResp_RequestedObjectResult extends $pb.GeneratedMessage {
  factory GetSupportedDMResp_RequestedObjectResult({
    $core.String? reqObjPath,
    $core.int? errCode,
    $core.String? errMsg,
    $core.String? dataModelInstUri,
    $core.Iterable<GetSupportedDMResp_SupportedObjectResult>? supportedObjs,
  }) {
    final result = create();
    if (reqObjPath != null) result.reqObjPath = reqObjPath;
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    if (dataModelInstUri != null) result.dataModelInstUri = dataModelInstUri;
    if (supportedObjs != null) result.supportedObjs.addAll(supportedObjs);
    return result;
  }

  GetSupportedDMResp_RequestedObjectResult._();

  factory GetSupportedDMResp_RequestedObjectResult.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSupportedDMResp_RequestedObjectResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSupportedDMResp.RequestedObjectResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'reqObjPath')
    ..aI(2, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(3, _omitFieldNames ? '' : 'errMsg')
    ..aOS(4, _omitFieldNames ? '' : 'dataModelInstUri')
    ..pPM<GetSupportedDMResp_SupportedObjectResult>(
        5, _omitFieldNames ? '' : 'supportedObjs',
        subBuilder: GetSupportedDMResp_SupportedObjectResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp_RequestedObjectResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp_RequestedObjectResult copyWith(
          void Function(GetSupportedDMResp_RequestedObjectResult) updates) =>
      super.copyWith((message) =>
              updates(message as GetSupportedDMResp_RequestedObjectResult))
          as GetSupportedDMResp_RequestedObjectResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp_RequestedObjectResult create() =>
      GetSupportedDMResp_RequestedObjectResult._();
  @$core.override
  GetSupportedDMResp_RequestedObjectResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp_RequestedObjectResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          GetSupportedDMResp_RequestedObjectResult>(create);
  static GetSupportedDMResp_RequestedObjectResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get reqObjPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set reqObjPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReqObjPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearReqObjPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get errCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set errCode($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get errMsg => $_getSZ(2);
  @$pb.TagNumber(3)
  set errMsg($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasErrMsg() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrMsg() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get dataModelInstUri => $_getSZ(3);
  @$pb.TagNumber(4)
  set dataModelInstUri($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDataModelInstUri() => $_has(3);
  @$pb.TagNumber(4)
  void clearDataModelInstUri() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<GetSupportedDMResp_SupportedObjectResult> get supportedObjs =>
      $_getList(4);
}

class GetSupportedDMResp_SupportedObjectResult extends $pb.GeneratedMessage {
  factory GetSupportedDMResp_SupportedObjectResult({
    $core.String? supportedObjPath,
    GetSupportedDMResp_ObjAccessType? access,
    $core.bool? isMultiInstance,
    $core.Iterable<GetSupportedDMResp_SupportedCommandResult>?
        supportedCommands,
    $core.Iterable<GetSupportedDMResp_SupportedEventResult>? supportedEvents,
    $core.Iterable<GetSupportedDMResp_SupportedParamResult>? supportedParams,
    $core.Iterable<$core.String>? divergentPaths,
    $core.Iterable<GetSupportedDMResp_SupportedUniqueKeySet>? uniqueKeySets,
  }) {
    final result = create();
    if (supportedObjPath != null) result.supportedObjPath = supportedObjPath;
    if (access != null) result.access = access;
    if (isMultiInstance != null) result.isMultiInstance = isMultiInstance;
    if (supportedCommands != null)
      result.supportedCommands.addAll(supportedCommands);
    if (supportedEvents != null) result.supportedEvents.addAll(supportedEvents);
    if (supportedParams != null) result.supportedParams.addAll(supportedParams);
    if (divergentPaths != null) result.divergentPaths.addAll(divergentPaths);
    if (uniqueKeySets != null) result.uniqueKeySets.addAll(uniqueKeySets);
    return result;
  }

  GetSupportedDMResp_SupportedObjectResult._();

  factory GetSupportedDMResp_SupportedObjectResult.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSupportedDMResp_SupportedObjectResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSupportedDMResp.SupportedObjectResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'supportedObjPath')
    ..aE<GetSupportedDMResp_ObjAccessType>(2, _omitFieldNames ? '' : 'access',
        enumValues: GetSupportedDMResp_ObjAccessType.values)
    ..aOB(3, _omitFieldNames ? '' : 'isMultiInstance')
    ..pPM<GetSupportedDMResp_SupportedCommandResult>(
        4, _omitFieldNames ? '' : 'supportedCommands',
        subBuilder: GetSupportedDMResp_SupportedCommandResult.create)
    ..pPM<GetSupportedDMResp_SupportedEventResult>(
        5, _omitFieldNames ? '' : 'supportedEvents',
        subBuilder: GetSupportedDMResp_SupportedEventResult.create)
    ..pPM<GetSupportedDMResp_SupportedParamResult>(
        6, _omitFieldNames ? '' : 'supportedParams',
        subBuilder: GetSupportedDMResp_SupportedParamResult.create)
    ..pPS(7, _omitFieldNames ? '' : 'divergentPaths')
    ..pPM<GetSupportedDMResp_SupportedUniqueKeySet>(
        8, _omitFieldNames ? '' : 'uniqueKeySets',
        subBuilder: GetSupportedDMResp_SupportedUniqueKeySet.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp_SupportedObjectResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp_SupportedObjectResult copyWith(
          void Function(GetSupportedDMResp_SupportedObjectResult) updates) =>
      super.copyWith((message) =>
              updates(message as GetSupportedDMResp_SupportedObjectResult))
          as GetSupportedDMResp_SupportedObjectResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp_SupportedObjectResult create() =>
      GetSupportedDMResp_SupportedObjectResult._();
  @$core.override
  GetSupportedDMResp_SupportedObjectResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp_SupportedObjectResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          GetSupportedDMResp_SupportedObjectResult>(create);
  static GetSupportedDMResp_SupportedObjectResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get supportedObjPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set supportedObjPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSupportedObjPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearSupportedObjPath() => $_clearField(1);

  @$pb.TagNumber(2)
  GetSupportedDMResp_ObjAccessType get access => $_getN(1);
  @$pb.TagNumber(2)
  set access(GetSupportedDMResp_ObjAccessType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAccess() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccess() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isMultiInstance => $_getBF(2);
  @$pb.TagNumber(3)
  set isMultiInstance($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsMultiInstance() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsMultiInstance() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<GetSupportedDMResp_SupportedCommandResult> get supportedCommands =>
      $_getList(3);

  @$pb.TagNumber(5)
  $pb.PbList<GetSupportedDMResp_SupportedEventResult> get supportedEvents =>
      $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<GetSupportedDMResp_SupportedParamResult> get supportedParams =>
      $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get divergentPaths => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<GetSupportedDMResp_SupportedUniqueKeySet> get uniqueKeySets =>
      $_getList(7);
}

class GetSupportedDMResp_SupportedParamResult extends $pb.GeneratedMessage {
  factory GetSupportedDMResp_SupportedParamResult({
    $core.String? paramName,
    GetSupportedDMResp_ParamAccessType? access,
    GetSupportedDMResp_ParamValueType? valueType,
    GetSupportedDMResp_ValueChangeType? valueChange,
  }) {
    final result = create();
    if (paramName != null) result.paramName = paramName;
    if (access != null) result.access = access;
    if (valueType != null) result.valueType = valueType;
    if (valueChange != null) result.valueChange = valueChange;
    return result;
  }

  GetSupportedDMResp_SupportedParamResult._();

  factory GetSupportedDMResp_SupportedParamResult.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSupportedDMResp_SupportedParamResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSupportedDMResp.SupportedParamResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'paramName')
    ..aE<GetSupportedDMResp_ParamAccessType>(2, _omitFieldNames ? '' : 'access',
        enumValues: GetSupportedDMResp_ParamAccessType.values)
    ..aE<GetSupportedDMResp_ParamValueType>(
        3, _omitFieldNames ? '' : 'valueType',
        enumValues: GetSupportedDMResp_ParamValueType.values)
    ..aE<GetSupportedDMResp_ValueChangeType>(
        4, _omitFieldNames ? '' : 'valueChange',
        enumValues: GetSupportedDMResp_ValueChangeType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp_SupportedParamResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp_SupportedParamResult copyWith(
          void Function(GetSupportedDMResp_SupportedParamResult) updates) =>
      super.copyWith((message) =>
              updates(message as GetSupportedDMResp_SupportedParamResult))
          as GetSupportedDMResp_SupportedParamResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp_SupportedParamResult create() =>
      GetSupportedDMResp_SupportedParamResult._();
  @$core.override
  GetSupportedDMResp_SupportedParamResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp_SupportedParamResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          GetSupportedDMResp_SupportedParamResult>(create);
  static GetSupportedDMResp_SupportedParamResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get paramName => $_getSZ(0);
  @$pb.TagNumber(1)
  set paramName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParamName() => $_has(0);
  @$pb.TagNumber(1)
  void clearParamName() => $_clearField(1);

  @$pb.TagNumber(2)
  GetSupportedDMResp_ParamAccessType get access => $_getN(1);
  @$pb.TagNumber(2)
  set access(GetSupportedDMResp_ParamAccessType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAccess() => $_has(1);
  @$pb.TagNumber(2)
  void clearAccess() => $_clearField(2);

  @$pb.TagNumber(3)
  GetSupportedDMResp_ParamValueType get valueType => $_getN(2);
  @$pb.TagNumber(3)
  set valueType(GetSupportedDMResp_ParamValueType value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasValueType() => $_has(2);
  @$pb.TagNumber(3)
  void clearValueType() => $_clearField(3);

  @$pb.TagNumber(4)
  GetSupportedDMResp_ValueChangeType get valueChange => $_getN(3);
  @$pb.TagNumber(4)
  set valueChange(GetSupportedDMResp_ValueChangeType value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasValueChange() => $_has(3);
  @$pb.TagNumber(4)
  void clearValueChange() => $_clearField(4);
}

class GetSupportedDMResp_SupportedCommandResult extends $pb.GeneratedMessage {
  factory GetSupportedDMResp_SupportedCommandResult({
    $core.String? commandName,
    $core.Iterable<$core.String>? inputArgNames,
    $core.Iterable<$core.String>? outputArgNames,
    GetSupportedDMResp_CmdType? commandType,
  }) {
    final result = create();
    if (commandName != null) result.commandName = commandName;
    if (inputArgNames != null) result.inputArgNames.addAll(inputArgNames);
    if (outputArgNames != null) result.outputArgNames.addAll(outputArgNames);
    if (commandType != null) result.commandType = commandType;
    return result;
  }

  GetSupportedDMResp_SupportedCommandResult._();

  factory GetSupportedDMResp_SupportedCommandResult.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSupportedDMResp_SupportedCommandResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSupportedDMResp.SupportedCommandResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'commandName')
    ..pPS(2, _omitFieldNames ? '' : 'inputArgNames')
    ..pPS(3, _omitFieldNames ? '' : 'outputArgNames')
    ..aE<GetSupportedDMResp_CmdType>(4, _omitFieldNames ? '' : 'commandType',
        enumValues: GetSupportedDMResp_CmdType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp_SupportedCommandResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp_SupportedCommandResult copyWith(
          void Function(GetSupportedDMResp_SupportedCommandResult) updates) =>
      super.copyWith((message) =>
              updates(message as GetSupportedDMResp_SupportedCommandResult))
          as GetSupportedDMResp_SupportedCommandResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp_SupportedCommandResult create() =>
      GetSupportedDMResp_SupportedCommandResult._();
  @$core.override
  GetSupportedDMResp_SupportedCommandResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp_SupportedCommandResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          GetSupportedDMResp_SupportedCommandResult>(create);
  static GetSupportedDMResp_SupportedCommandResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get commandName => $_getSZ(0);
  @$pb.TagNumber(1)
  set commandName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCommandName() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommandName() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get inputArgNames => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get outputArgNames => $_getList(2);

  @$pb.TagNumber(4)
  GetSupportedDMResp_CmdType get commandType => $_getN(3);
  @$pb.TagNumber(4)
  set commandType(GetSupportedDMResp_CmdType value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCommandType() => $_has(3);
  @$pb.TagNumber(4)
  void clearCommandType() => $_clearField(4);
}

class GetSupportedDMResp_SupportedEventResult extends $pb.GeneratedMessage {
  factory GetSupportedDMResp_SupportedEventResult({
    $core.String? eventName,
    $core.Iterable<$core.String>? argNames,
  }) {
    final result = create();
    if (eventName != null) result.eventName = eventName;
    if (argNames != null) result.argNames.addAll(argNames);
    return result;
  }

  GetSupportedDMResp_SupportedEventResult._();

  factory GetSupportedDMResp_SupportedEventResult.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSupportedDMResp_SupportedEventResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSupportedDMResp.SupportedEventResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'eventName')
    ..pPS(2, _omitFieldNames ? '' : 'argNames')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp_SupportedEventResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp_SupportedEventResult copyWith(
          void Function(GetSupportedDMResp_SupportedEventResult) updates) =>
      super.copyWith((message) =>
              updates(message as GetSupportedDMResp_SupportedEventResult))
          as GetSupportedDMResp_SupportedEventResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp_SupportedEventResult create() =>
      GetSupportedDMResp_SupportedEventResult._();
  @$core.override
  GetSupportedDMResp_SupportedEventResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp_SupportedEventResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          GetSupportedDMResp_SupportedEventResult>(create);
  static GetSupportedDMResp_SupportedEventResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get eventName => $_getSZ(0);
  @$pb.TagNumber(1)
  set eventName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEventName() => $_has(0);
  @$pb.TagNumber(1)
  void clearEventName() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get argNames => $_getList(1);
}

class GetSupportedDMResp_SupportedUniqueKeySet extends $pb.GeneratedMessage {
  factory GetSupportedDMResp_SupportedUniqueKeySet({
    $core.Iterable<$core.String>? keyNames,
  }) {
    final result = create();
    if (keyNames != null) result.keyNames.addAll(keyNames);
    return result;
  }

  GetSupportedDMResp_SupportedUniqueKeySet._();

  factory GetSupportedDMResp_SupportedUniqueKeySet.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSupportedDMResp_SupportedUniqueKeySet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSupportedDMResp.SupportedUniqueKeySet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'keyNames')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp_SupportedUniqueKeySet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp_SupportedUniqueKeySet copyWith(
          void Function(GetSupportedDMResp_SupportedUniqueKeySet) updates) =>
      super.copyWith((message) =>
              updates(message as GetSupportedDMResp_SupportedUniqueKeySet))
          as GetSupportedDMResp_SupportedUniqueKeySet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp_SupportedUniqueKeySet create() =>
      GetSupportedDMResp_SupportedUniqueKeySet._();
  @$core.override
  GetSupportedDMResp_SupportedUniqueKeySet createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp_SupportedUniqueKeySet getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          GetSupportedDMResp_SupportedUniqueKeySet>(create);
  static GetSupportedDMResp_SupportedUniqueKeySet? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get keyNames => $_getList(0);
}

class GetSupportedDMResp extends $pb.GeneratedMessage {
  factory GetSupportedDMResp({
    $core.Iterable<GetSupportedDMResp_RequestedObjectResult>? reqObjResults,
  }) {
    final result = create();
    if (reqObjResults != null) result.reqObjResults.addAll(reqObjResults);
    return result;
  }

  GetSupportedDMResp._();

  factory GetSupportedDMResp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSupportedDMResp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSupportedDMResp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPM<GetSupportedDMResp_RequestedObjectResult>(
        1, _omitFieldNames ? '' : 'reqObjResults',
        subBuilder: GetSupportedDMResp_RequestedObjectResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedDMResp copyWith(void Function(GetSupportedDMResp) updates) =>
      super.copyWith((message) => updates(message as GetSupportedDMResp))
          as GetSupportedDMResp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp create() => GetSupportedDMResp._();
  @$core.override
  GetSupportedDMResp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSupportedDMResp getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSupportedDMResp>(create);
  static GetSupportedDMResp? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<GetSupportedDMResp_RequestedObjectResult> get reqObjResults =>
      $_getList(0);
}

class GetInstances extends $pb.GeneratedMessage {
  factory GetInstances({
    $core.Iterable<$core.String>? objPaths,
    $core.bool? firstLevelOnly,
  }) {
    final result = create();
    if (objPaths != null) result.objPaths.addAll(objPaths);
    if (firstLevelOnly != null) result.firstLevelOnly = firstLevelOnly;
    return result;
  }

  GetInstances._();

  factory GetInstances.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetInstances.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInstances',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'objPaths')
    ..aOB(2, _omitFieldNames ? '' : 'firstLevelOnly')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstances clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstances copyWith(void Function(GetInstances) updates) =>
      super.copyWith((message) => updates(message as GetInstances))
          as GetInstances;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetInstances create() => GetInstances._();
  @$core.override
  GetInstances createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetInstances getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetInstances>(create);
  static GetInstances? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get objPaths => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get firstLevelOnly => $_getBF(1);
  @$pb.TagNumber(2)
  set firstLevelOnly($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFirstLevelOnly() => $_has(1);
  @$pb.TagNumber(2)
  void clearFirstLevelOnly() => $_clearField(2);
}

class GetInstancesResp_RequestedPathResult extends $pb.GeneratedMessage {
  factory GetInstancesResp_RequestedPathResult({
    $core.String? requestedPath,
    $core.int? errCode,
    $core.String? errMsg,
    $core.Iterable<GetInstancesResp_CurrInstance>? currInsts,
  }) {
    final result = create();
    if (requestedPath != null) result.requestedPath = requestedPath;
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    if (currInsts != null) result.currInsts.addAll(currInsts);
    return result;
  }

  GetInstancesResp_RequestedPathResult._();

  factory GetInstancesResp_RequestedPathResult.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetInstancesResp_RequestedPathResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInstancesResp.RequestedPathResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestedPath')
    ..aI(2, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(3, _omitFieldNames ? '' : 'errMsg')
    ..pPM<GetInstancesResp_CurrInstance>(4, _omitFieldNames ? '' : 'currInsts',
        subBuilder: GetInstancesResp_CurrInstance.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstancesResp_RequestedPathResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstancesResp_RequestedPathResult copyWith(
          void Function(GetInstancesResp_RequestedPathResult) updates) =>
      super.copyWith((message) =>
              updates(message as GetInstancesResp_RequestedPathResult))
          as GetInstancesResp_RequestedPathResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetInstancesResp_RequestedPathResult create() =>
      GetInstancesResp_RequestedPathResult._();
  @$core.override
  GetInstancesResp_RequestedPathResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetInstancesResp_RequestedPathResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          GetInstancesResp_RequestedPathResult>(create);
  static GetInstancesResp_RequestedPathResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestedPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestedPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestedPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestedPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get errCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set errCode($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get errMsg => $_getSZ(2);
  @$pb.TagNumber(3)
  set errMsg($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasErrMsg() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrMsg() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<GetInstancesResp_CurrInstance> get currInsts => $_getList(3);
}

class GetInstancesResp_CurrInstance extends $pb.GeneratedMessage {
  factory GetInstancesResp_CurrInstance({
    $core.String? instantiatedObjPath,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? uniqueKeys,
  }) {
    final result = create();
    if (instantiatedObjPath != null)
      result.instantiatedObjPath = instantiatedObjPath;
    if (uniqueKeys != null) result.uniqueKeys.addEntries(uniqueKeys);
    return result;
  }

  GetInstancesResp_CurrInstance._();

  factory GetInstancesResp_CurrInstance.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetInstancesResp_CurrInstance.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInstancesResp.CurrInstance',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'instantiatedObjPath')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'uniqueKeys',
        entryClassName: 'GetInstancesResp.CurrInstance.UniqueKeysEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('usp'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstancesResp_CurrInstance clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstancesResp_CurrInstance copyWith(
          void Function(GetInstancesResp_CurrInstance) updates) =>
      super.copyWith(
              (message) => updates(message as GetInstancesResp_CurrInstance))
          as GetInstancesResp_CurrInstance;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetInstancesResp_CurrInstance create() =>
      GetInstancesResp_CurrInstance._();
  @$core.override
  GetInstancesResp_CurrInstance createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetInstancesResp_CurrInstance getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetInstancesResp_CurrInstance>(create);
  static GetInstancesResp_CurrInstance? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get instantiatedObjPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set instantiatedObjPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstantiatedObjPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstantiatedObjPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get uniqueKeys => $_getMap(1);
}

class GetInstancesResp extends $pb.GeneratedMessage {
  factory GetInstancesResp({
    $core.Iterable<GetInstancesResp_RequestedPathResult>? reqPathResults,
  }) {
    final result = create();
    if (reqPathResults != null) result.reqPathResults.addAll(reqPathResults);
    return result;
  }

  GetInstancesResp._();

  factory GetInstancesResp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetInstancesResp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInstancesResp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPM<GetInstancesResp_RequestedPathResult>(
        1, _omitFieldNames ? '' : 'reqPathResults',
        subBuilder: GetInstancesResp_RequestedPathResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstancesResp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetInstancesResp copyWith(void Function(GetInstancesResp) updates) =>
      super.copyWith((message) => updates(message as GetInstancesResp))
          as GetInstancesResp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetInstancesResp create() => GetInstancesResp._();
  @$core.override
  GetInstancesResp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetInstancesResp getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetInstancesResp>(create);
  static GetInstancesResp? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<GetInstancesResp_RequestedPathResult> get reqPathResults =>
      $_getList(0);
}

class GetSupportedProtocol extends $pb.GeneratedMessage {
  factory GetSupportedProtocol({
    $core.String? controllerSupportedProtocolVersions,
  }) {
    final result = create();
    if (controllerSupportedProtocolVersions != null)
      result.controllerSupportedProtocolVersions =
          controllerSupportedProtocolVersions;
    return result;
  }

  GetSupportedProtocol._();

  factory GetSupportedProtocol.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSupportedProtocol.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSupportedProtocol',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'controllerSupportedProtocolVersions')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedProtocol clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedProtocol copyWith(void Function(GetSupportedProtocol) updates) =>
      super.copyWith((message) => updates(message as GetSupportedProtocol))
          as GetSupportedProtocol;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSupportedProtocol create() => GetSupportedProtocol._();
  @$core.override
  GetSupportedProtocol createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSupportedProtocol getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSupportedProtocol>(create);
  static GetSupportedProtocol? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get controllerSupportedProtocolVersions => $_getSZ(0);
  @$pb.TagNumber(1)
  set controllerSupportedProtocolVersions($core.String value) =>
      $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasControllerSupportedProtocolVersions() => $_has(0);
  @$pb.TagNumber(1)
  void clearControllerSupportedProtocolVersions() => $_clearField(1);
}

class GetSupportedProtocolResp extends $pb.GeneratedMessage {
  factory GetSupportedProtocolResp({
    $core.String? agentSupportedProtocolVersions,
  }) {
    final result = create();
    if (agentSupportedProtocolVersions != null)
      result.agentSupportedProtocolVersions = agentSupportedProtocolVersions;
    return result;
  }

  GetSupportedProtocolResp._();

  factory GetSupportedProtocolResp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetSupportedProtocolResp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetSupportedProtocolResp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'agentSupportedProtocolVersions')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedProtocolResp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetSupportedProtocolResp copyWith(
          void Function(GetSupportedProtocolResp) updates) =>
      super.copyWith((message) => updates(message as GetSupportedProtocolResp))
          as GetSupportedProtocolResp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetSupportedProtocolResp create() => GetSupportedProtocolResp._();
  @$core.override
  GetSupportedProtocolResp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetSupportedProtocolResp getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetSupportedProtocolResp>(create);
  static GetSupportedProtocolResp? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get agentSupportedProtocolVersions => $_getSZ(0);
  @$pb.TagNumber(1)
  set agentSupportedProtocolVersions($core.String value) =>
      $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAgentSupportedProtocolVersions() => $_has(0);
  @$pb.TagNumber(1)
  void clearAgentSupportedProtocolVersions() => $_clearField(1);
}

class Add_CreateObject extends $pb.GeneratedMessage {
  factory Add_CreateObject({
    $core.String? objPath,
    $core.Iterable<Add_CreateParamSetting>? paramSettings,
  }) {
    final result = create();
    if (objPath != null) result.objPath = objPath;
    if (paramSettings != null) result.paramSettings.addAll(paramSettings);
    return result;
  }

  Add_CreateObject._();

  factory Add_CreateObject.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Add_CreateObject.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Add.CreateObject',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'objPath')
    ..pPM<Add_CreateParamSetting>(2, _omitFieldNames ? '' : 'paramSettings',
        subBuilder: Add_CreateParamSetting.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Add_CreateObject clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Add_CreateObject copyWith(void Function(Add_CreateObject) updates) =>
      super.copyWith((message) => updates(message as Add_CreateObject))
          as Add_CreateObject;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Add_CreateObject create() => Add_CreateObject._();
  @$core.override
  Add_CreateObject createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Add_CreateObject getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Add_CreateObject>(create);
  static Add_CreateObject? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get objPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set objPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasObjPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Add_CreateParamSetting> get paramSettings => $_getList(1);
}

class Add_CreateParamSetting extends $pb.GeneratedMessage {
  factory Add_CreateParamSetting({
    $core.String? param,
    $core.String? value,
    $core.bool? required,
  }) {
    final result = create();
    if (param != null) result.param = param;
    if (value != null) result.value = value;
    if (required != null) result.required = required;
    return result;
  }

  Add_CreateParamSetting._();

  factory Add_CreateParamSetting.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Add_CreateParamSetting.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Add.CreateParamSetting',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'param')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..aOB(3, _omitFieldNames ? '' : 'required')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Add_CreateParamSetting clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Add_CreateParamSetting copyWith(
          void Function(Add_CreateParamSetting) updates) =>
      super.copyWith((message) => updates(message as Add_CreateParamSetting))
          as Add_CreateParamSetting;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Add_CreateParamSetting create() => Add_CreateParamSetting._();
  @$core.override
  Add_CreateParamSetting createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Add_CreateParamSetting getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Add_CreateParamSetting>(create);
  static Add_CreateParamSetting? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get param => $_getSZ(0);
  @$pb.TagNumber(1)
  set param($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParam() => $_has(0);
  @$pb.TagNumber(1)
  void clearParam() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get required => $_getBF(2);
  @$pb.TagNumber(3)
  set required($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRequired() => $_has(2);
  @$pb.TagNumber(3)
  void clearRequired() => $_clearField(3);
}

class Add extends $pb.GeneratedMessage {
  factory Add({
    $core.bool? allowPartial,
    $core.Iterable<Add_CreateObject>? createObjs,
  }) {
    final result = create();
    if (allowPartial != null) result.allowPartial = allowPartial;
    if (createObjs != null) result.createObjs.addAll(createObjs);
    return result;
  }

  Add._();

  factory Add.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Add.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Add',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'allowPartial')
    ..pPM<Add_CreateObject>(2, _omitFieldNames ? '' : 'createObjs',
        subBuilder: Add_CreateObject.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Add clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Add copyWith(void Function(Add) updates) =>
      super.copyWith((message) => updates(message as Add)) as Add;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Add create() => Add._();
  @$core.override
  Add createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Add getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Add>(create);
  static Add? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get allowPartial => $_getBF(0);
  @$pb.TagNumber(1)
  set allowPartial($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAllowPartial() => $_has(0);
  @$pb.TagNumber(1)
  void clearAllowPartial() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Add_CreateObject> get createObjs => $_getList(1);
}

class AddResp_CreatedObjectResult_OperationStatus_OperationFailure
    extends $pb.GeneratedMessage {
  factory AddResp_CreatedObjectResult_OperationStatus_OperationFailure({
    $core.int? errCode,
    $core.String? errMsg,
  }) {
    final result = create();
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    return result;
  }

  AddResp_CreatedObjectResult_OperationStatus_OperationFailure._();

  factory AddResp_CreatedObjectResult_OperationStatus_OperationFailure.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddResp_CreatedObjectResult_OperationStatus_OperationFailure.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AddResp.CreatedObjectResult.OperationStatus.OperationFailure',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(2, _omitFieldNames ? '' : 'errMsg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddResp_CreatedObjectResult_OperationStatus_OperationFailure clone() =>
      deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddResp_CreatedObjectResult_OperationStatus_OperationFailure copyWith(
          void Function(
                  AddResp_CreatedObjectResult_OperationStatus_OperationFailure)
              updates) =>
      super.copyWith((message) => updates(message
              as AddResp_CreatedObjectResult_OperationStatus_OperationFailure))
          as AddResp_CreatedObjectResult_OperationStatus_OperationFailure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddResp_CreatedObjectResult_OperationStatus_OperationFailure
      create() =>
          AddResp_CreatedObjectResult_OperationStatus_OperationFailure._();
  @$core.override
  AddResp_CreatedObjectResult_OperationStatus_OperationFailure
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddResp_CreatedObjectResult_OperationStatus_OperationFailure
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          AddResp_CreatedObjectResult_OperationStatus_OperationFailure>(create);
  static AddResp_CreatedObjectResult_OperationStatus_OperationFailure?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get errCode => $_getIZ(0);
  @$pb.TagNumber(1)
  set errCode($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasErrCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearErrCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errMsg => $_getSZ(1);
  @$pb.TagNumber(2)
  set errMsg($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrMsg() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrMsg() => $_clearField(2);
}

class AddResp_CreatedObjectResult_OperationStatus_OperationSuccess
    extends $pb.GeneratedMessage {
  factory AddResp_CreatedObjectResult_OperationStatus_OperationSuccess({
    $core.String? instantiatedPath,
    $core.Iterable<AddResp_ParameterError>? paramErrs,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? uniqueKeys,
  }) {
    final result = create();
    if (instantiatedPath != null) result.instantiatedPath = instantiatedPath;
    if (paramErrs != null) result.paramErrs.addAll(paramErrs);
    if (uniqueKeys != null) result.uniqueKeys.addEntries(uniqueKeys);
    return result;
  }

  AddResp_CreatedObjectResult_OperationStatus_OperationSuccess._();

  factory AddResp_CreatedObjectResult_OperationStatus_OperationSuccess.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddResp_CreatedObjectResult_OperationStatus_OperationSuccess.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'AddResp.CreatedObjectResult.OperationStatus.OperationSuccess',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'instantiatedPath')
    ..pPM<AddResp_ParameterError>(2, _omitFieldNames ? '' : 'paramErrs',
        subBuilder: AddResp_ParameterError.create)
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'uniqueKeys',
        entryClassName:
            'AddResp.CreatedObjectResult.OperationStatus.OperationSuccess.UniqueKeysEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('usp'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddResp_CreatedObjectResult_OperationStatus_OperationSuccess clone() =>
      deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddResp_CreatedObjectResult_OperationStatus_OperationSuccess copyWith(
          void Function(
                  AddResp_CreatedObjectResult_OperationStatus_OperationSuccess)
              updates) =>
      super.copyWith((message) => updates(message
              as AddResp_CreatedObjectResult_OperationStatus_OperationSuccess))
          as AddResp_CreatedObjectResult_OperationStatus_OperationSuccess;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddResp_CreatedObjectResult_OperationStatus_OperationSuccess
      create() =>
          AddResp_CreatedObjectResult_OperationStatus_OperationSuccess._();
  @$core.override
  AddResp_CreatedObjectResult_OperationStatus_OperationSuccess
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddResp_CreatedObjectResult_OperationStatus_OperationSuccess
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          AddResp_CreatedObjectResult_OperationStatus_OperationSuccess>(create);
  static AddResp_CreatedObjectResult_OperationStatus_OperationSuccess?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get instantiatedPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set instantiatedPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstantiatedPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstantiatedPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<AddResp_ParameterError> get paramErrs => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $core.String> get uniqueKeys => $_getMap(2);
}

enum AddResp_CreatedObjectResult_OperationStatus_OperStatus {
  operFailure,
  operSuccess,
  notSet
}

class AddResp_CreatedObjectResult_OperationStatus extends $pb.GeneratedMessage {
  factory AddResp_CreatedObjectResult_OperationStatus({
    AddResp_CreatedObjectResult_OperationStatus_OperationFailure? operFailure,
    AddResp_CreatedObjectResult_OperationStatus_OperationSuccess? operSuccess,
  }) {
    final result = create();
    if (operFailure != null) result.operFailure = operFailure;
    if (operSuccess != null) result.operSuccess = operSuccess;
    return result;
  }

  AddResp_CreatedObjectResult_OperationStatus._();

  factory AddResp_CreatedObjectResult_OperationStatus.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddResp_CreatedObjectResult_OperationStatus.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core
      .Map<$core.int, AddResp_CreatedObjectResult_OperationStatus_OperStatus>
      _AddResp_CreatedObjectResult_OperationStatus_OperStatusByTag = {
    1: AddResp_CreatedObjectResult_OperationStatus_OperStatus.operFailure,
    2: AddResp_CreatedObjectResult_OperationStatus_OperStatus.operSuccess,
    0: AddResp_CreatedObjectResult_OperationStatus_OperStatus.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddResp.CreatedObjectResult.OperationStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<AddResp_CreatedObjectResult_OperationStatus_OperationFailure>(
        1, _omitFieldNames ? '' : 'operFailure',
        subBuilder:
            AddResp_CreatedObjectResult_OperationStatus_OperationFailure.create)
    ..aOM<AddResp_CreatedObjectResult_OperationStatus_OperationSuccess>(
        2, _omitFieldNames ? '' : 'operSuccess',
        subBuilder:
            AddResp_CreatedObjectResult_OperationStatus_OperationSuccess.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddResp_CreatedObjectResult_OperationStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddResp_CreatedObjectResult_OperationStatus copyWith(
          void Function(AddResp_CreatedObjectResult_OperationStatus) updates) =>
      super.copyWith((message) =>
              updates(message as AddResp_CreatedObjectResult_OperationStatus))
          as AddResp_CreatedObjectResult_OperationStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddResp_CreatedObjectResult_OperationStatus create() =>
      AddResp_CreatedObjectResult_OperationStatus._();
  @$core.override
  AddResp_CreatedObjectResult_OperationStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddResp_CreatedObjectResult_OperationStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          AddResp_CreatedObjectResult_OperationStatus>(create);
  static AddResp_CreatedObjectResult_OperationStatus? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  AddResp_CreatedObjectResult_OperationStatus_OperStatus whichOperStatus() =>
      _AddResp_CreatedObjectResult_OperationStatus_OperStatusByTag[
          $_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOperStatus() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  AddResp_CreatedObjectResult_OperationStatus_OperationFailure
      get operFailure => $_getN(0);
  @$pb.TagNumber(1)
  set operFailure(
          AddResp_CreatedObjectResult_OperationStatus_OperationFailure value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOperFailure() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperFailure() => $_clearField(1);
  @$pb.TagNumber(1)
  AddResp_CreatedObjectResult_OperationStatus_OperationFailure
      ensureOperFailure() => $_ensure(0);

  @$pb.TagNumber(2)
  AddResp_CreatedObjectResult_OperationStatus_OperationSuccess
      get operSuccess => $_getN(1);
  @$pb.TagNumber(2)
  set operSuccess(
          AddResp_CreatedObjectResult_OperationStatus_OperationSuccess value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperSuccess() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperSuccess() => $_clearField(2);
  @$pb.TagNumber(2)
  AddResp_CreatedObjectResult_OperationStatus_OperationSuccess
      ensureOperSuccess() => $_ensure(1);
}

class AddResp_CreatedObjectResult extends $pb.GeneratedMessage {
  factory AddResp_CreatedObjectResult({
    $core.String? requestedPath,
    AddResp_CreatedObjectResult_OperationStatus? operStatus,
  }) {
    final result = create();
    if (requestedPath != null) result.requestedPath = requestedPath;
    if (operStatus != null) result.operStatus = operStatus;
    return result;
  }

  AddResp_CreatedObjectResult._();

  factory AddResp_CreatedObjectResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddResp_CreatedObjectResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddResp.CreatedObjectResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestedPath')
    ..aOM<AddResp_CreatedObjectResult_OperationStatus>(
        2, _omitFieldNames ? '' : 'operStatus',
        subBuilder: AddResp_CreatedObjectResult_OperationStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddResp_CreatedObjectResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddResp_CreatedObjectResult copyWith(
          void Function(AddResp_CreatedObjectResult) updates) =>
      super.copyWith(
              (message) => updates(message as AddResp_CreatedObjectResult))
          as AddResp_CreatedObjectResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddResp_CreatedObjectResult create() =>
      AddResp_CreatedObjectResult._();
  @$core.override
  AddResp_CreatedObjectResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddResp_CreatedObjectResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddResp_CreatedObjectResult>(create);
  static AddResp_CreatedObjectResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestedPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestedPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestedPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestedPath() => $_clearField(1);

  @$pb.TagNumber(2)
  AddResp_CreatedObjectResult_OperationStatus get operStatus => $_getN(1);
  @$pb.TagNumber(2)
  set operStatus(AddResp_CreatedObjectResult_OperationStatus value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperStatus() => $_clearField(2);
  @$pb.TagNumber(2)
  AddResp_CreatedObjectResult_OperationStatus ensureOperStatus() => $_ensure(1);
}

class AddResp_ParameterError extends $pb.GeneratedMessage {
  factory AddResp_ParameterError({
    $core.String? param,
    $core.int? errCode,
    $core.String? errMsg,
  }) {
    final result = create();
    if (param != null) result.param = param;
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    return result;
  }

  AddResp_ParameterError._();

  factory AddResp_ParameterError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddResp_ParameterError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddResp.ParameterError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'param')
    ..aI(2, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(3, _omitFieldNames ? '' : 'errMsg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddResp_ParameterError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddResp_ParameterError copyWith(
          void Function(AddResp_ParameterError) updates) =>
      super.copyWith((message) => updates(message as AddResp_ParameterError))
          as AddResp_ParameterError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddResp_ParameterError create() => AddResp_ParameterError._();
  @$core.override
  AddResp_ParameterError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddResp_ParameterError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddResp_ParameterError>(create);
  static AddResp_ParameterError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get param => $_getSZ(0);
  @$pb.TagNumber(1)
  set param($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParam() => $_has(0);
  @$pb.TagNumber(1)
  void clearParam() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get errCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set errCode($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get errMsg => $_getSZ(2);
  @$pb.TagNumber(3)
  set errMsg($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasErrMsg() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrMsg() => $_clearField(3);
}

class AddResp extends $pb.GeneratedMessage {
  factory AddResp({
    $core.Iterable<AddResp_CreatedObjectResult>? createdObjResults,
  }) {
    final result = create();
    if (createdObjResults != null)
      result.createdObjResults.addAll(createdObjResults);
    return result;
  }

  AddResp._();

  factory AddResp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddResp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddResp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPM<AddResp_CreatedObjectResult>(
        1, _omitFieldNames ? '' : 'createdObjResults',
        subBuilder: AddResp_CreatedObjectResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddResp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddResp copyWith(void Function(AddResp) updates) =>
      super.copyWith((message) => updates(message as AddResp)) as AddResp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddResp create() => AddResp._();
  @$core.override
  AddResp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddResp getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AddResp>(create);
  static AddResp? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<AddResp_CreatedObjectResult> get createdObjResults => $_getList(0);
}

class Delete extends $pb.GeneratedMessage {
  factory Delete({
    $core.bool? allowPartial,
    $core.Iterable<$core.String>? objPaths,
  }) {
    final result = create();
    if (allowPartial != null) result.allowPartial = allowPartial;
    if (objPaths != null) result.objPaths.addAll(objPaths);
    return result;
  }

  Delete._();

  factory Delete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Delete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Delete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'allowPartial')
    ..pPS(2, _omitFieldNames ? '' : 'objPaths')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Delete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Delete copyWith(void Function(Delete) updates) =>
      super.copyWith((message) => updates(message as Delete)) as Delete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Delete create() => Delete._();
  @$core.override
  Delete createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Delete getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Delete>(create);
  static Delete? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get allowPartial => $_getBF(0);
  @$pb.TagNumber(1)
  set allowPartial($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAllowPartial() => $_has(0);
  @$pb.TagNumber(1)
  void clearAllowPartial() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get objPaths => $_getList(1);
}

class DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure
    extends $pb.GeneratedMessage {
  factory DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure({
    $core.int? errCode,
    $core.String? errMsg,
  }) {
    final result = create();
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    return result;
  }

  DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure._();

  factory DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'DeleteResp.DeletedObjectResult.OperationStatus.OperationFailure',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(2, _omitFieldNames ? '' : 'errMsg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure clone() =>
      deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure copyWith(
          void Function(
                  DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure)
              updates) =>
      super.copyWith((message) => updates(message
              as DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure))
          as DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure
      create() =>
          DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure._();
  @$core.override
  DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure>(
          create);
  static DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get errCode => $_getIZ(0);
  @$pb.TagNumber(1)
  set errCode($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasErrCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearErrCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errMsg => $_getSZ(1);
  @$pb.TagNumber(2)
  set errMsg($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrMsg() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrMsg() => $_clearField(2);
}

class DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess
    extends $pb.GeneratedMessage {
  factory DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess({
    $core.Iterable<$core.String>? affectedPaths,
    $core.Iterable<DeleteResp_UnaffectedPathError>? unaffectedPathErrs,
  }) {
    final result = create();
    if (affectedPaths != null) result.affectedPaths.addAll(affectedPaths);
    if (unaffectedPathErrs != null)
      result.unaffectedPathErrs.addAll(unaffectedPathErrs);
    return result;
  }

  DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess._();

  factory DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'DeleteResp.DeletedObjectResult.OperationStatus.OperationSuccess',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'affectedPaths')
    ..pPM<DeleteResp_UnaffectedPathError>(
        2, _omitFieldNames ? '' : 'unaffectedPathErrs',
        subBuilder: DeleteResp_UnaffectedPathError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess clone() =>
      deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess copyWith(
          void Function(
                  DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess)
              updates) =>
      super.copyWith((message) => updates(message
              as DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess))
          as DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess
      create() =>
          DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess._();
  @$core.override
  DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess>(
          create);
  static DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess?
      _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get affectedPaths => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<DeleteResp_UnaffectedPathError> get unaffectedPathErrs =>
      $_getList(1);
}

enum DeleteResp_DeletedObjectResult_OperationStatus_OperStatus {
  operFailure,
  operSuccess,
  notSet
}

class DeleteResp_DeletedObjectResult_OperationStatus
    extends $pb.GeneratedMessage {
  factory DeleteResp_DeletedObjectResult_OperationStatus({
    DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure?
        operFailure,
    DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess?
        operSuccess,
  }) {
    final result = create();
    if (operFailure != null) result.operFailure = operFailure;
    if (operSuccess != null) result.operSuccess = operSuccess;
    return result;
  }

  DeleteResp_DeletedObjectResult_OperationStatus._();

  factory DeleteResp_DeletedObjectResult_OperationStatus.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteResp_DeletedObjectResult_OperationStatus.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core
      .Map<$core.int, DeleteResp_DeletedObjectResult_OperationStatus_OperStatus>
      _DeleteResp_DeletedObjectResult_OperationStatus_OperStatusByTag = {
    1: DeleteResp_DeletedObjectResult_OperationStatus_OperStatus.operFailure,
    2: DeleteResp_DeletedObjectResult_OperationStatus_OperStatus.operSuccess,
    0: DeleteResp_DeletedObjectResult_OperationStatus_OperStatus.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteResp.DeletedObjectResult.OperationStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure>(
        1, _omitFieldNames ? '' : 'operFailure',
        subBuilder:
            DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure
                .create)
    ..aOM<DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess>(
        2, _omitFieldNames ? '' : 'operSuccess',
        subBuilder:
            DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess
                .create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResp_DeletedObjectResult_OperationStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResp_DeletedObjectResult_OperationStatus copyWith(
          void Function(DeleteResp_DeletedObjectResult_OperationStatus)
              updates) =>
      super.copyWith((message) => updates(
              message as DeleteResp_DeletedObjectResult_OperationStatus))
          as DeleteResp_DeletedObjectResult_OperationStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteResp_DeletedObjectResult_OperationStatus create() =>
      DeleteResp_DeletedObjectResult_OperationStatus._();
  @$core.override
  DeleteResp_DeletedObjectResult_OperationStatus createEmptyInstance() =>
      create();
  @$core.pragma('dart2js:noInline')
  static DeleteResp_DeletedObjectResult_OperationStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          DeleteResp_DeletedObjectResult_OperationStatus>(create);
  static DeleteResp_DeletedObjectResult_OperationStatus? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DeleteResp_DeletedObjectResult_OperationStatus_OperStatus whichOperStatus() =>
      _DeleteResp_DeletedObjectResult_OperationStatus_OperStatusByTag[
          $_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOperStatus() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure
      get operFailure => $_getN(0);
  @$pb.TagNumber(1)
  set operFailure(
          DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure
              value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOperFailure() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperFailure() => $_clearField(1);
  @$pb.TagNumber(1)
  DeleteResp_DeletedObjectResult_OperationStatus_OperationFailure
      ensureOperFailure() => $_ensure(0);

  @$pb.TagNumber(2)
  DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess
      get operSuccess => $_getN(1);
  @$pb.TagNumber(2)
  set operSuccess(
          DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess
              value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperSuccess() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperSuccess() => $_clearField(2);
  @$pb.TagNumber(2)
  DeleteResp_DeletedObjectResult_OperationStatus_OperationSuccess
      ensureOperSuccess() => $_ensure(1);
}

class DeleteResp_DeletedObjectResult extends $pb.GeneratedMessage {
  factory DeleteResp_DeletedObjectResult({
    $core.String? requestedPath,
    DeleteResp_DeletedObjectResult_OperationStatus? operStatus,
  }) {
    final result = create();
    if (requestedPath != null) result.requestedPath = requestedPath;
    if (operStatus != null) result.operStatus = operStatus;
    return result;
  }

  DeleteResp_DeletedObjectResult._();

  factory DeleteResp_DeletedObjectResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteResp_DeletedObjectResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteResp.DeletedObjectResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestedPath')
    ..aOM<DeleteResp_DeletedObjectResult_OperationStatus>(
        2, _omitFieldNames ? '' : 'operStatus',
        subBuilder: DeleteResp_DeletedObjectResult_OperationStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResp_DeletedObjectResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResp_DeletedObjectResult copyWith(
          void Function(DeleteResp_DeletedObjectResult) updates) =>
      super.copyWith(
              (message) => updates(message as DeleteResp_DeletedObjectResult))
          as DeleteResp_DeletedObjectResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteResp_DeletedObjectResult create() =>
      DeleteResp_DeletedObjectResult._();
  @$core.override
  DeleteResp_DeletedObjectResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteResp_DeletedObjectResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteResp_DeletedObjectResult>(create);
  static DeleteResp_DeletedObjectResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestedPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestedPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestedPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestedPath() => $_clearField(1);

  @$pb.TagNumber(2)
  DeleteResp_DeletedObjectResult_OperationStatus get operStatus => $_getN(1);
  @$pb.TagNumber(2)
  set operStatus(DeleteResp_DeletedObjectResult_OperationStatus value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperStatus() => $_clearField(2);
  @$pb.TagNumber(2)
  DeleteResp_DeletedObjectResult_OperationStatus ensureOperStatus() =>
      $_ensure(1);
}

class DeleteResp_UnaffectedPathError extends $pb.GeneratedMessage {
  factory DeleteResp_UnaffectedPathError({
    $core.String? unaffectedPath,
    $core.int? errCode,
    $core.String? errMsg,
  }) {
    final result = create();
    if (unaffectedPath != null) result.unaffectedPath = unaffectedPath;
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    return result;
  }

  DeleteResp_UnaffectedPathError._();

  factory DeleteResp_UnaffectedPathError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteResp_UnaffectedPathError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteResp.UnaffectedPathError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'unaffectedPath')
    ..aI(2, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(3, _omitFieldNames ? '' : 'errMsg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResp_UnaffectedPathError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResp_UnaffectedPathError copyWith(
          void Function(DeleteResp_UnaffectedPathError) updates) =>
      super.copyWith(
              (message) => updates(message as DeleteResp_UnaffectedPathError))
          as DeleteResp_UnaffectedPathError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteResp_UnaffectedPathError create() =>
      DeleteResp_UnaffectedPathError._();
  @$core.override
  DeleteResp_UnaffectedPathError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteResp_UnaffectedPathError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteResp_UnaffectedPathError>(create);
  static DeleteResp_UnaffectedPathError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get unaffectedPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set unaffectedPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUnaffectedPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearUnaffectedPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get errCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set errCode($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get errMsg => $_getSZ(2);
  @$pb.TagNumber(3)
  set errMsg($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasErrMsg() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrMsg() => $_clearField(3);
}

class DeleteResp extends $pb.GeneratedMessage {
  factory DeleteResp({
    $core.Iterable<DeleteResp_DeletedObjectResult>? deletedObjResults,
  }) {
    final result = create();
    if (deletedObjResults != null)
      result.deletedObjResults.addAll(deletedObjResults);
    return result;
  }

  DeleteResp._();

  factory DeleteResp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeleteResp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeleteResp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPM<DeleteResp_DeletedObjectResult>(
        1, _omitFieldNames ? '' : 'deletedObjResults',
        subBuilder: DeleteResp_DeletedObjectResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteResp copyWith(void Function(DeleteResp) updates) =>
      super.copyWith((message) => updates(message as DeleteResp)) as DeleteResp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteResp create() => DeleteResp._();
  @$core.override
  DeleteResp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeleteResp getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteResp>(create);
  static DeleteResp? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<DeleteResp_DeletedObjectResult> get deletedObjResults =>
      $_getList(0);
}

class Set_UpdateObject extends $pb.GeneratedMessage {
  factory Set_UpdateObject({
    $core.String? objPath,
    $core.Iterable<Set_UpdateParamSetting>? paramSettings,
  }) {
    final result = create();
    if (objPath != null) result.objPath = objPath;
    if (paramSettings != null) result.paramSettings.addAll(paramSettings);
    return result;
  }

  Set_UpdateObject._();

  factory Set_UpdateObject.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Set_UpdateObject.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Set.UpdateObject',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'objPath')
    ..pPM<Set_UpdateParamSetting>(2, _omitFieldNames ? '' : 'paramSettings',
        subBuilder: Set_UpdateParamSetting.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Set_UpdateObject clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Set_UpdateObject copyWith(void Function(Set_UpdateObject) updates) =>
      super.copyWith((message) => updates(message as Set_UpdateObject))
          as Set_UpdateObject;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Set_UpdateObject create() => Set_UpdateObject._();
  @$core.override
  Set_UpdateObject createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Set_UpdateObject getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Set_UpdateObject>(create);
  static Set_UpdateObject? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get objPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set objPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasObjPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Set_UpdateParamSetting> get paramSettings => $_getList(1);
}

class Set_UpdateParamSetting extends $pb.GeneratedMessage {
  factory Set_UpdateParamSetting({
    $core.String? param,
    $core.String? value,
    $core.bool? required,
  }) {
    final result = create();
    if (param != null) result.param = param;
    if (value != null) result.value = value;
    if (required != null) result.required = required;
    return result;
  }

  Set_UpdateParamSetting._();

  factory Set_UpdateParamSetting.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Set_UpdateParamSetting.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Set.UpdateParamSetting',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'param')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..aOB(3, _omitFieldNames ? '' : 'required')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Set_UpdateParamSetting clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Set_UpdateParamSetting copyWith(
          void Function(Set_UpdateParamSetting) updates) =>
      super.copyWith((message) => updates(message as Set_UpdateParamSetting))
          as Set_UpdateParamSetting;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Set_UpdateParamSetting create() => Set_UpdateParamSetting._();
  @$core.override
  Set_UpdateParamSetting createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Set_UpdateParamSetting getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Set_UpdateParamSetting>(create);
  static Set_UpdateParamSetting? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get param => $_getSZ(0);
  @$pb.TagNumber(1)
  set param($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParam() => $_has(0);
  @$pb.TagNumber(1)
  void clearParam() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get required => $_getBF(2);
  @$pb.TagNumber(3)
  set required($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRequired() => $_has(2);
  @$pb.TagNumber(3)
  void clearRequired() => $_clearField(3);
}

class Set extends $pb.GeneratedMessage {
  factory Set({
    $core.bool? allowPartial,
    $core.Iterable<Set_UpdateObject>? updateObjs,
  }) {
    final result = create();
    if (allowPartial != null) result.allowPartial = allowPartial;
    if (updateObjs != null) result.updateObjs.addAll(updateObjs);
    return result;
  }

  Set._();

  factory Set.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Set.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Set',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'allowPartial')
    ..pPM<Set_UpdateObject>(2, _omitFieldNames ? '' : 'updateObjs',
        subBuilder: Set_UpdateObject.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Set clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Set copyWith(void Function(Set) updates) =>
      super.copyWith((message) => updates(message as Set)) as Set;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Set create() => Set._();
  @$core.override
  Set createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Set getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Set>(create);
  static Set? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get allowPartial => $_getBF(0);
  @$pb.TagNumber(1)
  set allowPartial($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAllowPartial() => $_has(0);
  @$pb.TagNumber(1)
  void clearAllowPartial() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Set_UpdateObject> get updateObjs => $_getList(1);
}

class SetResp_UpdatedObjectResult_OperationStatus_OperationFailure
    extends $pb.GeneratedMessage {
  factory SetResp_UpdatedObjectResult_OperationStatus_OperationFailure({
    $core.int? errCode,
    $core.String? errMsg,
    $core.Iterable<SetResp_UpdatedInstanceFailure>? updatedInstFailures,
  }) {
    final result = create();
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    if (updatedInstFailures != null)
      result.updatedInstFailures.addAll(updatedInstFailures);
    return result;
  }

  SetResp_UpdatedObjectResult_OperationStatus_OperationFailure._();

  factory SetResp_UpdatedObjectResult_OperationStatus_OperationFailure.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetResp_UpdatedObjectResult_OperationStatus_OperationFailure.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'SetResp.UpdatedObjectResult.OperationStatus.OperationFailure',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(2, _omitFieldNames ? '' : 'errMsg')
    ..pPM<SetResp_UpdatedInstanceFailure>(
        3, _omitFieldNames ? '' : 'updatedInstFailures',
        subBuilder: SetResp_UpdatedInstanceFailure.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_UpdatedObjectResult_OperationStatus_OperationFailure clone() =>
      deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_UpdatedObjectResult_OperationStatus_OperationFailure copyWith(
          void Function(
                  SetResp_UpdatedObjectResult_OperationStatus_OperationFailure)
              updates) =>
      super.copyWith((message) => updates(message
              as SetResp_UpdatedObjectResult_OperationStatus_OperationFailure))
          as SetResp_UpdatedObjectResult_OperationStatus_OperationFailure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetResp_UpdatedObjectResult_OperationStatus_OperationFailure
      create() =>
          SetResp_UpdatedObjectResult_OperationStatus_OperationFailure._();
  @$core.override
  SetResp_UpdatedObjectResult_OperationStatus_OperationFailure
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetResp_UpdatedObjectResult_OperationStatus_OperationFailure
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          SetResp_UpdatedObjectResult_OperationStatus_OperationFailure>(create);
  static SetResp_UpdatedObjectResult_OperationStatus_OperationFailure?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get errCode => $_getIZ(0);
  @$pb.TagNumber(1)
  set errCode($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasErrCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearErrCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errMsg => $_getSZ(1);
  @$pb.TagNumber(2)
  set errMsg($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrMsg() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrMsg() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<SetResp_UpdatedInstanceFailure> get updatedInstFailures =>
      $_getList(2);
}

class SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess
    extends $pb.GeneratedMessage {
  factory SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess({
    $core.Iterable<SetResp_UpdatedInstanceResult>? updatedInstResults,
  }) {
    final result = create();
    if (updatedInstResults != null)
      result.updatedInstResults.addAll(updatedInstResults);
    return result;
  }

  SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess._();

  factory SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'SetResp.UpdatedObjectResult.OperationStatus.OperationSuccess',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPM<SetResp_UpdatedInstanceResult>(
        1, _omitFieldNames ? '' : 'updatedInstResults',
        subBuilder: SetResp_UpdatedInstanceResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess clone() =>
      deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess copyWith(
          void Function(
                  SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess)
              updates) =>
      super.copyWith((message) => updates(message
              as SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess))
          as SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess
      create() =>
          SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess._();
  @$core.override
  SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess>(create);
  static SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess?
      _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SetResp_UpdatedInstanceResult> get updatedInstResults =>
      $_getList(0);
}

enum SetResp_UpdatedObjectResult_OperationStatus_OperStatus {
  operFailure,
  operSuccess,
  notSet
}

class SetResp_UpdatedObjectResult_OperationStatus extends $pb.GeneratedMessage {
  factory SetResp_UpdatedObjectResult_OperationStatus({
    SetResp_UpdatedObjectResult_OperationStatus_OperationFailure? operFailure,
    SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess? operSuccess,
  }) {
    final result = create();
    if (operFailure != null) result.operFailure = operFailure;
    if (operSuccess != null) result.operSuccess = operSuccess;
    return result;
  }

  SetResp_UpdatedObjectResult_OperationStatus._();

  factory SetResp_UpdatedObjectResult_OperationStatus.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetResp_UpdatedObjectResult_OperationStatus.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core
      .Map<$core.int, SetResp_UpdatedObjectResult_OperationStatus_OperStatus>
      _SetResp_UpdatedObjectResult_OperationStatus_OperStatusByTag = {
    1: SetResp_UpdatedObjectResult_OperationStatus_OperStatus.operFailure,
    2: SetResp_UpdatedObjectResult_OperationStatus_OperStatus.operSuccess,
    0: SetResp_UpdatedObjectResult_OperationStatus_OperStatus.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetResp.UpdatedObjectResult.OperationStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<SetResp_UpdatedObjectResult_OperationStatus_OperationFailure>(
        1, _omitFieldNames ? '' : 'operFailure',
        subBuilder:
            SetResp_UpdatedObjectResult_OperationStatus_OperationFailure.create)
    ..aOM<SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess>(
        2, _omitFieldNames ? '' : 'operSuccess',
        subBuilder:
            SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_UpdatedObjectResult_OperationStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_UpdatedObjectResult_OperationStatus copyWith(
          void Function(SetResp_UpdatedObjectResult_OperationStatus) updates) =>
      super.copyWith((message) =>
              updates(message as SetResp_UpdatedObjectResult_OperationStatus))
          as SetResp_UpdatedObjectResult_OperationStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetResp_UpdatedObjectResult_OperationStatus create() =>
      SetResp_UpdatedObjectResult_OperationStatus._();
  @$core.override
  SetResp_UpdatedObjectResult_OperationStatus createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetResp_UpdatedObjectResult_OperationStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          SetResp_UpdatedObjectResult_OperationStatus>(create);
  static SetResp_UpdatedObjectResult_OperationStatus? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  SetResp_UpdatedObjectResult_OperationStatus_OperStatus whichOperStatus() =>
      _SetResp_UpdatedObjectResult_OperationStatus_OperStatusByTag[
          $_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOperStatus() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  SetResp_UpdatedObjectResult_OperationStatus_OperationFailure
      get operFailure => $_getN(0);
  @$pb.TagNumber(1)
  set operFailure(
          SetResp_UpdatedObjectResult_OperationStatus_OperationFailure value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOperFailure() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperFailure() => $_clearField(1);
  @$pb.TagNumber(1)
  SetResp_UpdatedObjectResult_OperationStatus_OperationFailure
      ensureOperFailure() => $_ensure(0);

  @$pb.TagNumber(2)
  SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess
      get operSuccess => $_getN(1);
  @$pb.TagNumber(2)
  set operSuccess(
          SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperSuccess() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperSuccess() => $_clearField(2);
  @$pb.TagNumber(2)
  SetResp_UpdatedObjectResult_OperationStatus_OperationSuccess
      ensureOperSuccess() => $_ensure(1);
}

class SetResp_UpdatedObjectResult extends $pb.GeneratedMessage {
  factory SetResp_UpdatedObjectResult({
    $core.String? requestedPath,
    SetResp_UpdatedObjectResult_OperationStatus? operStatus,
  }) {
    final result = create();
    if (requestedPath != null) result.requestedPath = requestedPath;
    if (operStatus != null) result.operStatus = operStatus;
    return result;
  }

  SetResp_UpdatedObjectResult._();

  factory SetResp_UpdatedObjectResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetResp_UpdatedObjectResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetResp.UpdatedObjectResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestedPath')
    ..aOM<SetResp_UpdatedObjectResult_OperationStatus>(
        2, _omitFieldNames ? '' : 'operStatus',
        subBuilder: SetResp_UpdatedObjectResult_OperationStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_UpdatedObjectResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_UpdatedObjectResult copyWith(
          void Function(SetResp_UpdatedObjectResult) updates) =>
      super.copyWith(
              (message) => updates(message as SetResp_UpdatedObjectResult))
          as SetResp_UpdatedObjectResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetResp_UpdatedObjectResult create() =>
      SetResp_UpdatedObjectResult._();
  @$core.override
  SetResp_UpdatedObjectResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetResp_UpdatedObjectResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetResp_UpdatedObjectResult>(create);
  static SetResp_UpdatedObjectResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestedPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestedPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestedPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestedPath() => $_clearField(1);

  @$pb.TagNumber(2)
  SetResp_UpdatedObjectResult_OperationStatus get operStatus => $_getN(1);
  @$pb.TagNumber(2)
  set operStatus(SetResp_UpdatedObjectResult_OperationStatus value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperStatus() => $_clearField(2);
  @$pb.TagNumber(2)
  SetResp_UpdatedObjectResult_OperationStatus ensureOperStatus() => $_ensure(1);
}

class SetResp_UpdatedInstanceFailure extends $pb.GeneratedMessage {
  factory SetResp_UpdatedInstanceFailure({
    $core.String? affectedPath,
    $core.Iterable<SetResp_ParameterError>? paramErrs,
  }) {
    final result = create();
    if (affectedPath != null) result.affectedPath = affectedPath;
    if (paramErrs != null) result.paramErrs.addAll(paramErrs);
    return result;
  }

  SetResp_UpdatedInstanceFailure._();

  factory SetResp_UpdatedInstanceFailure.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetResp_UpdatedInstanceFailure.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetResp.UpdatedInstanceFailure',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'affectedPath')
    ..pPM<SetResp_ParameterError>(2, _omitFieldNames ? '' : 'paramErrs',
        subBuilder: SetResp_ParameterError.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_UpdatedInstanceFailure clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_UpdatedInstanceFailure copyWith(
          void Function(SetResp_UpdatedInstanceFailure) updates) =>
      super.copyWith(
              (message) => updates(message as SetResp_UpdatedInstanceFailure))
          as SetResp_UpdatedInstanceFailure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetResp_UpdatedInstanceFailure create() =>
      SetResp_UpdatedInstanceFailure._();
  @$core.override
  SetResp_UpdatedInstanceFailure createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetResp_UpdatedInstanceFailure getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetResp_UpdatedInstanceFailure>(create);
  static SetResp_UpdatedInstanceFailure? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get affectedPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set affectedPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAffectedPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearAffectedPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SetResp_ParameterError> get paramErrs => $_getList(1);
}

class SetResp_UpdatedInstanceResult extends $pb.GeneratedMessage {
  factory SetResp_UpdatedInstanceResult({
    $core.String? affectedPath,
    $core.Iterable<SetResp_ParameterError>? paramErrs,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? updatedParams,
  }) {
    final result = create();
    if (affectedPath != null) result.affectedPath = affectedPath;
    if (paramErrs != null) result.paramErrs.addAll(paramErrs);
    if (updatedParams != null) result.updatedParams.addEntries(updatedParams);
    return result;
  }

  SetResp_UpdatedInstanceResult._();

  factory SetResp_UpdatedInstanceResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetResp_UpdatedInstanceResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetResp.UpdatedInstanceResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'affectedPath')
    ..pPM<SetResp_ParameterError>(2, _omitFieldNames ? '' : 'paramErrs',
        subBuilder: SetResp_ParameterError.create)
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'updatedParams',
        entryClassName: 'SetResp.UpdatedInstanceResult.UpdatedParamsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('usp'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_UpdatedInstanceResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_UpdatedInstanceResult copyWith(
          void Function(SetResp_UpdatedInstanceResult) updates) =>
      super.copyWith(
              (message) => updates(message as SetResp_UpdatedInstanceResult))
          as SetResp_UpdatedInstanceResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetResp_UpdatedInstanceResult create() =>
      SetResp_UpdatedInstanceResult._();
  @$core.override
  SetResp_UpdatedInstanceResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetResp_UpdatedInstanceResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetResp_UpdatedInstanceResult>(create);
  static SetResp_UpdatedInstanceResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get affectedPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set affectedPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAffectedPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearAffectedPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<SetResp_ParameterError> get paramErrs => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $core.String> get updatedParams => $_getMap(2);
}

class SetResp_ParameterError extends $pb.GeneratedMessage {
  factory SetResp_ParameterError({
    $core.String? param,
    $core.int? errCode,
    $core.String? errMsg,
  }) {
    final result = create();
    if (param != null) result.param = param;
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    return result;
  }

  SetResp_ParameterError._();

  factory SetResp_ParameterError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetResp_ParameterError.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetResp.ParameterError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'param')
    ..aI(2, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(3, _omitFieldNames ? '' : 'errMsg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_ParameterError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp_ParameterError copyWith(
          void Function(SetResp_ParameterError) updates) =>
      super.copyWith((message) => updates(message as SetResp_ParameterError))
          as SetResp_ParameterError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetResp_ParameterError create() => SetResp_ParameterError._();
  @$core.override
  SetResp_ParameterError createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetResp_ParameterError getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetResp_ParameterError>(create);
  static SetResp_ParameterError? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get param => $_getSZ(0);
  @$pb.TagNumber(1)
  set param($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParam() => $_has(0);
  @$pb.TagNumber(1)
  void clearParam() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get errCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set errCode($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get errMsg => $_getSZ(2);
  @$pb.TagNumber(3)
  set errMsg($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasErrMsg() => $_has(2);
  @$pb.TagNumber(3)
  void clearErrMsg() => $_clearField(3);
}

class SetResp extends $pb.GeneratedMessage {
  factory SetResp({
    $core.Iterable<SetResp_UpdatedObjectResult>? updatedObjResults,
  }) {
    final result = create();
    if (updatedObjResults != null)
      result.updatedObjResults.addAll(updatedObjResults);
    return result;
  }

  SetResp._();

  factory SetResp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SetResp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SetResp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPM<SetResp_UpdatedObjectResult>(
        1, _omitFieldNames ? '' : 'updatedObjResults',
        subBuilder: SetResp_UpdatedObjectResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetResp copyWith(void Function(SetResp) updates) =>
      super.copyWith((message) => updates(message as SetResp)) as SetResp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetResp create() => SetResp._();
  @$core.override
  SetResp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SetResp getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetResp>(create);
  static SetResp? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SetResp_UpdatedObjectResult> get updatedObjResults => $_getList(0);
}

class Operate extends $pb.GeneratedMessage {
  factory Operate({
    $core.String? command,
    $core.String? commandKey,
    $core.bool? sendResp,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? inputArgs,
  }) {
    final result = create();
    if (command != null) result.command = command;
    if (commandKey != null) result.commandKey = commandKey;
    if (sendResp != null) result.sendResp = sendResp;
    if (inputArgs != null) result.inputArgs.addEntries(inputArgs);
    return result;
  }

  Operate._();

  factory Operate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Operate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Operate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'command')
    ..aOS(2, _omitFieldNames ? '' : 'commandKey')
    ..aOB(3, _omitFieldNames ? '' : 'sendResp')
    ..m<$core.String, $core.String>(4, _omitFieldNames ? '' : 'inputArgs',
        entryClassName: 'Operate.InputArgsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('usp'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Operate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Operate copyWith(void Function(Operate) updates) =>
      super.copyWith((message) => updates(message as Operate)) as Operate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Operate create() => Operate._();
  @$core.override
  Operate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Operate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Operate>(create);
  static Operate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get command => $_getSZ(0);
  @$pb.TagNumber(1)
  set command($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCommand() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommand() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get commandKey => $_getSZ(1);
  @$pb.TagNumber(2)
  set commandKey($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommandKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommandKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get sendResp => $_getBF(2);
  @$pb.TagNumber(3)
  set sendResp($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSendResp() => $_has(2);
  @$pb.TagNumber(3)
  void clearSendResp() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbMap<$core.String, $core.String> get inputArgs => $_getMap(3);
}

class OperateResp_OperationResult_OutputArgs extends $pb.GeneratedMessage {
  factory OperateResp_OperationResult_OutputArgs({
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? outputArgs,
  }) {
    final result = create();
    if (outputArgs != null) result.outputArgs.addEntries(outputArgs);
    return result;
  }

  OperateResp_OperationResult_OutputArgs._();

  factory OperateResp_OperationResult_OutputArgs.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OperateResp_OperationResult_OutputArgs.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OperateResp.OperationResult.OutputArgs',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..m<$core.String, $core.String>(1, _omitFieldNames ? '' : 'outputArgs',
        entryClassName:
            'OperateResp.OperationResult.OutputArgs.OutputArgsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('usp'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperateResp_OperationResult_OutputArgs clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperateResp_OperationResult_OutputArgs copyWith(
          void Function(OperateResp_OperationResult_OutputArgs) updates) =>
      super.copyWith((message) =>
              updates(message as OperateResp_OperationResult_OutputArgs))
          as OperateResp_OperationResult_OutputArgs;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OperateResp_OperationResult_OutputArgs create() =>
      OperateResp_OperationResult_OutputArgs._();
  @$core.override
  OperateResp_OperationResult_OutputArgs createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OperateResp_OperationResult_OutputArgs getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          OperateResp_OperationResult_OutputArgs>(create);
  static OperateResp_OperationResult_OutputArgs? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, $core.String> get outputArgs => $_getMap(0);
}

class OperateResp_OperationResult_CommandFailure extends $pb.GeneratedMessage {
  factory OperateResp_OperationResult_CommandFailure({
    $core.int? errCode,
    $core.String? errMsg,
  }) {
    final result = create();
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    return result;
  }

  OperateResp_OperationResult_CommandFailure._();

  factory OperateResp_OperationResult_CommandFailure.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OperateResp_OperationResult_CommandFailure.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OperateResp.OperationResult.CommandFailure',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(2, _omitFieldNames ? '' : 'errMsg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperateResp_OperationResult_CommandFailure clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperateResp_OperationResult_CommandFailure copyWith(
          void Function(OperateResp_OperationResult_CommandFailure) updates) =>
      super.copyWith((message) =>
              updates(message as OperateResp_OperationResult_CommandFailure))
          as OperateResp_OperationResult_CommandFailure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OperateResp_OperationResult_CommandFailure create() =>
      OperateResp_OperationResult_CommandFailure._();
  @$core.override
  OperateResp_OperationResult_CommandFailure createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OperateResp_OperationResult_CommandFailure getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          OperateResp_OperationResult_CommandFailure>(create);
  static OperateResp_OperationResult_CommandFailure? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get errCode => $_getIZ(0);
  @$pb.TagNumber(1)
  set errCode($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasErrCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearErrCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errMsg => $_getSZ(1);
  @$pb.TagNumber(2)
  set errMsg($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrMsg() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrMsg() => $_clearField(2);
}

enum OperateResp_OperationResult_OperationResp {
  reqObjPath,
  reqOutputArgs,
  cmdFailure,
  notSet
}

class OperateResp_OperationResult extends $pb.GeneratedMessage {
  factory OperateResp_OperationResult({
    $core.String? executedCommand,
    $core.String? reqObjPath,
    OperateResp_OperationResult_OutputArgs? reqOutputArgs,
    OperateResp_OperationResult_CommandFailure? cmdFailure,
  }) {
    final result = create();
    if (executedCommand != null) result.executedCommand = executedCommand;
    if (reqObjPath != null) result.reqObjPath = reqObjPath;
    if (reqOutputArgs != null) result.reqOutputArgs = reqOutputArgs;
    if (cmdFailure != null) result.cmdFailure = cmdFailure;
    return result;
  }

  OperateResp_OperationResult._();

  factory OperateResp_OperationResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OperateResp_OperationResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, OperateResp_OperationResult_OperationResp>
      _OperateResp_OperationResult_OperationRespByTag = {
    2: OperateResp_OperationResult_OperationResp.reqObjPath,
    3: OperateResp_OperationResult_OperationResp.reqOutputArgs,
    4: OperateResp_OperationResult_OperationResp.cmdFailure,
    0: OperateResp_OperationResult_OperationResp.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OperateResp.OperationResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4])
    ..aOS(1, _omitFieldNames ? '' : 'executedCommand')
    ..aOS(2, _omitFieldNames ? '' : 'reqObjPath')
    ..aOM<OperateResp_OperationResult_OutputArgs>(
        3, _omitFieldNames ? '' : 'reqOutputArgs',
        subBuilder: OperateResp_OperationResult_OutputArgs.create)
    ..aOM<OperateResp_OperationResult_CommandFailure>(
        4, _omitFieldNames ? '' : 'cmdFailure',
        subBuilder: OperateResp_OperationResult_CommandFailure.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperateResp_OperationResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperateResp_OperationResult copyWith(
          void Function(OperateResp_OperationResult) updates) =>
      super.copyWith(
              (message) => updates(message as OperateResp_OperationResult))
          as OperateResp_OperationResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OperateResp_OperationResult create() =>
      OperateResp_OperationResult._();
  @$core.override
  OperateResp_OperationResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OperateResp_OperationResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OperateResp_OperationResult>(create);
  static OperateResp_OperationResult? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  OperateResp_OperationResult_OperationResp whichOperationResp() =>
      _OperateResp_OperationResult_OperationRespByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  void clearOperationResp() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get executedCommand => $_getSZ(0);
  @$pb.TagNumber(1)
  set executedCommand($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExecutedCommand() => $_has(0);
  @$pb.TagNumber(1)
  void clearExecutedCommand() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get reqObjPath => $_getSZ(1);
  @$pb.TagNumber(2)
  set reqObjPath($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReqObjPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearReqObjPath() => $_clearField(2);

  @$pb.TagNumber(3)
  OperateResp_OperationResult_OutputArgs get reqOutputArgs => $_getN(2);
  @$pb.TagNumber(3)
  set reqOutputArgs(OperateResp_OperationResult_OutputArgs value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasReqOutputArgs() => $_has(2);
  @$pb.TagNumber(3)
  void clearReqOutputArgs() => $_clearField(3);
  @$pb.TagNumber(3)
  OperateResp_OperationResult_OutputArgs ensureReqOutputArgs() => $_ensure(2);

  @$pb.TagNumber(4)
  OperateResp_OperationResult_CommandFailure get cmdFailure => $_getN(3);
  @$pb.TagNumber(4)
  set cmdFailure(OperateResp_OperationResult_CommandFailure value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasCmdFailure() => $_has(3);
  @$pb.TagNumber(4)
  void clearCmdFailure() => $_clearField(4);
  @$pb.TagNumber(4)
  OperateResp_OperationResult_CommandFailure ensureCmdFailure() => $_ensure(3);
}

class OperateResp extends $pb.GeneratedMessage {
  factory OperateResp({
    $core.Iterable<OperateResp_OperationResult>? operationResults,
  }) {
    final result = create();
    if (operationResults != null)
      result.operationResults.addAll(operationResults);
    return result;
  }

  OperateResp._();

  factory OperateResp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OperateResp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OperateResp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPM<OperateResp_OperationResult>(
        1, _omitFieldNames ? '' : 'operationResults',
        subBuilder: OperateResp_OperationResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperateResp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OperateResp copyWith(void Function(OperateResp) updates) =>
      super.copyWith((message) => updates(message as OperateResp))
          as OperateResp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OperateResp create() => OperateResp._();
  @$core.override
  OperateResp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OperateResp getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OperateResp>(create);
  static OperateResp? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<OperateResp_OperationResult> get operationResults => $_getList(0);
}

class Notify_Event extends $pb.GeneratedMessage {
  factory Notify_Event({
    $core.String? objPath,
    $core.String? eventName,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? params,
  }) {
    final result = create();
    if (objPath != null) result.objPath = objPath;
    if (eventName != null) result.eventName = eventName;
    if (params != null) result.params.addEntries(params);
    return result;
  }

  Notify_Event._();

  factory Notify_Event.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Notify_Event.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Notify.Event',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'objPath')
    ..aOS(2, _omitFieldNames ? '' : 'eventName')
    ..m<$core.String, $core.String>(3, _omitFieldNames ? '' : 'params',
        entryClassName: 'Notify.Event.ParamsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('usp'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_Event clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_Event copyWith(void Function(Notify_Event) updates) =>
      super.copyWith((message) => updates(message as Notify_Event))
          as Notify_Event;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notify_Event create() => Notify_Event._();
  @$core.override
  Notify_Event createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Notify_Event getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Notify_Event>(create);
  static Notify_Event? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get objPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set objPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasObjPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get eventName => $_getSZ(1);
  @$pb.TagNumber(2)
  set eventName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEventName() => $_has(1);
  @$pb.TagNumber(2)
  void clearEventName() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbMap<$core.String, $core.String> get params => $_getMap(2);
}

class Notify_ValueChange extends $pb.GeneratedMessage {
  factory Notify_ValueChange({
    $core.String? paramPath,
    $core.String? paramValue,
  }) {
    final result = create();
    if (paramPath != null) result.paramPath = paramPath;
    if (paramValue != null) result.paramValue = paramValue;
    return result;
  }

  Notify_ValueChange._();

  factory Notify_ValueChange.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Notify_ValueChange.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Notify.ValueChange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'paramPath')
    ..aOS(2, _omitFieldNames ? '' : 'paramValue')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_ValueChange clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_ValueChange copyWith(void Function(Notify_ValueChange) updates) =>
      super.copyWith((message) => updates(message as Notify_ValueChange))
          as Notify_ValueChange;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notify_ValueChange create() => Notify_ValueChange._();
  @$core.override
  Notify_ValueChange createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Notify_ValueChange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Notify_ValueChange>(create);
  static Notify_ValueChange? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get paramPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set paramPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasParamPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearParamPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get paramValue => $_getSZ(1);
  @$pb.TagNumber(2)
  set paramValue($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasParamValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearParamValue() => $_clearField(2);
}

class Notify_ObjectCreation extends $pb.GeneratedMessage {
  factory Notify_ObjectCreation({
    $core.String? objPath,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? uniqueKeys,
  }) {
    final result = create();
    if (objPath != null) result.objPath = objPath;
    if (uniqueKeys != null) result.uniqueKeys.addEntries(uniqueKeys);
    return result;
  }

  Notify_ObjectCreation._();

  factory Notify_ObjectCreation.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Notify_ObjectCreation.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Notify.ObjectCreation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'objPath')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'uniqueKeys',
        entryClassName: 'Notify.ObjectCreation.UniqueKeysEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('usp'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_ObjectCreation clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_ObjectCreation copyWith(
          void Function(Notify_ObjectCreation) updates) =>
      super.copyWith((message) => updates(message as Notify_ObjectCreation))
          as Notify_ObjectCreation;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notify_ObjectCreation create() => Notify_ObjectCreation._();
  @$core.override
  Notify_ObjectCreation createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Notify_ObjectCreation getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Notify_ObjectCreation>(create);
  static Notify_ObjectCreation? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get objPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set objPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasObjPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get uniqueKeys => $_getMap(1);
}

class Notify_ObjectDeletion extends $pb.GeneratedMessage {
  factory Notify_ObjectDeletion({
    $core.String? objPath,
  }) {
    final result = create();
    if (objPath != null) result.objPath = objPath;
    return result;
  }

  Notify_ObjectDeletion._();

  factory Notify_ObjectDeletion.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Notify_ObjectDeletion.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Notify.ObjectDeletion',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'objPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_ObjectDeletion clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_ObjectDeletion copyWith(
          void Function(Notify_ObjectDeletion) updates) =>
      super.copyWith((message) => updates(message as Notify_ObjectDeletion))
          as Notify_ObjectDeletion;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notify_ObjectDeletion create() => Notify_ObjectDeletion._();
  @$core.override
  Notify_ObjectDeletion createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Notify_ObjectDeletion getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Notify_ObjectDeletion>(create);
  static Notify_ObjectDeletion? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get objPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set objPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasObjPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjPath() => $_clearField(1);
}

class Notify_OperationComplete_OutputArgs extends $pb.GeneratedMessage {
  factory Notify_OperationComplete_OutputArgs({
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? outputArgs,
  }) {
    final result = create();
    if (outputArgs != null) result.outputArgs.addEntries(outputArgs);
    return result;
  }

  Notify_OperationComplete_OutputArgs._();

  factory Notify_OperationComplete_OutputArgs.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Notify_OperationComplete_OutputArgs.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Notify.OperationComplete.OutputArgs',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..m<$core.String, $core.String>(1, _omitFieldNames ? '' : 'outputArgs',
        entryClassName: 'Notify.OperationComplete.OutputArgs.OutputArgsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('usp'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_OperationComplete_OutputArgs clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_OperationComplete_OutputArgs copyWith(
          void Function(Notify_OperationComplete_OutputArgs) updates) =>
      super.copyWith((message) =>
              updates(message as Notify_OperationComplete_OutputArgs))
          as Notify_OperationComplete_OutputArgs;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notify_OperationComplete_OutputArgs create() =>
      Notify_OperationComplete_OutputArgs._();
  @$core.override
  Notify_OperationComplete_OutputArgs createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Notify_OperationComplete_OutputArgs getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          Notify_OperationComplete_OutputArgs>(create);
  static Notify_OperationComplete_OutputArgs? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbMap<$core.String, $core.String> get outputArgs => $_getMap(0);
}

class Notify_OperationComplete_CommandFailure extends $pb.GeneratedMessage {
  factory Notify_OperationComplete_CommandFailure({
    $core.int? errCode,
    $core.String? errMsg,
  }) {
    final result = create();
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    return result;
  }

  Notify_OperationComplete_CommandFailure._();

  factory Notify_OperationComplete_CommandFailure.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Notify_OperationComplete_CommandFailure.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Notify.OperationComplete.CommandFailure',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(2, _omitFieldNames ? '' : 'errMsg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_OperationComplete_CommandFailure clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_OperationComplete_CommandFailure copyWith(
          void Function(Notify_OperationComplete_CommandFailure) updates) =>
      super.copyWith((message) =>
              updates(message as Notify_OperationComplete_CommandFailure))
          as Notify_OperationComplete_CommandFailure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notify_OperationComplete_CommandFailure create() =>
      Notify_OperationComplete_CommandFailure._();
  @$core.override
  Notify_OperationComplete_CommandFailure createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Notify_OperationComplete_CommandFailure getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          Notify_OperationComplete_CommandFailure>(create);
  static Notify_OperationComplete_CommandFailure? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get errCode => $_getIZ(0);
  @$pb.TagNumber(1)
  set errCode($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasErrCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearErrCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errMsg => $_getSZ(1);
  @$pb.TagNumber(2)
  set errMsg($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrMsg() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrMsg() => $_clearField(2);
}

enum Notify_OperationComplete_OperationResp {
  reqOutputArgs,
  cmdFailure,
  notSet
}

class Notify_OperationComplete extends $pb.GeneratedMessage {
  factory Notify_OperationComplete({
    $core.String? objPath,
    $core.String? commandName,
    $core.String? commandKey,
    Notify_OperationComplete_OutputArgs? reqOutputArgs,
    Notify_OperationComplete_CommandFailure? cmdFailure,
  }) {
    final result = create();
    if (objPath != null) result.objPath = objPath;
    if (commandName != null) result.commandName = commandName;
    if (commandKey != null) result.commandKey = commandKey;
    if (reqOutputArgs != null) result.reqOutputArgs = reqOutputArgs;
    if (cmdFailure != null) result.cmdFailure = cmdFailure;
    return result;
  }

  Notify_OperationComplete._();

  factory Notify_OperationComplete.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Notify_OperationComplete.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Notify_OperationComplete_OperationResp>
      _Notify_OperationComplete_OperationRespByTag = {
    4: Notify_OperationComplete_OperationResp.reqOutputArgs,
    5: Notify_OperationComplete_OperationResp.cmdFailure,
    0: Notify_OperationComplete_OperationResp.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Notify.OperationComplete',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..oo(0, [4, 5])
    ..aOS(1, _omitFieldNames ? '' : 'objPath')
    ..aOS(2, _omitFieldNames ? '' : 'commandName')
    ..aOS(3, _omitFieldNames ? '' : 'commandKey')
    ..aOM<Notify_OperationComplete_OutputArgs>(
        4, _omitFieldNames ? '' : 'reqOutputArgs',
        subBuilder: Notify_OperationComplete_OutputArgs.create)
    ..aOM<Notify_OperationComplete_CommandFailure>(
        5, _omitFieldNames ? '' : 'cmdFailure',
        subBuilder: Notify_OperationComplete_CommandFailure.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_OperationComplete clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_OperationComplete copyWith(
          void Function(Notify_OperationComplete) updates) =>
      super.copyWith((message) => updates(message as Notify_OperationComplete))
          as Notify_OperationComplete;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notify_OperationComplete create() => Notify_OperationComplete._();
  @$core.override
  Notify_OperationComplete createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Notify_OperationComplete getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Notify_OperationComplete>(create);
  static Notify_OperationComplete? _defaultInstance;

  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  Notify_OperationComplete_OperationResp whichOperationResp() =>
      _Notify_OperationComplete_OperationRespByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  void clearOperationResp() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get objPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set objPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasObjPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearObjPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get commandName => $_getSZ(1);
  @$pb.TagNumber(2)
  set commandName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommandName() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommandName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get commandKey => $_getSZ(2);
  @$pb.TagNumber(3)
  set commandKey($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCommandKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommandKey() => $_clearField(3);

  @$pb.TagNumber(4)
  Notify_OperationComplete_OutputArgs get reqOutputArgs => $_getN(3);
  @$pb.TagNumber(4)
  set reqOutputArgs(Notify_OperationComplete_OutputArgs value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasReqOutputArgs() => $_has(3);
  @$pb.TagNumber(4)
  void clearReqOutputArgs() => $_clearField(4);
  @$pb.TagNumber(4)
  Notify_OperationComplete_OutputArgs ensureReqOutputArgs() => $_ensure(3);

  @$pb.TagNumber(5)
  Notify_OperationComplete_CommandFailure get cmdFailure => $_getN(4);
  @$pb.TagNumber(5)
  set cmdFailure(Notify_OperationComplete_CommandFailure value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasCmdFailure() => $_has(4);
  @$pb.TagNumber(5)
  void clearCmdFailure() => $_clearField(5);
  @$pb.TagNumber(5)
  Notify_OperationComplete_CommandFailure ensureCmdFailure() => $_ensure(4);
}

class Notify_OnBoardRequest extends $pb.GeneratedMessage {
  factory Notify_OnBoardRequest({
    $core.String? oui,
    $core.String? productClass,
    $core.String? serialNumber,
    $core.String? agentSupportedProtocolVersions,
  }) {
    final result = create();
    if (oui != null) result.oui = oui;
    if (productClass != null) result.productClass = productClass;
    if (serialNumber != null) result.serialNumber = serialNumber;
    if (agentSupportedProtocolVersions != null)
      result.agentSupportedProtocolVersions = agentSupportedProtocolVersions;
    return result;
  }

  Notify_OnBoardRequest._();

  factory Notify_OnBoardRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Notify_OnBoardRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Notify.OnBoardRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'oui')
    ..aOS(2, _omitFieldNames ? '' : 'productClass')
    ..aOS(3, _omitFieldNames ? '' : 'serialNumber')
    ..aOS(4, _omitFieldNames ? '' : 'agentSupportedProtocolVersions')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_OnBoardRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify_OnBoardRequest copyWith(
          void Function(Notify_OnBoardRequest) updates) =>
      super.copyWith((message) => updates(message as Notify_OnBoardRequest))
          as Notify_OnBoardRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notify_OnBoardRequest create() => Notify_OnBoardRequest._();
  @$core.override
  Notify_OnBoardRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Notify_OnBoardRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Notify_OnBoardRequest>(create);
  static Notify_OnBoardRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get oui => $_getSZ(0);
  @$pb.TagNumber(1)
  set oui($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOui() => $_has(0);
  @$pb.TagNumber(1)
  void clearOui() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get productClass => $_getSZ(1);
  @$pb.TagNumber(2)
  set productClass($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProductClass() => $_has(1);
  @$pb.TagNumber(2)
  void clearProductClass() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get serialNumber => $_getSZ(2);
  @$pb.TagNumber(3)
  set serialNumber($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSerialNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearSerialNumber() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get agentSupportedProtocolVersions => $_getSZ(3);
  @$pb.TagNumber(4)
  set agentSupportedProtocolVersions($core.String value) =>
      $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAgentSupportedProtocolVersions() => $_has(3);
  @$pb.TagNumber(4)
  void clearAgentSupportedProtocolVersions() => $_clearField(4);
}

enum Notify_Notification {
  event,
  valueChange,
  objCreation,
  objDeletion,
  operComplete,
  onBoardReq,
  notSet
}

class Notify extends $pb.GeneratedMessage {
  factory Notify({
    $core.String? subscriptionId,
    $core.bool? sendResp,
    Notify_Event? event,
    Notify_ValueChange? valueChange,
    Notify_ObjectCreation? objCreation,
    Notify_ObjectDeletion? objDeletion,
    Notify_OperationComplete? operComplete,
    Notify_OnBoardRequest? onBoardReq,
  }) {
    final result = create();
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    if (sendResp != null) result.sendResp = sendResp;
    if (event != null) result.event = event;
    if (valueChange != null) result.valueChange = valueChange;
    if (objCreation != null) result.objCreation = objCreation;
    if (objDeletion != null) result.objDeletion = objDeletion;
    if (operComplete != null) result.operComplete = operComplete;
    if (onBoardReq != null) result.onBoardReq = onBoardReq;
    return result;
  }

  Notify._();

  factory Notify.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Notify.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Notify_Notification>
      _Notify_NotificationByTag = {
    3: Notify_Notification.event,
    4: Notify_Notification.valueChange,
    5: Notify_Notification.objCreation,
    6: Notify_Notification.objDeletion,
    7: Notify_Notification.operComplete,
    8: Notify_Notification.onBoardReq,
    0: Notify_Notification.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Notify',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..oo(0, [3, 4, 5, 6, 7, 8])
    ..aOS(1, _omitFieldNames ? '' : 'subscriptionId')
    ..aOB(2, _omitFieldNames ? '' : 'sendResp')
    ..aOM<Notify_Event>(3, _omitFieldNames ? '' : 'event',
        subBuilder: Notify_Event.create)
    ..aOM<Notify_ValueChange>(4, _omitFieldNames ? '' : 'valueChange',
        subBuilder: Notify_ValueChange.create)
    ..aOM<Notify_ObjectCreation>(5, _omitFieldNames ? '' : 'objCreation',
        subBuilder: Notify_ObjectCreation.create)
    ..aOM<Notify_ObjectDeletion>(6, _omitFieldNames ? '' : 'objDeletion',
        subBuilder: Notify_ObjectDeletion.create)
    ..aOM<Notify_OperationComplete>(7, _omitFieldNames ? '' : 'operComplete',
        subBuilder: Notify_OperationComplete.create)
    ..aOM<Notify_OnBoardRequest>(8, _omitFieldNames ? '' : 'onBoardReq',
        subBuilder: Notify_OnBoardRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Notify copyWith(void Function(Notify) updates) =>
      super.copyWith((message) => updates(message as Notify)) as Notify;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Notify create() => Notify._();
  @$core.override
  Notify createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Notify getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Notify>(create);
  static Notify? _defaultInstance;

  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  Notify_Notification whichNotification() =>
      _Notify_NotificationByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  void clearNotification() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get subscriptionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscriptionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscriptionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscriptionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get sendResp => $_getBF(1);
  @$pb.TagNumber(2)
  set sendResp($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSendResp() => $_has(1);
  @$pb.TagNumber(2)
  void clearSendResp() => $_clearField(2);

  @$pb.TagNumber(3)
  Notify_Event get event => $_getN(2);
  @$pb.TagNumber(3)
  set event(Notify_Event value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasEvent() => $_has(2);
  @$pb.TagNumber(3)
  void clearEvent() => $_clearField(3);
  @$pb.TagNumber(3)
  Notify_Event ensureEvent() => $_ensure(2);

  @$pb.TagNumber(4)
  Notify_ValueChange get valueChange => $_getN(3);
  @$pb.TagNumber(4)
  set valueChange(Notify_ValueChange value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasValueChange() => $_has(3);
  @$pb.TagNumber(4)
  void clearValueChange() => $_clearField(4);
  @$pb.TagNumber(4)
  Notify_ValueChange ensureValueChange() => $_ensure(3);

  @$pb.TagNumber(5)
  Notify_ObjectCreation get objCreation => $_getN(4);
  @$pb.TagNumber(5)
  set objCreation(Notify_ObjectCreation value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasObjCreation() => $_has(4);
  @$pb.TagNumber(5)
  void clearObjCreation() => $_clearField(5);
  @$pb.TagNumber(5)
  Notify_ObjectCreation ensureObjCreation() => $_ensure(4);

  @$pb.TagNumber(6)
  Notify_ObjectDeletion get objDeletion => $_getN(5);
  @$pb.TagNumber(6)
  set objDeletion(Notify_ObjectDeletion value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasObjDeletion() => $_has(5);
  @$pb.TagNumber(6)
  void clearObjDeletion() => $_clearField(6);
  @$pb.TagNumber(6)
  Notify_ObjectDeletion ensureObjDeletion() => $_ensure(5);

  @$pb.TagNumber(7)
  Notify_OperationComplete get operComplete => $_getN(6);
  @$pb.TagNumber(7)
  set operComplete(Notify_OperationComplete value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasOperComplete() => $_has(6);
  @$pb.TagNumber(7)
  void clearOperComplete() => $_clearField(7);
  @$pb.TagNumber(7)
  Notify_OperationComplete ensureOperComplete() => $_ensure(6);

  @$pb.TagNumber(8)
  Notify_OnBoardRequest get onBoardReq => $_getN(7);
  @$pb.TagNumber(8)
  set onBoardReq(Notify_OnBoardRequest value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasOnBoardReq() => $_has(7);
  @$pb.TagNumber(8)
  void clearOnBoardReq() => $_clearField(8);
  @$pb.TagNumber(8)
  Notify_OnBoardRequest ensureOnBoardReq() => $_ensure(7);
}

class NotifyResp extends $pb.GeneratedMessage {
  factory NotifyResp({
    $core.String? subscriptionId,
  }) {
    final result = create();
    if (subscriptionId != null) result.subscriptionId = subscriptionId;
    return result;
  }

  NotifyResp._();

  factory NotifyResp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NotifyResp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NotifyResp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'subscriptionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotifyResp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotifyResp copyWith(void Function(NotifyResp) updates) =>
      super.copyWith((message) => updates(message as NotifyResp)) as NotifyResp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NotifyResp create() => NotifyResp._();
  @$core.override
  NotifyResp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NotifyResp getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NotifyResp>(create);
  static NotifyResp? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get subscriptionId => $_getSZ(0);
  @$pb.TagNumber(1)
  set subscriptionId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSubscriptionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSubscriptionId() => $_clearField(1);
}

class Register_RegistrationPath extends $pb.GeneratedMessage {
  factory Register_RegistrationPath({
    $core.String? path,
  }) {
    final result = create();
    if (path != null) result.path = path;
    return result;
  }

  Register_RegistrationPath._();

  factory Register_RegistrationPath.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Register_RegistrationPath.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Register.RegistrationPath',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Register_RegistrationPath clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Register_RegistrationPath copyWith(
          void Function(Register_RegistrationPath) updates) =>
      super.copyWith((message) => updates(message as Register_RegistrationPath))
          as Register_RegistrationPath;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Register_RegistrationPath create() => Register_RegistrationPath._();
  @$core.override
  Register_RegistrationPath createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Register_RegistrationPath getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Register_RegistrationPath>(create);
  static Register_RegistrationPath? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);
}

class Register extends $pb.GeneratedMessage {
  factory Register({
    $core.bool? allowPartial,
    $core.Iterable<Register_RegistrationPath>? regPaths,
  }) {
    final result = create();
    if (allowPartial != null) result.allowPartial = allowPartial;
    if (regPaths != null) result.regPaths.addAll(regPaths);
    return result;
  }

  Register._();

  factory Register.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Register.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Register',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'allowPartial')
    ..pPM<Register_RegistrationPath>(2, _omitFieldNames ? '' : 'regPaths',
        subBuilder: Register_RegistrationPath.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Register clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Register copyWith(void Function(Register) updates) =>
      super.copyWith((message) => updates(message as Register)) as Register;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Register create() => Register._();
  @$core.override
  Register createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Register getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Register>(create);
  static Register? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get allowPartial => $_getBF(0);
  @$pb.TagNumber(1)
  set allowPartial($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAllowPartial() => $_has(0);
  @$pb.TagNumber(1)
  void clearAllowPartial() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Register_RegistrationPath> get regPaths => $_getList(1);
}

class RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure
    extends $pb.GeneratedMessage {
  factory RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure({
    $core.int? errCode,
    $core.String? errMsg,
  }) {
    final result = create();
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    return result;
  }

  RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure._();

  factory RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'RegisterResp.RegisteredPathResult.OperationStatus.OperationFailure',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(2, _omitFieldNames ? '' : 'errMsg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure clone() =>
      deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure copyWith(
          void Function(
                  RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure)
              updates) =>
      super.copyWith((message) => updates(message
              as RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure))
          as RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure
      create() =>
          RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure
              ._();
  @$core.override
  RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure>(
          create);
  static RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get errCode => $_getIZ(0);
  @$pb.TagNumber(1)
  set errCode($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasErrCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearErrCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errMsg => $_getSZ(1);
  @$pb.TagNumber(2)
  set errMsg($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrMsg() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrMsg() => $_clearField(2);
}

class RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess
    extends $pb.GeneratedMessage {
  factory RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess({
    $core.String? registeredPath,
  }) {
    final result = create();
    if (registeredPath != null) result.registeredPath = registeredPath;
    return result;
  }

  RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess._();

  factory RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'RegisterResp.RegisteredPathResult.OperationStatus.OperationSuccess',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'registeredPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess clone() =>
      deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess copyWith(
          void Function(
                  RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess)
              updates) =>
      super.copyWith((message) => updates(message
              as RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess))
          as RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess
      create() =>
          RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess
              ._();
  @$core.override
  RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess>(
          create);
  static RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get registeredPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set registeredPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRegisteredPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearRegisteredPath() => $_clearField(1);
}

enum RegisterResp_RegisteredPathResult_OperationStatus_OperStatus {
  operFailure,
  operSuccess,
  notSet
}

class RegisterResp_RegisteredPathResult_OperationStatus
    extends $pb.GeneratedMessage {
  factory RegisterResp_RegisteredPathResult_OperationStatus({
    RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure?
        operFailure,
    RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess?
        operSuccess,
  }) {
    final result = create();
    if (operFailure != null) result.operFailure = operFailure;
    if (operSuccess != null) result.operSuccess = operSuccess;
    return result;
  }

  RegisterResp_RegisteredPathResult_OperationStatus._();

  factory RegisterResp_RegisteredPathResult_OperationStatus.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterResp_RegisteredPathResult_OperationStatus.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int,
          RegisterResp_RegisteredPathResult_OperationStatus_OperStatus>
      _RegisterResp_RegisteredPathResult_OperationStatus_OperStatusByTag = {
    1: RegisterResp_RegisteredPathResult_OperationStatus_OperStatus.operFailure,
    2: RegisterResp_RegisteredPathResult_OperationStatus_OperStatus.operSuccess,
    0: RegisterResp_RegisteredPathResult_OperationStatus_OperStatus.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'RegisterResp.RegisteredPathResult.OperationStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure>(
        1, _omitFieldNames ? '' : 'operFailure',
        subBuilder:
            RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure
                .create)
    ..aOM<RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess>(
        2, _omitFieldNames ? '' : 'operSuccess',
        subBuilder:
            RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess
                .create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResp_RegisteredPathResult_OperationStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResp_RegisteredPathResult_OperationStatus copyWith(
          void Function(RegisterResp_RegisteredPathResult_OperationStatus)
              updates) =>
      super.copyWith((message) => updates(
              message as RegisterResp_RegisteredPathResult_OperationStatus))
          as RegisterResp_RegisteredPathResult_OperationStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterResp_RegisteredPathResult_OperationStatus create() =>
      RegisterResp_RegisteredPathResult_OperationStatus._();
  @$core.override
  RegisterResp_RegisteredPathResult_OperationStatus createEmptyInstance() =>
      create();
  @$core.pragma('dart2js:noInline')
  static RegisterResp_RegisteredPathResult_OperationStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          RegisterResp_RegisteredPathResult_OperationStatus>(create);
  static RegisterResp_RegisteredPathResult_OperationStatus? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  RegisterResp_RegisteredPathResult_OperationStatus_OperStatus
      whichOperStatus() =>
          _RegisterResp_RegisteredPathResult_OperationStatus_OperStatusByTag[
              $_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOperStatus() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure
      get operFailure => $_getN(0);
  @$pb.TagNumber(1)
  set operFailure(
          RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure
              value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOperFailure() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperFailure() => $_clearField(1);
  @$pb.TagNumber(1)
  RegisterResp_RegisteredPathResult_OperationStatus_OperationFailure
      ensureOperFailure() => $_ensure(0);

  @$pb.TagNumber(2)
  RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess
      get operSuccess => $_getN(1);
  @$pb.TagNumber(2)
  set operSuccess(
          RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess
              value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperSuccess() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperSuccess() => $_clearField(2);
  @$pb.TagNumber(2)
  RegisterResp_RegisteredPathResult_OperationStatus_OperationSuccess
      ensureOperSuccess() => $_ensure(1);
}

class RegisterResp_RegisteredPathResult extends $pb.GeneratedMessage {
  factory RegisterResp_RegisteredPathResult({
    $core.String? requestedPath,
    RegisterResp_RegisteredPathResult_OperationStatus? operStatus,
  }) {
    final result = create();
    if (requestedPath != null) result.requestedPath = requestedPath;
    if (operStatus != null) result.operStatus = operStatus;
    return result;
  }

  RegisterResp_RegisteredPathResult._();

  factory RegisterResp_RegisteredPathResult.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterResp_RegisteredPathResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterResp.RegisteredPathResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestedPath')
    ..aOM<RegisterResp_RegisteredPathResult_OperationStatus>(
        2, _omitFieldNames ? '' : 'operStatus',
        subBuilder: RegisterResp_RegisteredPathResult_OperationStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResp_RegisteredPathResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResp_RegisteredPathResult copyWith(
          void Function(RegisterResp_RegisteredPathResult) updates) =>
      super.copyWith((message) =>
              updates(message as RegisterResp_RegisteredPathResult))
          as RegisterResp_RegisteredPathResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterResp_RegisteredPathResult create() =>
      RegisterResp_RegisteredPathResult._();
  @$core.override
  RegisterResp_RegisteredPathResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegisterResp_RegisteredPathResult getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterResp_RegisteredPathResult>(
          create);
  static RegisterResp_RegisteredPathResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestedPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestedPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestedPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestedPath() => $_clearField(1);

  @$pb.TagNumber(2)
  RegisterResp_RegisteredPathResult_OperationStatus get operStatus => $_getN(1);
  @$pb.TagNumber(2)
  set operStatus(RegisterResp_RegisteredPathResult_OperationStatus value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperStatus() => $_clearField(2);
  @$pb.TagNumber(2)
  RegisterResp_RegisteredPathResult_OperationStatus ensureOperStatus() =>
      $_ensure(1);
}

class RegisterResp extends $pb.GeneratedMessage {
  factory RegisterResp({
    $core.Iterable<RegisterResp_RegisteredPathResult>? registeredPathResults,
  }) {
    final result = create();
    if (registeredPathResults != null)
      result.registeredPathResults.addAll(registeredPathResults);
    return result;
  }

  RegisterResp._();

  factory RegisterResp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RegisterResp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RegisterResp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPM<RegisterResp_RegisteredPathResult>(
        1, _omitFieldNames ? '' : 'registeredPathResults',
        subBuilder: RegisterResp_RegisteredPathResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RegisterResp copyWith(void Function(RegisterResp) updates) =>
      super.copyWith((message) => updates(message as RegisterResp))
          as RegisterResp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RegisterResp create() => RegisterResp._();
  @$core.override
  RegisterResp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RegisterResp getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RegisterResp>(create);
  static RegisterResp? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<RegisterResp_RegisteredPathResult> get registeredPathResults =>
      $_getList(0);
}

class Deregister extends $pb.GeneratedMessage {
  factory Deregister({
    $core.Iterable<$core.String>? paths,
  }) {
    final result = create();
    if (paths != null) result.paths.addAll(paths);
    return result;
  }

  Deregister._();

  factory Deregister.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Deregister.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Deregister',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'paths')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Deregister clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Deregister copyWith(void Function(Deregister) updates) =>
      super.copyWith((message) => updates(message as Deregister)) as Deregister;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Deregister create() => Deregister._();
  @$core.override
  Deregister createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Deregister getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Deregister>(create);
  static Deregister? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get paths => $_getList(0);
}

class DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure
    extends $pb.GeneratedMessage {
  factory DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure({
    $core.int? errCode,
    $core.String? errMsg,
  }) {
    final result = create();
    if (errCode != null) result.errCode = errCode;
    if (errMsg != null) result.errMsg = errMsg;
    return result;
  }

  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure._();

  factory DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'DeregisterResp.DeregisteredPathResult.OperationStatus.OperationFailure',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'errCode', fieldType: $pb.PbFieldType.OF3)
    ..aOS(2, _omitFieldNames ? '' : 'errMsg')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure
      clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure copyWith(
          void Function(
                  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure)
              updates) =>
      super.copyWith((message) => updates(message
              as DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure))
          as DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure
      create() =>
          DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure
              ._();
  @$core.override
  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure>(
          create);
  static DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure?
      _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get errCode => $_getIZ(0);
  @$pb.TagNumber(1)
  set errCode($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasErrCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearErrCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get errMsg => $_getSZ(1);
  @$pb.TagNumber(2)
  set errMsg($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasErrMsg() => $_has(1);
  @$pb.TagNumber(2)
  void clearErrMsg() => $_clearField(2);
}

class DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess
    extends $pb.GeneratedMessage {
  factory DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess({
    $core.Iterable<$core.String>? deregisteredPath,
  }) {
    final result = create();
    if (deregisteredPath != null)
      result.deregisteredPath.addAll(deregisteredPath);
    return result;
  }

  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess._();

  factory DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'DeregisterResp.DeregisteredPathResult.OperationStatus.OperationSuccess',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'deregisteredPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess
      clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess copyWith(
          void Function(
                  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess)
              updates) =>
      super.copyWith((message) => updates(message
              as DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess))
          as DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess
      create() =>
          DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess
              ._();
  @$core.override
  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess
      createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess>(
          create);
  static DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess?
      _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get deregisteredPath => $_getList(0);
}

enum DeregisterResp_DeregisteredPathResult_OperationStatus_OperStatus {
  operFailure,
  operSuccess,
  notSet
}

class DeregisterResp_DeregisteredPathResult_OperationStatus
    extends $pb.GeneratedMessage {
  factory DeregisterResp_DeregisteredPathResult_OperationStatus({
    DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure?
        operFailure,
    DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess?
        operSuccess,
  }) {
    final result = create();
    if (operFailure != null) result.operFailure = operFailure;
    if (operSuccess != null) result.operSuccess = operSuccess;
    return result;
  }

  DeregisterResp_DeregisteredPathResult_OperationStatus._();

  factory DeregisterResp_DeregisteredPathResult_OperationStatus.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeregisterResp_DeregisteredPathResult_OperationStatus.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int,
          DeregisterResp_DeregisteredPathResult_OperationStatus_OperStatus>
      _DeregisterResp_DeregisteredPathResult_OperationStatus_OperStatusByTag = {
    1: DeregisterResp_DeregisteredPathResult_OperationStatus_OperStatus
        .operFailure,
    2: DeregisterResp_DeregisteredPathResult_OperationStatus_OperStatus
        .operSuccess,
    0: DeregisterResp_DeregisteredPathResult_OperationStatus_OperStatus.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'DeregisterResp.DeregisteredPathResult.OperationStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure>(
        1, _omitFieldNames ? '' : 'operFailure',
        subBuilder:
            DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure
                .create)
    ..aOM<DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess>(
        2, _omitFieldNames ? '' : 'operSuccess',
        subBuilder:
            DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess
                .create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeregisterResp_DeregisteredPathResult_OperationStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeregisterResp_DeregisteredPathResult_OperationStatus copyWith(
          void Function(DeregisterResp_DeregisteredPathResult_OperationStatus)
              updates) =>
      super.copyWith((message) => updates(
              message as DeregisterResp_DeregisteredPathResult_OperationStatus))
          as DeregisterResp_DeregisteredPathResult_OperationStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeregisterResp_DeregisteredPathResult_OperationStatus create() =>
      DeregisterResp_DeregisteredPathResult_OperationStatus._();
  @$core.override
  DeregisterResp_DeregisteredPathResult_OperationStatus createEmptyInstance() =>
      create();
  @$core.pragma('dart2js:noInline')
  static DeregisterResp_DeregisteredPathResult_OperationStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          DeregisterResp_DeregisteredPathResult_OperationStatus>(create);
  static DeregisterResp_DeregisteredPathResult_OperationStatus?
      _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  DeregisterResp_DeregisteredPathResult_OperationStatus_OperStatus
      whichOperStatus() =>
          _DeregisterResp_DeregisteredPathResult_OperationStatus_OperStatusByTag[
              $_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearOperStatus() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure
      get operFailure => $_getN(0);
  @$pb.TagNumber(1)
  set operFailure(
          DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure
              value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOperFailure() => $_has(0);
  @$pb.TagNumber(1)
  void clearOperFailure() => $_clearField(1);
  @$pb.TagNumber(1)
  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationFailure
      ensureOperFailure() => $_ensure(0);

  @$pb.TagNumber(2)
  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess
      get operSuccess => $_getN(1);
  @$pb.TagNumber(2)
  set operSuccess(
          DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess
              value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperSuccess() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperSuccess() => $_clearField(2);
  @$pb.TagNumber(2)
  DeregisterResp_DeregisteredPathResult_OperationStatus_OperationSuccess
      ensureOperSuccess() => $_ensure(1);
}

class DeregisterResp_DeregisteredPathResult extends $pb.GeneratedMessage {
  factory DeregisterResp_DeregisteredPathResult({
    $core.String? requestedPath,
    DeregisterResp_DeregisteredPathResult_OperationStatus? operStatus,
  }) {
    final result = create();
    if (requestedPath != null) result.requestedPath = requestedPath;
    if (operStatus != null) result.operStatus = operStatus;
    return result;
  }

  DeregisterResp_DeregisteredPathResult._();

  factory DeregisterResp_DeregisteredPathResult.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeregisterResp_DeregisteredPathResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeregisterResp.DeregisteredPathResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestedPath')
    ..aOM<DeregisterResp_DeregisteredPathResult_OperationStatus>(
        2, _omitFieldNames ? '' : 'operStatus',
        subBuilder:
            DeregisterResp_DeregisteredPathResult_OperationStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeregisterResp_DeregisteredPathResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeregisterResp_DeregisteredPathResult copyWith(
          void Function(DeregisterResp_DeregisteredPathResult) updates) =>
      super.copyWith((message) =>
              updates(message as DeregisterResp_DeregisteredPathResult))
          as DeregisterResp_DeregisteredPathResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeregisterResp_DeregisteredPathResult create() =>
      DeregisterResp_DeregisteredPathResult._();
  @$core.override
  DeregisterResp_DeregisteredPathResult createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeregisterResp_DeregisteredPathResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          DeregisterResp_DeregisteredPathResult>(create);
  static DeregisterResp_DeregisteredPathResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get requestedPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestedPath($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRequestedPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestedPath() => $_clearField(1);

  @$pb.TagNumber(2)
  DeregisterResp_DeregisteredPathResult_OperationStatus get operStatus =>
      $_getN(1);
  @$pb.TagNumber(2)
  set operStatus(DeregisterResp_DeregisteredPathResult_OperationStatus value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasOperStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearOperStatus() => $_clearField(2);
  @$pb.TagNumber(2)
  DeregisterResp_DeregisteredPathResult_OperationStatus ensureOperStatus() =>
      $_ensure(1);
}

class DeregisterResp extends $pb.GeneratedMessage {
  factory DeregisterResp({
    $core.Iterable<DeregisterResp_DeregisteredPathResult>?
        deregisteredPathResults,
  }) {
    final result = create();
    if (deregisteredPathResults != null)
      result.deregisteredPathResults.addAll(deregisteredPathResults);
    return result;
  }

  DeregisterResp._();

  factory DeregisterResp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeregisterResp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeregisterResp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp'),
      createEmptyInstance: create)
    ..pPM<DeregisterResp_DeregisteredPathResult>(
        1, _omitFieldNames ? '' : 'deregisteredPathResults',
        subBuilder: DeregisterResp_DeregisteredPathResult.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeregisterResp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeregisterResp copyWith(void Function(DeregisterResp) updates) =>
      super.copyWith((message) => updates(message as DeregisterResp))
          as DeregisterResp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeregisterResp create() => DeregisterResp._();
  @$core.override
  DeregisterResp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeregisterResp getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeregisterResp>(create);
  static DeregisterResp? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<DeregisterResp_DeregisteredPathResult>
      get deregisteredPathResults => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
