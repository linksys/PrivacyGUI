// Mocks generated by Mockito 5.4.4 from annotations
// in privacy_gui/test/mocks/mockito_specs/mac_filtering_notifier_spec.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;

import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:privacy_gui/page/wifi_settings/providers/mac_filtering_provider.dart'
    as _i4;
import 'package:privacy_gui/page/wifi_settings/providers/mac_filtering_state.dart'
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

class _FakeMacFilteringState_1 extends _i1.SmartFake
    implements _i3.MacFilteringState {
  _FakeMacFilteringState_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [MacFilteringNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockMacFilteringNotifier extends _i2.Notifier<_i3.MacFilteringState> with _i1.Mock
    implements _i4.MacFilteringNotifier {
  @override
  _i2.NotifierProviderRef<_i3.MacFilteringState> get ref => (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeNotifierProviderRef_0<_i3.MacFilteringState>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub:
            _FakeNotifierProviderRef_0<_i3.MacFilteringState>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.NotifierProviderRef<_i3.MacFilteringState>);

  @override
  _i3.MacFilteringState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeMacFilteringState_1(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakeMacFilteringState_1(
          this,
          Invocation.getter(#state),
        ),
      ) as _i3.MacFilteringState);

  @override
  set state(_i3.MacFilteringState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.MacFilteringState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _FakeMacFilteringState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
        returnValueForMissingStub: _FakeMacFilteringState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
      ) as _i3.MacFilteringState);

  @override
  _i5.Future<_i3.MacFilteringState> fetch() => (super.noSuchMethod(
        Invocation.method(
          #fetch,
          [],
        ),
        returnValue:
            _i5.Future<_i3.MacFilteringState>.value(_FakeMacFilteringState_1(
          this,
          Invocation.method(
            #fetch,
            [],
          ),
        )),
        returnValueForMissingStub:
            _i5.Future<_i3.MacFilteringState>.value(_FakeMacFilteringState_1(
          this,
          Invocation.method(
            #fetch,
            [],
          ),
        )),
      ) as _i5.Future<_i3.MacFilteringState>);

  @override
  _i5.Future<dynamic> save() => (super.noSuchMethod(
        Invocation.method(
          #save,
          [],
        ),
        returnValue: _i5.Future<dynamic>.value(),
        returnValueForMissingStub: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);

  @override
  dynamic setEnable(bool? isEnabled) => super.noSuchMethod(
        Invocation.method(
          #setEnable,
          [isEnabled],
        ),
        returnValueForMissingStub: null,
      );

  @override
  dynamic setAccess(String? value) => super.noSuchMethod(
        Invocation.method(
          #setAccess,
          [value],
        ),
        returnValueForMissingStub: null,
      );

  @override
  dynamic setSelection(List<String>? selections) => super.noSuchMethod(
        Invocation.method(
          #setSelection,
          [selections],
        ),
        returnValueForMissingStub: null,
      );

  @override
  dynamic removeSelection(List<String>? selection) => super.noSuchMethod(
        Invocation.method(
          #removeSelection,
          [selection],
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool updateShouldNotify(
    _i3.MacFilteringState? previous,
    _i3.MacFilteringState? next,
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