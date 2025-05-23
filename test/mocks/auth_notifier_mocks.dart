// Mocks generated by Mockito 5.4.5 from annotations
// in privacy_gui/test/mocks/mockito_specs/auth_notifier_spec.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart' as _i5;
import 'package:privacy_gui/core/cloud/model/region_code.dart' as _i6;
import 'package:privacy_gui/providers/auth/auth_provider.dart' as _i3;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeAsyncNotifierProviderRef_0<T> extends _i1.SmartFake
    implements _i2.AsyncNotifierProviderRef<T> {
  _FakeAsyncNotifierProviderRef_0(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeAsyncValue_1<T> extends _i1.SmartFake implements _i2.AsyncValue<T> {
  _FakeAsyncValue_1(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeAuthState_2 extends _i1.SmartFake implements _i3.AuthState {
  _FakeAuthState_2(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

/// A class which mocks [AuthNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockAuthNotifier extends _i2.AsyncNotifier<_i3.AuthState> with _i1.Mock implements _i3.AuthNotifier {
  @override
  _i2.AsyncNotifierProviderRef<_i3.AuthState> get ref =>
      (super.noSuchMethod(
            Invocation.getter(#ref),
            returnValue: _FakeAsyncNotifierProviderRef_0<_i3.AuthState>(
              this,
              Invocation.getter(#ref),
            ),
            returnValueForMissingStub:
                _FakeAsyncNotifierProviderRef_0<_i3.AuthState>(
                  this,
                  Invocation.getter(#ref),
                ),
          )
          as _i2.AsyncNotifierProviderRef<_i3.AuthState>);

  @override
  _i2.AsyncValue<_i3.AuthState> get state =>
      (super.noSuchMethod(
            Invocation.getter(#state),
            returnValue: _FakeAsyncValue_1<_i3.AuthState>(
              this,
              Invocation.getter(#state),
            ),
            returnValueForMissingStub: _FakeAsyncValue_1<_i3.AuthState>(
              this,
              Invocation.getter(#state),
            ),
          )
          as _i2.AsyncValue<_i3.AuthState>);

  @override
  set state(_i2.AsyncValue<_i3.AuthState>? newState) => super.noSuchMethod(
    Invocation.setter(#state, newState),
    returnValueForMissingStub: null,
  );

  @override
  _i4.Future<_i3.AuthState> get future =>
      (super.noSuchMethod(
            Invocation.getter(#future),
            returnValue: _i4.Future<_i3.AuthState>.value(
              _FakeAuthState_2(this, Invocation.getter(#future)),
            ),
            returnValueForMissingStub: _i4.Future<_i3.AuthState>.value(
              _FakeAuthState_2(this, Invocation.getter(#future)),
            ),
          )
          as _i4.Future<_i3.AuthState>);

  @override
  _i4.Future<_i3.AuthState> build() =>
      (super.noSuchMethod(
            Invocation.method(#build, []),
            returnValue: _i4.Future<_i3.AuthState>.value(
              _FakeAuthState_2(this, Invocation.method(#build, [])),
            ),
            returnValueForMissingStub: _i4.Future<_i3.AuthState>.value(
              _FakeAuthState_2(this, Invocation.method(#build, [])),
            ),
          )
          as _i4.Future<_i3.AuthState>);

  @override
  _i4.Future<_i3.AuthState?> init() =>
      (super.noSuchMethod(
            Invocation.method(#init, []),
            returnValue: _i4.Future<_i3.AuthState?>.value(),
            returnValueForMissingStub: _i4.Future<_i3.AuthState?>.value(),
          )
          as _i4.Future<_i3.AuthState?>);

  @override
  _i4.Future<_i5.SessionToken?> checkSessionToken() =>
      (super.noSuchMethod(
            Invocation.method(#checkSessionToken, []),
            returnValue: _i4.Future<_i5.SessionToken?>.value(),
            returnValueForMissingStub: _i4.Future<_i5.SessionToken?>.value(),
          )
          as _i4.Future<_i5.SessionToken?>);

  @override
  _i4.Future<_i5.SessionToken?> handleSessionTokenError(
    Object? error,
    StackTrace? trace,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#handleSessionTokenError, [error, trace]),
            returnValue: _i4.Future<_i5.SessionToken?>.value(),
            returnValueForMissingStub: _i4.Future<_i5.SessionToken?>.value(),
          )
          as _i4.Future<_i5.SessionToken?>);

  @override
  _i4.Future<_i5.SessionToken?> refreshToken(String? refreshToken) =>
      (super.noSuchMethod(
            Invocation.method(#refreshToken, [refreshToken]),
            returnValue: _i4.Future<_i5.SessionToken?>.value(),
            returnValueForMissingStub: _i4.Future<_i5.SessionToken?>.value(),
          )
          as _i4.Future<_i5.SessionToken?>);

  @override
  _i4.Future<dynamic> cloudLogin({
    required String? username,
    required String? password,
    _i5.SessionToken? sessionToken,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#cloudLogin, [], {
              #username: username,
              #password: password,
              #sessionToken: sessionToken,
            }),
            returnValue: _i4.Future<dynamic>.value(),
            returnValueForMissingStub: _i4.Future<dynamic>.value(),
          )
          as _i4.Future<dynamic>);

  @override
  _i4.Future<_i3.AuthState> updateCloudCredientials({
    _i5.SessionToken? sessionToken,
    String? username,
    String? password,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#updateCloudCredientials, [], {
              #sessionToken: sessionToken,
              #username: username,
              #password: password,
            }),
            returnValue: _i4.Future<_i3.AuthState>.value(
              _FakeAuthState_2(
                this,
                Invocation.method(#updateCloudCredientials, [], {
                  #sessionToken: sessionToken,
                  #username: username,
                  #password: password,
                }),
              ),
            ),
            returnValueForMissingStub: _i4.Future<_i3.AuthState>.value(
              _FakeAuthState_2(
                this,
                Invocation.method(#updateCloudCredientials, [], {
                  #sessionToken: sessionToken,
                  #username: username,
                  #password: password,
                }),
              ),
            ),
          )
          as _i4.Future<_i3.AuthState>);

  @override
  _i4.Future<dynamic> localLogin(
    String? password, {
    bool? pnp = false,
    bool? guardError = true,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #localLogin,
              [password],
              {#pnp: pnp, #guardError: guardError},
            ),
            returnValue: _i4.Future<dynamic>.value(),
            returnValueForMissingStub: _i4.Future<dynamic>.value(),
          )
          as _i4.Future<dynamic>);

  @override
  _i4.Future<void> getPasswordHint() =>
      (super.noSuchMethod(
            Invocation.method(#getPasswordHint, []),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);

  @override
  _i4.Future<Map<String, dynamic>?> getAdminPasswordAuthStatus(
    List<String>? services,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#getAdminPasswordAuthStatus, [services]),
            returnValue: _i4.Future<Map<String, dynamic>?>.value(),
            returnValueForMissingStub:
                _i4.Future<Map<String, dynamic>?>.value(),
          )
          as _i4.Future<Map<String, dynamic>?>);

  @override
  _i4.Future<void> getDeviceInfo() =>
      (super.noSuchMethod(
            Invocation.method(#getDeviceInfo, []),
            returnValue: _i4.Future<void>.value(),
            returnValueForMissingStub: _i4.Future<void>.value(),
          )
          as _i4.Future<void>);

  @override
  _i4.Future<dynamic> logout() =>
      (super.noSuchMethod(
            Invocation.method(#logout, []),
            returnValue: _i4.Future<dynamic>.value(),
            returnValueForMissingStub: _i4.Future<dynamic>.value(),
          )
          as _i4.Future<dynamic>);

  @override
  bool isCloudLogin() =>
      (super.noSuchMethod(
            Invocation.method(#isCloudLogin, []),
            returnValue: false,
            returnValueForMissingStub: false,
          )
          as bool);

  @override
  _i4.Future<List<_i6.RegionCode>> fetchRegionCodes() =>
      (super.noSuchMethod(
            Invocation.method(#fetchRegionCodes, []),
            returnValue: _i4.Future<List<_i6.RegionCode>>.value(
              <_i6.RegionCode>[],
            ),
            returnValueForMissingStub: _i4.Future<List<_i6.RegionCode>>.value(
              <_i6.RegionCode>[],
            ),
          )
          as _i4.Future<List<_i6.RegionCode>>);

  @override
  _i4.Future<dynamic> raLogin(
    String? sessionToken,
    String? networkId,
    String? serialNumber,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#raLogin, [
              sessionToken,
              networkId,
              serialNumber,
            ]),
            returnValue: _i4.Future<dynamic>.value(),
            returnValueForMissingStub: _i4.Future<dynamic>.value(),
          )
          as _i4.Future<dynamic>);

  @override
  void listenSelf(
    void Function(
      _i2.AsyncValue<_i3.AuthState>?,
      _i2.AsyncValue<_i3.AuthState>,
    )?
    listener, {
    void Function(Object, StackTrace)? onError,
  }) => super.noSuchMethod(
    Invocation.method(#listenSelf, [listener], {#onError: onError}),
    returnValueForMissingStub: null,
  );

  @override
  _i4.Future<_i3.AuthState> update(
    _i4.FutureOr<_i3.AuthState> Function(_i3.AuthState)? cb, {
    _i4.FutureOr<_i3.AuthState> Function(Object, StackTrace)? onError,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#update, [cb], {#onError: onError}),
            returnValue: _i4.Future<_i3.AuthState>.value(
              _FakeAuthState_2(
                this,
                Invocation.method(#update, [cb], {#onError: onError}),
              ),
            ),
            returnValueForMissingStub: _i4.Future<_i3.AuthState>.value(
              _FakeAuthState_2(
                this,
                Invocation.method(#update, [cb], {#onError: onError}),
              ),
            ),
          )
          as _i4.Future<_i3.AuthState>);

  @override
  bool updateShouldNotify(
    _i2.AsyncValue<_i3.AuthState>? previous,
    _i2.AsyncValue<_i3.AuthState>? next,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#updateShouldNotify, [previous, next]),
            returnValue: false,
            returnValueForMissingStub: false,
          )
          as bool);
}
