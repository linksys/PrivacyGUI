// Mocks generated by Mockito 5.4.4 from annotations
// in privacy_gui/test/mocks/mockito_specs/instant_topology_notifier_spec.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart'
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

class _FakeInstantTopologyState_1 extends _i1.SmartFake
    implements _i3.InstantTopologyState {
  _FakeInstantTopologyState_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [InstantTopologyNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockInstantTopologyNotifier extends _i2.Notifier<_i3.InstantTopologyState> with _i1.Mock
    implements _i3.InstantTopologyNotifier {
  @override
  _i2.NotifierProviderRef<_i3.InstantTopologyState> get ref =>
      (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeNotifierProviderRef_0<_i3.InstantTopologyState>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub:
            _FakeNotifierProviderRef_0<_i3.InstantTopologyState>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.NotifierProviderRef<_i3.InstantTopologyState>);

  @override
  _i3.InstantTopologyState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeInstantTopologyState_1(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakeInstantTopologyState_1(
          this,
          Invocation.getter(#state),
        ),
      ) as _i3.InstantTopologyState);

  @override
  set state(_i3.InstantTopologyState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.InstantTopologyState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _FakeInstantTopologyState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
        returnValueForMissingStub: _FakeInstantTopologyState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
      ) as _i3.InstantTopologyState);

  @override
  _i4.Future<dynamic> reboot([List<String>? deviceUUIDs = const []]) =>
      (super.noSuchMethod(
        Invocation.method(
          #reboot,
          [deviceUUIDs],
        ),
        returnValue: _i4.Future<dynamic>.value(),
        returnValueForMissingStub: _i4.Future<dynamic>.value(),
      ) as _i4.Future<dynamic>);

  @override
  _i4.Future<dynamic> startBlinkNodeLED(String? deviceId) =>
      (super.noSuchMethod(
        Invocation.method(
          #startBlinkNodeLED,
          [deviceId],
        ),
        returnValue: _i4.Future<dynamic>.value(),
        returnValueForMissingStub: _i4.Future<dynamic>.value(),
      ) as _i4.Future<dynamic>);

  @override
  _i4.Future<dynamic> stopBlinkNodeLED() => (super.noSuchMethod(
        Invocation.method(
          #stopBlinkNodeLED,
          [],
        ),
        returnValue: _i4.Future<dynamic>.value(),
        returnValueForMissingStub: _i4.Future<dynamic>.value(),
      ) as _i4.Future<dynamic>);

  @override
  _i4.Future<void> toggleBlinkNode(
    String? deviceId, [
    bool? stopOnly = false,
  ]) =>
      (super.noSuchMethod(
        Invocation.method(
          #toggleBlinkNode,
          [
            deviceId,
            stopOnly,
          ],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<dynamic> factoryReset([List<String>? deviceUUIDs = const []]) =>
      (super.noSuchMethod(
        Invocation.method(
          #factoryReset,
          [deviceUUIDs],
        ),
        returnValue: _i4.Future<dynamic>.value(),
        returnValueForMissingStub: _i4.Future<dynamic>.value(),
      ) as _i4.Future<dynamic>);

  @override
  bool updateShouldNotify(
    _i3.InstantTopologyState? previous,
    _i3.InstantTopologyState? next,
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
