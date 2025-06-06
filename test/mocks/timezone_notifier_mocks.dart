// Mocks generated by Mockito 5.4.4 from annotations
// in privacy_gui/test/page/network_admin/views/localizations/network_admin_view_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i6;

import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:privacy_gui/page/instant_admin/providers/timezone_provider.dart'
    as _i7;
import 'package:privacy_gui/page/instant_admin/providers/timezone_state.dart'
    as _i4;

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

class _FakeTimezoneState_2 extends _i1.SmartFake implements _i4.TimezoneState {
  _FakeTimezoneState_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [TimezoneNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockTimezoneNotifier extends _i2.Notifier<_i4.TimezoneState>
    with _i1.Mock
    implements _i7.TimezoneNotifier {
  @override
  _i2.NotifierProviderRef<_i4.TimezoneState> get ref => (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeNotifierProviderRef_0<_i4.TimezoneState>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub:
            _FakeNotifierProviderRef_0<_i4.TimezoneState>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.NotifierProviderRef<_i4.TimezoneState>);

  @override
  _i4.TimezoneState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeTimezoneState_2(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakeTimezoneState_2(
          this,
          Invocation.getter(#state),
        ),
      ) as _i4.TimezoneState);

  @override
  set state(_i4.TimezoneState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i4.TimezoneState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _FakeTimezoneState_2(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
        returnValueForMissingStub: _FakeTimezoneState_2(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
      ) as _i4.TimezoneState);

  @override
  _i6.Future<dynamic> fetch({bool? fetchRemote = false}) => (super.noSuchMethod(
        Invocation.method(
          #fetch,
          [],
          {#fetchRemote: fetchRemote},
        ),
        returnValue: _i6.Future<dynamic>.value(),
        returnValueForMissingStub: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);

  @override
  _i6.Future<dynamic> save() => (super.noSuchMethod(
        Invocation.method(
          #save,
          [],
        ),
        returnValue: _i6.Future<dynamic>.value(),
        returnValueForMissingStub: _i6.Future<dynamic>.value(),
      ) as _i6.Future<dynamic>);

  @override
  bool isSelectedTimezone(int? index) => (super.noSuchMethod(
        Invocation.method(
          #isSelectedTimezone,
          [index],
        ),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  bool isSupportDaylightSaving() => (super.noSuchMethod(
        Invocation.method(
          #isSupportDaylightSaving,
          [],
        ),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  dynamic setSelectedTimezone(int? index) => super.noSuchMethod(
        Invocation.method(
          #setSelectedTimezone,
          [index],
        ),
        returnValueForMissingStub: null,
      );

  @override
  dynamic setDaylightSaving(bool? isDaylightSaving) => super.noSuchMethod(
        Invocation.method(
          #setDaylightSaving,
          [isDaylightSaving],
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool updateShouldNotify(
    _i4.TimezoneState? previous,
    _i4.TimezoneState? next,
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
