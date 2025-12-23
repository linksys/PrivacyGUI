import 'dart:async' as _i6;

import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:privacy_gui/page/instant_admin/providers/_providers.dart';
import 'package:privacy_gui/page/instant_admin/providers/router_password_provider.dart'
    as _i5;
import 'package:privacy_gui/page/instant_admin/providers/router_password_state.dart'
    as _i3;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeNotifierProviderRef_0<T> extends _i1.SmartFake
    implements _i2.NotifierProviderRef<T> {
  _FakeNotifierProviderRef_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeRouterPasswordState_1 extends _i1.SmartFake
    implements _i3.RouterPasswordState {
  _FakeRouterPasswordState_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [RouterPasswordNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockRouterPasswordNotifier extends _i2.Notifier<_i3.RouterPasswordState>
    with _i1.Mock
    implements _i5.RouterPasswordNotifier {
  @override
  _i2.NotifierProviderRef<_i3.RouterPasswordState> get ref =>
      (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeNotifierProviderRef_0<_i3.RouterPasswordState>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub:
            _FakeNotifierProviderRef_0<_i3.RouterPasswordState>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.NotifierProviderRef<_i3.RouterPasswordState>);

  @override
  _i3.RouterPasswordState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeRouterPasswordState_1(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakeRouterPasswordState_1(
          this,
          Invocation.getter(#state),
        ),
      ) as _i3.RouterPasswordState);

  @override
  set state(_i3.RouterPasswordState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.RouterPasswordState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _FakeRouterPasswordState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
        returnValueForMissingStub: _FakeRouterPasswordState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
      ) as _i3.RouterPasswordState);

  @override
  _i6.Future<dynamic> fetch([bool? force = false]) => (super.noSuchMethod(
        Invocation.method(
          #fetch,
          [force],
        ),
        returnValue: _i6.Future<dynamic>.value(),
        returnValueForMissingStub: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);

  @override
  _i6.Future<void> setAdminPasswordWithResetCode(
    String? password,
    String? hint,
    String? code,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #setAdminPasswordWithResetCode,
          [
            password,
            hint,
            code,
          ],
        ),
        returnValue: _i6.Future<void>.value(),
        returnValueForMissingStub: _i6.Future<void>.value(),
      ) as _i6.Future<void>);

  @override
  _i6.Future<dynamic> setAdminPasswordWithCredentials(
    String? password, [
    String? hint,
  ]) =>
      (super.noSuchMethod(
        Invocation.method(
          #setAdminPasswordWithCredentials,
          [
            password,
            hint,
          ],
        ),
        returnValue: _i6.Future<dynamic>.value(),
        returnValueForMissingStub: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);

  @override
  _i6.Future<bool> checkRecoveryCode(String? code) => (super.noSuchMethod(
        Invocation.method(
          #checkRecoveryCode,
          [code],
        ),
        returnValue: _i6.Future<bool>.value(false),
        returnValueForMissingStub: _i6.Future<bool>.value(false),
      ) as _i6.Future<bool>);

  @override
  dynamic setEdited(bool? hasEdited) => super.noSuchMethod(
        Invocation.method(
          #setEdited,
          [hasEdited],
        ),
        returnValueForMissingStub: null,
      );

  @override
  dynamic setValidate(bool? isValid) => super.noSuchMethod(
        Invocation.method(
          #setValidate,
          [isValid],
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool updateShouldNotify(
    _i3.RouterPasswordState? previous,
    _i3.RouterPasswordState? next,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateShouldNotify,
          [
            previous,
            next,
          ],
        ),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);
}
