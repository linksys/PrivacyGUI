// Mocks generated by Mockito 5.4.4 from annotations
// in linksys_app/test/page/topology/views/topology_view_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:linksys_app/page/topology/_topology.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;

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

class _FakeTopologyState_1 extends _i1.SmartFake implements _i3.TopologyState {
  _FakeTopologyState_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [TopologyNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockTopologyNotifier extends _i2.Notifier<_i3.TopologyState> with _i1.Mock implements _i3.TopologyNotifier {
  @override
  _i2.NotifierProviderRef<_i3.TopologyState> get ref => (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeNotifierProviderRef_0<_i3.TopologyState>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub:
            _FakeNotifierProviderRef_0<_i3.TopologyState>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.NotifierProviderRef<_i3.TopologyState>);

  @override
  _i3.TopologyState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeTopologyState_1(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakeTopologyState_1(
          this,
          Invocation.getter(#state),
        ),
      ) as _i3.TopologyState);

  @override
  set state(_i3.TopologyState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.TopologyState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _FakeTopologyState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
        returnValueForMissingStub: _FakeTopologyState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
      ) as _i3.TopologyState);

  @override
  _i4.Future<dynamic> reboot() => (super.noSuchMethod(
        Invocation.method(
          #reboot,
          [],
        ),
        returnValue: _i4.Future<dynamic>.value(),
        returnValueForMissingStub: _i4.Future<dynamic>.value(),
      ) as _i4.Future<dynamic>);

  @override
  bool isSupportAutoOnboarding() => (super.noSuchMethod(
        Invocation.method(
          #isSupportAutoOnboarding,
          [],
        ),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  bool updateShouldNotify(
    _i3.TopologyState? previous,
    _i3.TopologyState? next,
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