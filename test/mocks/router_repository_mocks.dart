import 'dart:async' as _i13;

import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:privacy_gui/core/jnap/actions/better_action.dart' as _i17;
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart' as _i20;
import 'package:privacy_gui/core/jnap/command/base_command.dart' as _i11;
import 'package:privacy_gui/core/jnap/command/http/base_http_command.dart'
    as _i9;
import 'package:privacy_gui/core/jnap/jnap_command_executor_mixin.dart' as _i7;
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart'
    as _i19;
import 'package:privacy_gui/core/jnap/result/jnap_result.dart' as _i8;
import 'package:privacy_gui/core/jnap/router_repository.dart' as _i18;
import 'package:privacy_gui/core/jnap/spec/jnap_spec.dart' as _i10;

class _FakeRef_6<State extends Object?> extends _i1.SmartFake
    implements _i2.Ref<State> {
  _FakeRef_6(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeJNAPCommandExecutor_7<R> extends _i1.SmartFake
    implements _i7.JNAPCommandExecutor<R> {
  _FakeJNAPCommandExecutor_7(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeJNAPSuccess_8 extends _i1.SmartFake implements _i8.JNAPSuccess {
  _FakeJNAPSuccess_8(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeJNAPTransactionSuccessWrap_9 extends _i1.SmartFake
    implements _i8.JNAPTransactionSuccessWrap {
  _FakeJNAPTransactionSuccessWrap_9(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeTransactionHttpCommand_10 extends _i1.SmartFake
    implements _i9.TransactionHttpCommand {
  _FakeTransactionHttpCommand_10(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeBaseCommand_11<R, S extends _i10.JNAPSpec<dynamic>>
    extends _i1.SmartFake implements _i11.BaseCommand<R, S> {
  _FakeBaseCommand_11(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [RouterRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockRouterRepository extends _i1.Mock implements _i18.RouterRepository {
  @override
  _i2.Ref<Object?> get ref => (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeRef_6<Object?>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub: _FakeRef_6<Object?>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.Ref<Object?>);

  @override
  _i7.JNAPCommandExecutor<dynamic> get executor => (super.noSuchMethod(
        Invocation.getter(#executor),
        returnValue: _FakeJNAPCommandExecutor_7<dynamic>(
          this,
          Invocation.getter(#executor),
        ),
        returnValueForMissingStub: _FakeJNAPCommandExecutor_7<dynamic>(
          this,
          Invocation.getter(#executor),
        ),
      ) as _i7.JNAPCommandExecutor<dynamic>);

  @override
  set enableBTSetup(bool? isEnable) => super.noSuchMethod(
        Invocation.setter(
          #enableBTSetup,
          isEnable,
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool get isEnableBTSetup => (super.noSuchMethod(
        Invocation.getter(#isEnableBTSetup),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  _i13.Future<_i8.JNAPSuccess> send(
    _i17.JNAPAction? action, {
    Map<String, dynamic>? data = const {},
    Map<String, String>? extraHeaders = const {},
    bool? auth = false,
    _i18.CommandType? type,
    bool? fetchRemote = false,
    _i11.CacheLevel? cacheLevel,
    int? timeoutMs = 10000,
    int? retries = 1,
    _i19.JNAPSideEffectOverrides? sideEffectOverrides,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #send,
          [action],
          {
            #data: data,
            #extraHeaders: extraHeaders,
            #auth: auth,
            #type: type,
            #fetchRemote: fetchRemote,
            #cacheLevel: cacheLevel,
            #timeoutMs: timeoutMs,
            #retries: retries,
            #sideEffectOverrides: sideEffectOverrides,
          },
        ),
        returnValue: _i13.Future<_i8.JNAPSuccess>.value(_FakeJNAPSuccess_8(
          this,
          Invocation.method(
            #send,
            [action],
            {
              #data: data,
              #extraHeaders: extraHeaders,
              #auth: auth,
              #type: type,
              #fetchRemote: fetchRemote,
              #cacheLevel: cacheLevel,
              #timeoutMs: timeoutMs,
              #retries: retries,
              #sideEffectOverrides: sideEffectOverrides,
            },
          ),
        )),
        returnValueForMissingStub:
            _i13.Future<_i8.JNAPSuccess>.value(_FakeJNAPSuccess_8(
          this,
          Invocation.method(
            #send,
            [action],
            {
              #data: data,
              #extraHeaders: extraHeaders,
              #auth: auth,
              #type: type,
              #fetchRemote: fetchRemote,
              #cacheLevel: cacheLevel,
              #timeoutMs: timeoutMs,
              #retries: retries,
              #sideEffectOverrides: sideEffectOverrides,
            },
          ),
        )),
      ) as _i13.Future<_i8.JNAPSuccess>);

  @override
  _i13.Future<_i8.JNAPTransactionSuccessWrap> transaction(
    _i20.JNAPTransactionBuilder? builder, {
    bool? fetchRemote = false,
    _i11.CacheLevel? cacheLevel = _i11.CacheLevel.localCached,
    int? timeoutMs = 10000,
    int? retries = 1,
    _i19.JNAPSideEffectOverrides? sideEffectOverrides,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #transaction,
          [builder],
          {
            #fetchRemote: fetchRemote,
            #cacheLevel: cacheLevel,
            #timeoutMs: timeoutMs,
            #retries: retries,
            #sideEffectOverrides: sideEffectOverrides,
          },
        ),
        returnValue: _i13.Future<_i8.JNAPTransactionSuccessWrap>.value(
            _FakeJNAPTransactionSuccessWrap_9(
          this,
          Invocation.method(
            #transaction,
            [builder],
            {
              #fetchRemote: fetchRemote,
              #cacheLevel: cacheLevel,
              #timeoutMs: timeoutMs,
              #retries: retries,
              #sideEffectOverrides: sideEffectOverrides,
            },
          ),
        )),
        returnValueForMissingStub:
            _i13.Future<_i8.JNAPTransactionSuccessWrap>.value(
                _FakeJNAPTransactionSuccessWrap_9(
          this,
          Invocation.method(
            #transaction,
            [builder],
            {
              #fetchRemote: fetchRemote,
              #cacheLevel: cacheLevel,
              #timeoutMs: timeoutMs,
              #retries: retries,
              #sideEffectOverrides: sideEffectOverrides,
            },
          ),
        )),
      ) as _i13.Future<_i8.JNAPTransactionSuccessWrap>);

  @override
  _i13.Future<_i9.TransactionHttpCommand> createTransaction(
    List<Map<String, dynamic>>? payload, {
    bool? needAuth = false,
    required List<_i17.JNAPAction>? actions,
    bool? fetchRemote = false,
    _i11.CacheLevel? cacheLevel = _i11.CacheLevel.localCached,
    int? timeoutMs = 10000,
    int? retries = 1,
    _i18.CommandType? type,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #createTransaction,
          [payload],
          {
            #needAuth: needAuth,
            #actions: actions,
            #fetchRemote: fetchRemote,
            #cacheLevel: cacheLevel,
            #timeoutMs: timeoutMs,
            #retries: retries,
            #type: type,
          },
        ),
        returnValue: _i13.Future<_i9.TransactionHttpCommand>.value(
            _FakeTransactionHttpCommand_10(
          this,
          Invocation.method(
            #createTransaction,
            [payload],
            {
              #needAuth: needAuth,
              #actions: actions,
              #fetchRemote: fetchRemote,
              #cacheLevel: cacheLevel,
              #timeoutMs: timeoutMs,
              #retries: retries,
              #type: type,
            },
          ),
        )),
        returnValueForMissingStub:
            _i13.Future<_i9.TransactionHttpCommand>.value(
                _FakeTransactionHttpCommand_10(
          this,
          Invocation.method(
            #createTransaction,
            [payload],
            {
              #needAuth: needAuth,
              #actions: actions,
              #fetchRemote: fetchRemote,
              #cacheLevel: cacheLevel,
              #timeoutMs: timeoutMs,
              #retries: retries,
              #type: type,
            },
          ),
        )),
      ) as _i13.Future<_i9.TransactionHttpCommand>);

  @override
  _i13.Future<
      _i11.BaseCommand<_i8.JNAPResult,
          _i10.JNAPCommandSpec<dynamic>>> createCommand(
    String? action, {
    Map<String, dynamic>? data = const {},
    Map<String, String>? extraHeaders = const {},
    bool? needAuth = false,
    _i18.CommandType? type,
    bool? fetchRemote = false,
    _i11.CacheLevel? cacheLevel = _i11.CacheLevel.localCached,
    int? timeoutMs = 10000,
    int? retries = 1,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #createCommand,
          [action],
          {
            #data: data,
            #extraHeaders: extraHeaders,
            #needAuth: needAuth,
            #type: type,
            #fetchRemote: fetchRemote,
            #cacheLevel: cacheLevel,
            #timeoutMs: timeoutMs,
            #retries: retries,
          },
        ),
        returnValue: _i13.Future<
                _i11.BaseCommand<_i8.JNAPResult,
                    _i10.JNAPCommandSpec<dynamic>>>.value(
            _FakeBaseCommand_11<_i8.JNAPResult, _i10.JNAPCommandSpec<dynamic>>(
          this,
          Invocation.method(
            #createCommand,
            [action],
            {
              #data: data,
              #extraHeaders: extraHeaders,
              #needAuth: needAuth,
              #type: type,
              #fetchRemote: fetchRemote,
              #cacheLevel: cacheLevel,
              #timeoutMs: timeoutMs,
              #retries: retries,
            },
          ),
        )),
        returnValueForMissingStub: _i13.Future<
                _i11.BaseCommand<_i8.JNAPResult,
                    _i10.JNAPCommandSpec<dynamic>>>.value(
            _FakeBaseCommand_11<_i8.JNAPResult, _i10.JNAPCommandSpec<dynamic>>(
          this,
          Invocation.method(
            #createCommand,
            [action],
            {
              #data: data,
              #extraHeaders: extraHeaders,
              #needAuth: needAuth,
              #type: type,
              #fetchRemote: fetchRemote,
              #cacheLevel: cacheLevel,
              #timeoutMs: timeoutMs,
              #retries: retries,
            },
          ),
        )),
      ) as _i13.Future<
          _i11.BaseCommand<_i8.JNAPResult, _i10.JNAPCommandSpec<dynamic>>>);

  @override
  _i13.Stream<_i8.JNAPResult> scheduledCommand({
    required _i17.JNAPAction? action,
    int? retryDelayInMilliSec = 5000,
    int? maxRetry = 10,
    int? firstDelayInMilliSec = 3000,
    Map<String, dynamic>? data = const {},
    bool Function(_i8.JNAPResult)? condition,
    dynamic Function()? onCompleted,
    bool? auth = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #scheduledCommand,
          [],
          {
            #action: action,
            #retryDelayInMilliSec: retryDelayInMilliSec,
            #maxRetry: maxRetry,
            #firstDelayInMilliSec: firstDelayInMilliSec,
            #data: data,
            #condition: condition,
            #onCompleted: onCompleted,
            #auth: auth,
          },
        ),
        returnValue: _i13.Stream<_i8.JNAPResult>.empty(),
        returnValueForMissingStub: _i13.Stream<_i8.JNAPResult>.empty(),
      ) as _i13.Stream<_i8.JNAPResult>);
}