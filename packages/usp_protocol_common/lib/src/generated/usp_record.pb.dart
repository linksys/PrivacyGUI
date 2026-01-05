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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'usp_record.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'usp_record.pbenum.dart';

enum Record_RecordType {
  noSessionContext,
  sessionContext,
  websocketConnect,
  mqttConnect,
  stompConnect,
  disconnect,
  udsConnect,
  notSet
}

class Record extends $pb.GeneratedMessage {
  factory Record({
    $core.String? version,
    $core.String? toId,
    $core.String? fromId,
    Record_PayloadSecurity? payloadSecurity,
    $core.List<$core.int>? macSignature,
    $core.List<$core.int>? senderCert,
    NoSessionContextRecord? noSessionContext,
    SessionContextRecord? sessionContext,
    WebSocketConnectRecord? websocketConnect,
    MQTTConnectRecord? mqttConnect,
    STOMPConnectRecord? stompConnect,
    DisconnectRecord? disconnect,
    UDSConnectRecord? udsConnect,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (toId != null) result.toId = toId;
    if (fromId != null) result.fromId = fromId;
    if (payloadSecurity != null) result.payloadSecurity = payloadSecurity;
    if (macSignature != null) result.macSignature = macSignature;
    if (senderCert != null) result.senderCert = senderCert;
    if (noSessionContext != null) result.noSessionContext = noSessionContext;
    if (sessionContext != null) result.sessionContext = sessionContext;
    if (websocketConnect != null) result.websocketConnect = websocketConnect;
    if (mqttConnect != null) result.mqttConnect = mqttConnect;
    if (stompConnect != null) result.stompConnect = stompConnect;
    if (disconnect != null) result.disconnect = disconnect;
    if (udsConnect != null) result.udsConnect = udsConnect;
    return result;
  }

  Record._();

  factory Record.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Record.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Record_RecordType> _Record_RecordTypeByTag =
      {
    7: Record_RecordType.noSessionContext,
    8: Record_RecordType.sessionContext,
    9: Record_RecordType.websocketConnect,
    10: Record_RecordType.mqttConnect,
    11: Record_RecordType.stompConnect,
    12: Record_RecordType.disconnect,
    13: Record_RecordType.udsConnect,
    0: Record_RecordType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Record',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp_record'),
      createEmptyInstance: create)
    ..oo(0, [7, 8, 9, 10, 11, 12, 13])
    ..aOS(1, _omitFieldNames ? '' : 'version')
    ..aOS(2, _omitFieldNames ? '' : 'toId')
    ..aOS(3, _omitFieldNames ? '' : 'fromId')
    ..aE<Record_PayloadSecurity>(4, _omitFieldNames ? '' : 'payloadSecurity',
        enumValues: Record_PayloadSecurity.values)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'macSignature', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'senderCert', $pb.PbFieldType.OY)
    ..aOM<NoSessionContextRecord>(7, _omitFieldNames ? '' : 'noSessionContext',
        subBuilder: NoSessionContextRecord.create)
    ..aOM<SessionContextRecord>(8, _omitFieldNames ? '' : 'sessionContext',
        subBuilder: SessionContextRecord.create)
    ..aOM<WebSocketConnectRecord>(9, _omitFieldNames ? '' : 'websocketConnect',
        subBuilder: WebSocketConnectRecord.create)
    ..aOM<MQTTConnectRecord>(10, _omitFieldNames ? '' : 'mqttConnect',
        subBuilder: MQTTConnectRecord.create)
    ..aOM<STOMPConnectRecord>(11, _omitFieldNames ? '' : 'stompConnect',
        subBuilder: STOMPConnectRecord.create)
    ..aOM<DisconnectRecord>(12, _omitFieldNames ? '' : 'disconnect',
        subBuilder: DisconnectRecord.create)
    ..aOM<UDSConnectRecord>(13, _omitFieldNames ? '' : 'udsConnect',
        subBuilder: UDSConnectRecord.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Record clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Record copyWith(void Function(Record) updates) =>
      super.copyWith((message) => updates(message as Record)) as Record;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Record create() => Record._();
  @$core.override
  Record createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Record getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Record>(create);
  static Record? _defaultInstance;

  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  Record_RecordType whichRecordType() =>
      _Record_RecordTypeByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  void clearRecordType() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get version => $_getSZ(0);
  @$pb.TagNumber(1)
  set version($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get toId => $_getSZ(1);
  @$pb.TagNumber(2)
  set toId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasToId() => $_has(1);
  @$pb.TagNumber(2)
  void clearToId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get fromId => $_getSZ(2);
  @$pb.TagNumber(3)
  set fromId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFromId() => $_has(2);
  @$pb.TagNumber(3)
  void clearFromId() => $_clearField(3);

  @$pb.TagNumber(4)
  Record_PayloadSecurity get payloadSecurity => $_getN(3);
  @$pb.TagNumber(4)
  set payloadSecurity(Record_PayloadSecurity value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasPayloadSecurity() => $_has(3);
  @$pb.TagNumber(4)
  void clearPayloadSecurity() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get macSignature => $_getN(4);
  @$pb.TagNumber(5)
  set macSignature($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMacSignature() => $_has(4);
  @$pb.TagNumber(5)
  void clearMacSignature() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get senderCert => $_getN(5);
  @$pb.TagNumber(6)
  set senderCert($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSenderCert() => $_has(5);
  @$pb.TagNumber(6)
  void clearSenderCert() => $_clearField(6);

  @$pb.TagNumber(7)
  NoSessionContextRecord get noSessionContext => $_getN(6);
  @$pb.TagNumber(7)
  set noSessionContext(NoSessionContextRecord value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasNoSessionContext() => $_has(6);
  @$pb.TagNumber(7)
  void clearNoSessionContext() => $_clearField(7);
  @$pb.TagNumber(7)
  NoSessionContextRecord ensureNoSessionContext() => $_ensure(6);

  @$pb.TagNumber(8)
  SessionContextRecord get sessionContext => $_getN(7);
  @$pb.TagNumber(8)
  set sessionContext(SessionContextRecord value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasSessionContext() => $_has(7);
  @$pb.TagNumber(8)
  void clearSessionContext() => $_clearField(8);
  @$pb.TagNumber(8)
  SessionContextRecord ensureSessionContext() => $_ensure(7);

  @$pb.TagNumber(9)
  WebSocketConnectRecord get websocketConnect => $_getN(8);
  @$pb.TagNumber(9)
  set websocketConnect(WebSocketConnectRecord value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasWebsocketConnect() => $_has(8);
  @$pb.TagNumber(9)
  void clearWebsocketConnect() => $_clearField(9);
  @$pb.TagNumber(9)
  WebSocketConnectRecord ensureWebsocketConnect() => $_ensure(8);

  @$pb.TagNumber(10)
  MQTTConnectRecord get mqttConnect => $_getN(9);
  @$pb.TagNumber(10)
  set mqttConnect(MQTTConnectRecord value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasMqttConnect() => $_has(9);
  @$pb.TagNumber(10)
  void clearMqttConnect() => $_clearField(10);
  @$pb.TagNumber(10)
  MQTTConnectRecord ensureMqttConnect() => $_ensure(9);

  @$pb.TagNumber(11)
  STOMPConnectRecord get stompConnect => $_getN(10);
  @$pb.TagNumber(11)
  set stompConnect(STOMPConnectRecord value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasStompConnect() => $_has(10);
  @$pb.TagNumber(11)
  void clearStompConnect() => $_clearField(11);
  @$pb.TagNumber(11)
  STOMPConnectRecord ensureStompConnect() => $_ensure(10);

  @$pb.TagNumber(12)
  DisconnectRecord get disconnect => $_getN(11);
  @$pb.TagNumber(12)
  set disconnect(DisconnectRecord value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasDisconnect() => $_has(11);
  @$pb.TagNumber(12)
  void clearDisconnect() => $_clearField(12);
  @$pb.TagNumber(12)
  DisconnectRecord ensureDisconnect() => $_ensure(11);

  @$pb.TagNumber(13)
  UDSConnectRecord get udsConnect => $_getN(12);
  @$pb.TagNumber(13)
  set udsConnect(UDSConnectRecord value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasUdsConnect() => $_has(12);
  @$pb.TagNumber(13)
  void clearUdsConnect() => $_clearField(13);
  @$pb.TagNumber(13)
  UDSConnectRecord ensureUdsConnect() => $_ensure(12);
}

class NoSessionContextRecord extends $pb.GeneratedMessage {
  factory NoSessionContextRecord({
    $core.List<$core.int>? payload,
  }) {
    final result = create();
    if (payload != null) result.payload = payload;
    return result;
  }

  NoSessionContextRecord._();

  factory NoSessionContextRecord.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NoSessionContextRecord.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NoSessionContextRecord',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp_record'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NoSessionContextRecord clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NoSessionContextRecord copyWith(
          void Function(NoSessionContextRecord) updates) =>
      super.copyWith((message) => updates(message as NoSessionContextRecord))
          as NoSessionContextRecord;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NoSessionContextRecord create() => NoSessionContextRecord._();
  @$core.override
  NoSessionContextRecord createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NoSessionContextRecord getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NoSessionContextRecord>(create);
  static NoSessionContextRecord? _defaultInstance;

  @$pb.TagNumber(2)
  $core.List<$core.int> get payload => $_getN(0);
  @$pb.TagNumber(2)
  set payload($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(2)
  $core.bool hasPayload() => $_has(0);
  @$pb.TagNumber(2)
  void clearPayload() => $_clearField(2);
}

class SessionContextRecord extends $pb.GeneratedMessage {
  factory SessionContextRecord({
    $fixnum.Int64? sessionId,
    $fixnum.Int64? sequenceId,
    $fixnum.Int64? expectedId,
    $fixnum.Int64? retransmitId,
    SessionContextRecord_PayloadSARState? payloadSarState,
    SessionContextRecord_PayloadSARState? payloadrecSarState,
    $core.Iterable<$core.List<$core.int>>? payload,
  }) {
    final result = create();
    if (sessionId != null) result.sessionId = sessionId;
    if (sequenceId != null) result.sequenceId = sequenceId;
    if (expectedId != null) result.expectedId = expectedId;
    if (retransmitId != null) result.retransmitId = retransmitId;
    if (payloadSarState != null) result.payloadSarState = payloadSarState;
    if (payloadrecSarState != null)
      result.payloadrecSarState = payloadrecSarState;
    if (payload != null) result.payload.addAll(payload);
    return result;
  }

  SessionContextRecord._();

  factory SessionContextRecord.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SessionContextRecord.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionContextRecord',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp_record'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'sessionId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'sequenceId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'expectedId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'retransmitId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aE<SessionContextRecord_PayloadSARState>(
        5, _omitFieldNames ? '' : 'payloadSarState',
        enumValues: SessionContextRecord_PayloadSARState.values)
    ..aE<SessionContextRecord_PayloadSARState>(
        6, _omitFieldNames ? '' : 'payloadrecSarState',
        enumValues: SessionContextRecord_PayloadSARState.values)
    ..p<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.PY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionContextRecord clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionContextRecord copyWith(void Function(SessionContextRecord) updates) =>
      super.copyWith((message) => updates(message as SessionContextRecord))
          as SessionContextRecord;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionContextRecord create() => SessionContextRecord._();
  @$core.override
  SessionContextRecord createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SessionContextRecord getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionContextRecord>(create);
  static SessionContextRecord? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sessionId => $_getI64(0);
  @$pb.TagNumber(1)
  set sessionId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sequenceId => $_getI64(1);
  @$pb.TagNumber(2)
  set sequenceId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSequenceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSequenceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get expectedId => $_getI64(2);
  @$pb.TagNumber(3)
  set expectedId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpectedId() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpectedId() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get retransmitId => $_getI64(3);
  @$pb.TagNumber(4)
  set retransmitId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRetransmitId() => $_has(3);
  @$pb.TagNumber(4)
  void clearRetransmitId() => $_clearField(4);

  @$pb.TagNumber(5)
  SessionContextRecord_PayloadSARState get payloadSarState => $_getN(4);
  @$pb.TagNumber(5)
  set payloadSarState(SessionContextRecord_PayloadSARState value) =>
      $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasPayloadSarState() => $_has(4);
  @$pb.TagNumber(5)
  void clearPayloadSarState() => $_clearField(5);

  @$pb.TagNumber(6)
  SessionContextRecord_PayloadSARState get payloadrecSarState => $_getN(5);
  @$pb.TagNumber(6)
  set payloadrecSarState(SessionContextRecord_PayloadSARState value) =>
      $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasPayloadrecSarState() => $_has(5);
  @$pb.TagNumber(6)
  void clearPayloadrecSarState() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<$core.List<$core.int>> get payload => $_getList(6);
}

class WebSocketConnectRecord extends $pb.GeneratedMessage {
  factory WebSocketConnectRecord() => create();

  WebSocketConnectRecord._();

  factory WebSocketConnectRecord.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebSocketConnectRecord.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebSocketConnectRecord',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp_record'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebSocketConnectRecord clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebSocketConnectRecord copyWith(
          void Function(WebSocketConnectRecord) updates) =>
      super.copyWith((message) => updates(message as WebSocketConnectRecord))
          as WebSocketConnectRecord;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebSocketConnectRecord create() => WebSocketConnectRecord._();
  @$core.override
  WebSocketConnectRecord createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WebSocketConnectRecord getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebSocketConnectRecord>(create);
  static WebSocketConnectRecord? _defaultInstance;
}

class MQTTConnectRecord extends $pb.GeneratedMessage {
  factory MQTTConnectRecord({
    MQTTConnectRecord_MQTTVersion? version,
    $core.String? subscribedTopic,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (subscribedTopic != null) result.subscribedTopic = subscribedTopic;
    return result;
  }

  MQTTConnectRecord._();

  factory MQTTConnectRecord.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MQTTConnectRecord.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MQTTConnectRecord',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp_record'),
      createEmptyInstance: create)
    ..aE<MQTTConnectRecord_MQTTVersion>(1, _omitFieldNames ? '' : 'version',
        enumValues: MQTTConnectRecord_MQTTVersion.values)
    ..aOS(2, _omitFieldNames ? '' : 'subscribedTopic')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MQTTConnectRecord clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MQTTConnectRecord copyWith(void Function(MQTTConnectRecord) updates) =>
      super.copyWith((message) => updates(message as MQTTConnectRecord))
          as MQTTConnectRecord;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MQTTConnectRecord create() => MQTTConnectRecord._();
  @$core.override
  MQTTConnectRecord createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MQTTConnectRecord getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MQTTConnectRecord>(create);
  static MQTTConnectRecord? _defaultInstance;

  @$pb.TagNumber(1)
  MQTTConnectRecord_MQTTVersion get version => $_getN(0);
  @$pb.TagNumber(1)
  set version(MQTTConnectRecord_MQTTVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get subscribedTopic => $_getSZ(1);
  @$pb.TagNumber(2)
  set subscribedTopic($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubscribedTopic() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubscribedTopic() => $_clearField(2);
}

class STOMPConnectRecord extends $pb.GeneratedMessage {
  factory STOMPConnectRecord({
    STOMPConnectRecord_STOMPVersion? version,
    $core.String? subscribedDestination,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (subscribedDestination != null)
      result.subscribedDestination = subscribedDestination;
    return result;
  }

  STOMPConnectRecord._();

  factory STOMPConnectRecord.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory STOMPConnectRecord.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'STOMPConnectRecord',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp_record'),
      createEmptyInstance: create)
    ..aE<STOMPConnectRecord_STOMPVersion>(1, _omitFieldNames ? '' : 'version',
        enumValues: STOMPConnectRecord_STOMPVersion.values)
    ..aOS(2, _omitFieldNames ? '' : 'subscribedDestination')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  STOMPConnectRecord clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  STOMPConnectRecord copyWith(void Function(STOMPConnectRecord) updates) =>
      super.copyWith((message) => updates(message as STOMPConnectRecord))
          as STOMPConnectRecord;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static STOMPConnectRecord create() => STOMPConnectRecord._();
  @$core.override
  STOMPConnectRecord createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static STOMPConnectRecord getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<STOMPConnectRecord>(create);
  static STOMPConnectRecord? _defaultInstance;

  @$pb.TagNumber(1)
  STOMPConnectRecord_STOMPVersion get version => $_getN(0);
  @$pb.TagNumber(1)
  set version(STOMPConnectRecord_STOMPVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get subscribedDestination => $_getSZ(1);
  @$pb.TagNumber(2)
  set subscribedDestination($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSubscribedDestination() => $_has(1);
  @$pb.TagNumber(2)
  void clearSubscribedDestination() => $_clearField(2);
}

class UDSConnectRecord extends $pb.GeneratedMessage {
  factory UDSConnectRecord() => create();

  UDSConnectRecord._();

  factory UDSConnectRecord.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UDSConnectRecord.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UDSConnectRecord',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp_record'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UDSConnectRecord clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UDSConnectRecord copyWith(void Function(UDSConnectRecord) updates) =>
      super.copyWith((message) => updates(message as UDSConnectRecord))
          as UDSConnectRecord;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UDSConnectRecord create() => UDSConnectRecord._();
  @$core.override
  UDSConnectRecord createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UDSConnectRecord getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UDSConnectRecord>(create);
  static UDSConnectRecord? _defaultInstance;
}

class DisconnectRecord extends $pb.GeneratedMessage {
  factory DisconnectRecord({
    $core.String? reason,
    $core.int? reasonCode,
  }) {
    final result = create();
    if (reason != null) result.reason = reason;
    if (reasonCode != null) result.reasonCode = reasonCode;
    return result;
  }

  DisconnectRecord._();

  factory DisconnectRecord.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DisconnectRecord.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DisconnectRecord',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'usp_record'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'reason')
    ..aI(2, _omitFieldNames ? '' : 'reasonCode', fieldType: $pb.PbFieldType.OF3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisconnectRecord clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisconnectRecord copyWith(void Function(DisconnectRecord) updates) =>
      super.copyWith((message) => updates(message as DisconnectRecord))
          as DisconnectRecord;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DisconnectRecord create() => DisconnectRecord._();
  @$core.override
  DisconnectRecord createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DisconnectRecord getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DisconnectRecord>(create);
  static DisconnectRecord? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get reason => $_getSZ(0);
  @$pb.TagNumber(1)
  set reason($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReason() => $_has(0);
  @$pb.TagNumber(1)
  void clearReason() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get reasonCode => $_getIZ(1);
  @$pb.TagNumber(2)
  set reasonCode($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReasonCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearReasonCode() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
