// Mocks generated by Mockito 5.4.4 from annotations
// in privacy_gui/test/page/advanced_settings/static_routing/static_routing_view_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;

import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart' as _i6;
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart'
    as _i4;
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart'
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

class _FakeStaticRoutingState_1 extends _i1.SmartFake
    implements _i3.StaticRoutingState {
  _FakeStaticRoutingState_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [StaticRoutingNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockStaticRoutingNotifier extends _i2.Notifier<_i3.StaticRoutingState>
    with _i1.Mock
    implements _i4.StaticRoutingNotifier {
  @override
  _i2.NotifierProviderRef<_i3.StaticRoutingState> get ref =>
      (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeNotifierProviderRef_0<_i3.StaticRoutingState>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub:
            _FakeNotifierProviderRef_0<_i3.StaticRoutingState>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.NotifierProviderRef<_i3.StaticRoutingState>);

  @override
  _i3.StaticRoutingState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeStaticRoutingState_1(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakeStaticRoutingState_1(
          this,
          Invocation.getter(#state),
        ),
      ) as _i3.StaticRoutingState);

  @override
  set state(_i3.StaticRoutingState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.StaticRoutingState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _FakeStaticRoutingState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
        returnValueForMissingStub: _FakeStaticRoutingState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
      ) as _i3.StaticRoutingState);

  @override
  _i5.Future<void> fetchSettings() => (super.noSuchMethod(
        Invocation.method(
          #fetchSettings,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> saveRoutingSettingNetork(
          _i3.RoutingSettingNetwork? option) =>
      (super.noSuchMethod(
        Invocation.method(
          #saveRoutingSettingNetork,
          [option],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> saveRoutingSettingList(
          List<_i6.NamedStaticRouteEntry>? entries) =>
      (super.noSuchMethod(
        Invocation.method(
          #saveRoutingSettingList,
          [entries],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  bool updateShouldNotify(
    _i3.StaticRoutingState? previous,
    _i3.StaticRoutingState? next,
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