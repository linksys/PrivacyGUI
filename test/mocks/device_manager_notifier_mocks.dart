// Mocks generated by Mockito 5.4.4 from annotations
// in privacy_gui/test/mocks/mockito_specs/device_manager_notifier_spec.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i8;

import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i7;
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart' as _i4;
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart'
    as _i5;
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart'
    as _i3;
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart' as _i6;
import 'package:privacy_gui/core/utils/icon_device_category.dart' as _i9;

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

class _FakeDeviceManagerState_1 extends _i1.SmartFake
    implements _i3.DeviceManagerState {
  _FakeDeviceManagerState_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeNodeLightSettings_2 extends _i1.SmartFake
    implements _i4.NodeLightSettings {
  _FakeNodeLightSettings_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [DeviceManagerNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockDeviceManagerNotifier extends _i2.Notifier<_i3.DeviceManagerState>
    with _i1.Mock
    implements _i5.DeviceManagerNotifier {
  @override
  _i2.NotifierProviderRef<_i3.DeviceManagerState> get ref =>
      (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeNotifierProviderRef_0<_i3.DeviceManagerState>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub:
            _FakeNotifierProviderRef_0<_i3.DeviceManagerState>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.NotifierProviderRef<_i3.DeviceManagerState>);

  @override
  _i3.DeviceManagerState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeDeviceManagerState_1(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakeDeviceManagerState_1(
          this,
          Invocation.getter(#state),
        ),
      ) as _i3.DeviceManagerState);

  @override
  set state(_i3.DeviceManagerState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.DeviceManagerState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _FakeDeviceManagerState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
        returnValueForMissingStub: _FakeDeviceManagerState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
      ) as _i3.DeviceManagerState);

  @override
  _i3.DeviceManagerState createState(
          {_i6.CoreTransactionData? pollingResult}) =>
      (super.noSuchMethod(
        Invocation.method(
          #createState,
          [],
          {#pollingResult: pollingResult},
        ),
        returnValue: _FakeDeviceManagerState_1(
          this,
          Invocation.method(
            #createState,
            [],
            {#pollingResult: pollingResult},
          ),
        ),
        returnValueForMissingStub: _FakeDeviceManagerState_1(
          this,
          Invocation.method(
            #createState,
            [],
            {#pollingResult: pollingResult},
          ),
        ),
      ) as _i3.DeviceManagerState);

  @override
  bool isEmptyState() => (super.noSuchMethod(
        Invocation.method(
          #isEmptyState,
          [],
        ),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  String? getSsidConnectedBy(_i3.LinksysDevice? device) => (super.noSuchMethod(
        Invocation.method(
          #getSsidConnectedBy,
          [device],
        ),
        returnValueForMissingStub: null,
      ) as String?);

  @override
  String getBandConnectedBy(_i3.LinksysDevice? device) => (super.noSuchMethod(
        Invocation.method(
          #getBandConnectedBy,
          [device],
        ),
        returnValue: _i7.dummyValue<String>(
          this,
          Invocation.method(
            #getBandConnectedBy,
            [device],
          ),
        ),
        returnValueForMissingStub: _i7.dummyValue<String>(
          this,
          Invocation.method(
            #getBandConnectedBy,
            [device],
          ),
        ),
      ) as String);

  @override
  _i3.LinksysDevice? findParent(
    String? deviceID, [
    _i3.DeviceManagerState? current,
  ]) =>
      (super.noSuchMethod(
        Invocation.method(
          #findParent,
          [
            deviceID,
            current,
          ],
        ),
        returnValueForMissingStub: null,
      ) as _i3.LinksysDevice?);

  @override
  _i8.Future<void> updateDeviceNameAndIcon({
    required String? targetId,
    required String? newName,
    required bool? isLocation,
    _i9.IconDeviceCategory? icon,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateDeviceNameAndIcon,
          [],
          {
            #targetId: targetId,
            #newName: newName,
            #isLocation: isLocation,
            #icon: icon,
          },
        ),
        returnValue: _i8.Future<void>.value(),
        returnValueForMissingStub: _i8.Future<void>.value(),
      ) as _i8.Future<void>);

  @override
  _i8.Future<_i4.NodeLightSettings> getLEDLight() => (super.noSuchMethod(
        Invocation.method(
          #getLEDLight,
          [],
        ),
        returnValue:
            _i8.Future<_i4.NodeLightSettings>.value(_FakeNodeLightSettings_2(
          this,
          Invocation.method(
            #getLEDLight,
            [],
          ),
        )),
        returnValueForMissingStub:
            _i8.Future<_i4.NodeLightSettings>.value(_FakeNodeLightSettings_2(
          this,
          Invocation.method(
            #getLEDLight,
            [],
          ),
        )),
      ) as _i8.Future<_i4.NodeLightSettings>);

  @override
  _i8.Future<void> setLEDLight(_i4.NodeLightSettings? settings) =>
      (super.noSuchMethod(
        Invocation.method(
          #setLEDLight,
          [settings],
        ),
        returnValue: _i8.Future<void>.value(),
        returnValueForMissingStub: _i8.Future<void>.value(),
      ) as _i8.Future<void>);

  @override
  _i8.Future<void> deleteDevices({required List<String>? deviceIds}) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteDevices,
          [],
          {#deviceIds: deviceIds},
        ),
        returnValue: _i8.Future<void>.value(),
        returnValueForMissingStub: _i8.Future<void>.value(),
      ) as _i8.Future<void>);

  @override
  _i8.Future<void> deauthClient({required String? macAddress}) =>
      (super.noSuchMethod(
        Invocation.method(
          #deauthClient,
          [],
          {#macAddress: macAddress},
        ),
        returnValue: _i8.Future<void>.value(),
        returnValueForMissingStub: _i8.Future<void>.value(),
      ) as _i8.Future<void>);

  @override
  bool updateShouldNotify(
    _i3.DeviceManagerState? previous,
    _i3.DeviceManagerState? next,
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
