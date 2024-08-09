import 'dart:async' as _i10;

import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i15;
import 'package:privacy_gui/core/jnap/models/device.dart' as _i14;
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart' as _i6;
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart'
    as _i12;
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart'
    as _i5;
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart' as _i13;
import 'package:privacy_gui/core/utils/icon_device_category.dart' as _i16;

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

class _FakeDeviceManagerState_3 extends _i1.SmartFake
    implements _i5.DeviceManagerState {
  _FakeDeviceManagerState_3(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeLinksysDevice_4 extends _i1.SmartFake implements _i5.LinksysDevice {
  _FakeLinksysDevice_4(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeNodeLightSettings_5 extends _i1.SmartFake
    implements _i6.NodeLightSettings {
  _FakeNodeLightSettings_5(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

// A class which mocks [DeviceManagerNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockDeviceManagerNotifier extends _i2.Notifier<_i5.DeviceManagerState>
    with _i1.Mock
    implements _i12.DeviceManagerNotifier {
  @override
  _i2.NotifierProviderRef<_i5.DeviceManagerState> get ref =>
      (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeNotifierProviderRef_0<_i5.DeviceManagerState>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub:
            _FakeNotifierProviderRef_0<_i5.DeviceManagerState>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.NotifierProviderRef<_i5.DeviceManagerState>);

  @override
  _i5.DeviceManagerState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeDeviceManagerState_3(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakeDeviceManagerState_3(
          this,
          Invocation.getter(#state),
        ),
      ) as _i5.DeviceManagerState);

  @override
  set state(_i5.DeviceManagerState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i5.DeviceManagerState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _FakeDeviceManagerState_3(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
        returnValueForMissingStub: _FakeDeviceManagerState_3(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
      ) as _i5.DeviceManagerState);

  @override
  _i5.DeviceManagerState createState(
          {_i13.CoreTransactionData? pollingResult}) =>
      (super.noSuchMethod(
        Invocation.method(
          #createState,
          [],
          {#pollingResult: pollingResult},
        ),
        returnValue: _FakeDeviceManagerState_3(
          this,
          Invocation.method(
            #createState,
            [],
            {#pollingResult: pollingResult},
          ),
        ),
        returnValueForMissingStub: _FakeDeviceManagerState_3(
          this,
          Invocation.method(
            #createState,
            [],
            {#pollingResult: pollingResult},
          ),
        ),
      ) as _i5.DeviceManagerState);

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
  String? getSsidConnectedBy(_i14.RawDevice? device) => (super.noSuchMethod(
        Invocation.method(
          #getSsidConnectedBy,
          [device],
        ),
        returnValueForMissingStub: null,
      ) as String?);

  @override
  int _getWirelessSignalOf(
    _i14.RawDevice? device, [
    _i5.DeviceManagerState? currentState,
  ]) =>
      (super.noSuchMethod(
        Invocation.method(
          #getWirelessSignalOf,
          [
            device,
            currentState,
          ],
        ),
        returnValue: 0,
        returnValueForMissingStub: 0,
      ) as int);

  @override
  String getBandConnectedBy(_i14.RawDevice? device) => (super.noSuchMethod(
        Invocation.method(
          #getBandConnectedBy,
          [device],
        ),
        returnValue: _i15.dummyValue<String>(
          this,
          Invocation.method(
            #getBandConnectedBy,
            [device],
          ),
        ),
        returnValueForMissingStub: _i15.dummyValue<String>(
          this,
          Invocation.method(
            #getBandConnectedBy,
            [device],
          ),
        ),
      ) as String);

  @override
  _i5.LinksysDevice findParent(
    String? deviceID, [
    _i5.DeviceManagerState? current,
  ]) =>
      (super.noSuchMethod(
        Invocation.method(
          #findParent,
          [
            deviceID,
            current,
          ],
        ),
        returnValue: _FakeLinksysDevice_4(
          this,
          Invocation.method(
            #findParent,
            [
              deviceID,
              current,
            ],
          ),
        ),
        returnValueForMissingStub: _FakeLinksysDevice_4(
          this,
          Invocation.method(
            #findParent,
            [
              deviceID,
              current,
            ],
          ),
        ),
      ) as _i5.LinksysDevice);

  @override
  _i10.Future<void> updateDeviceNameAndIcon({
    required String? targetId,
    required String? newName,
    required bool? isLocation,
    _i16.IconDeviceCategory? icon,
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
        returnValue: _i10.Future<void>.value(),
        returnValueForMissingStub: _i10.Future<void>.value(),
      ) as _i10.Future<void>);

  @override
  _i10.Future<_i6.NodeLightSettings> getLEDLight() => (super.noSuchMethod(
        Invocation.method(
          #getLEDLight,
          [],
        ),
        returnValue:
            _i10.Future<_i6.NodeLightSettings>.value(_FakeNodeLightSettings_5(
          this,
          Invocation.method(
            #getLEDLight,
            [],
          ),
        )),
        returnValueForMissingStub:
            _i10.Future<_i6.NodeLightSettings>.value(_FakeNodeLightSettings_5(
          this,
          Invocation.method(
            #getLEDLight,
            [],
          ),
        )),
      ) as _i10.Future<_i6.NodeLightSettings>);

  @override
  _i10.Future<void> setLEDLight(_i6.NodeLightSettings? settings) =>
      (super.noSuchMethod(
        Invocation.method(
          #setLEDLight,
          [settings],
        ),
        returnValue: _i10.Future<void>.value(),
        returnValueForMissingStub: _i10.Future<void>.value(),
      ) as _i10.Future<void>);

  @override
  _i10.Future<void> deleteDevices({required List<String>? deviceIds}) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteDevices,
          [],
          {#deviceIds: deviceIds},
        ),
        returnValue: _i10.Future<void>.value(),
        returnValueForMissingStub: _i10.Future<void>.value(),
      ) as _i10.Future<void>);

  @override
  bool updateShouldNotify(
    _i5.DeviceManagerState? previous,
    _i5.DeviceManagerState? next,
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