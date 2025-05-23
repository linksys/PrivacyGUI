// Mocks generated by Mockito 5.4.4 from annotations
// in privacy_gui/test/page/devices/views/localizations/device_detail_view_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:privacy_gui/page/instant_device/_instant_device.dart' as _i3;

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

class _FakeExternalDeviceDetailState_1 extends _i1.SmartFake
    implements _i3.ExternalDeviceDetailState {
  _FakeExternalDeviceDetailState_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [ExternalDeviceDetailNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockExternalDeviceDetailNotifier extends _i2.Notifier<_i3.ExternalDeviceDetailState> with _i1.Mock
    implements _i3.ExternalDeviceDetailNotifier {
  @override
  _i2.NotifierProviderRef<_i3.ExternalDeviceDetailState> get ref =>
      (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeNotifierProviderRef_0<_i3.ExternalDeviceDetailState>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub:
            _FakeNotifierProviderRef_0<_i3.ExternalDeviceDetailState>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.NotifierProviderRef<_i3.ExternalDeviceDetailState>);

  @override
  _i3.ExternalDeviceDetailState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeExternalDeviceDetailState_1(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakeExternalDeviceDetailState_1(
          this,
          Invocation.getter(#state),
        ),
      ) as _i3.ExternalDeviceDetailState);

  @override
  set state(_i3.ExternalDeviceDetailState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.ExternalDeviceDetailState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _FakeExternalDeviceDetailState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
        returnValueForMissingStub: _FakeExternalDeviceDetailState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
      ) as _i3.ExternalDeviceDetailState);

  @override
  _i3.ExternalDeviceDetailState createState(
    List<_i3.DeviceListItem>? filteredDevices,
    String? targetId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #createState,
          [
            filteredDevices,
            targetId,
          ],
        ),
        returnValue: _FakeExternalDeviceDetailState_1(
          this,
          Invocation.method(
            #createState,
            [
              filteredDevices,
              targetId,
            ],
          ),
        ),
        returnValueForMissingStub: _FakeExternalDeviceDetailState_1(
          this,
          Invocation.method(
            #createState,
            [
              filteredDevices,
              targetId,
            ],
          ),
        ),
      ) as _i3.ExternalDeviceDetailState);

  @override
  bool updateShouldNotify(
    _i3.ExternalDeviceDetailState? previous,
    _i3.ExternalDeviceDetailState? next,
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
