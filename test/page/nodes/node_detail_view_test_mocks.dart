// Mocks generated by Mockito 5.4.4 from annotations
// in linksys_app/test/page/nodes/views/node_detail_view_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i7;

import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:linksys_app/core/jnap/models/firmware_update_status.dart'
    as _i10;
import 'package:linksys_app/core/jnap/models/node_light_settings.dart' as _i8;
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart'
    as _i6;
import 'package:linksys_app/core/jnap/providers/firmware_update_provider.dart'
    as _i9;
import 'package:linksys_app/core/jnap/providers/firmware_update_state.dart'
    as _i5;
import 'package:linksys_app/core/jnap/result/jnap_result.dart' as _i4;
import 'package:linksys_app/page/nodes/_nodes.dart' as _i3;
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

class _FakeNodeDetailState_1 extends _i1.SmartFake
    implements _i3.NodeDetailState {
  _FakeNodeDetailState_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeJNAPResult_2 extends _i1.SmartFake implements _i4.JNAPResult {
  _FakeJNAPResult_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeFirmwareUpdateState_3 extends _i1.SmartFake
    implements _i5.FirmwareUpdateState {
  _FakeFirmwareUpdateState_3(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [NodeDetailNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockNodeDetailNotifier extends _i2.Notifier<_i3.NodeDetailState> with _i1.Mock
    implements _i3.NodeDetailNotifier {
  @override
  _i2.NotifierProviderRef<_i3.NodeDetailState> get ref => (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeNotifierProviderRef_0<_i3.NodeDetailState>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub:
            _FakeNotifierProviderRef_0<_i3.NodeDetailState>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.NotifierProviderRef<_i3.NodeDetailState>);

  @override
  _i3.NodeDetailState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeNodeDetailState_1(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakeNodeDetailState_1(
          this,
          Invocation.getter(#state),
        ),
      ) as _i3.NodeDetailState);

  @override
  set state(_i3.NodeDetailState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.NodeDetailState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _FakeNodeDetailState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
        returnValueForMissingStub: _FakeNodeDetailState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
      ) as _i3.NodeDetailState);

  @override
  _i3.NodeDetailState createState(
    _i6.DeviceManagerState? deviceManagerState,
    String? targetId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #createState,
          [
            deviceManagerState,
            targetId,
          ],
        ),
        returnValue: _FakeNodeDetailState_1(
          this,
          Invocation.method(
            #createState,
            [
              deviceManagerState,
              targetId,
            ],
          ),
        ),
        returnValueForMissingStub: _FakeNodeDetailState_1(
          this,
          Invocation.method(
            #createState,
            [
              deviceManagerState,
              targetId,
            ],
          ),
        ),
      ) as _i3.NodeDetailState);

  @override
  bool isSupportLedBlinking() => (super.noSuchMethod(
        Invocation.method(
          #isSupportLedBlinking,
          [],
        ),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  bool isSupportLedMode() => (super.noSuchMethod(
        Invocation.method(
          #isSupportLedMode,
          [],
        ),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  _i7.Future<void> getLEDLight() => (super.noSuchMethod(
        Invocation.method(
          #getLEDLight,
          [],
        ),
        returnValue: _i7.Future<void>.value(),
        returnValueForMissingStub: _i7.Future<void>.value(),
      ) as _i7.Future<void>);

  @override
  _i7.Future<void> setLEDLight(_i8.NodeLightSettings? settings) =>
      (super.noSuchMethod(
        Invocation.method(
          #setLEDLight,
          [settings],
        ),
        returnValue: _i7.Future<void>.value(),
        returnValueForMissingStub: _i7.Future<void>.value(),
      ) as _i7.Future<void>);

  @override
  _i7.Future<_i4.JNAPResult> startBlinkNodeLED(String? deviceId) =>
      (super.noSuchMethod(
        Invocation.method(
          #startBlinkNodeLED,
          [deviceId],
        ),
        returnValue: _i7.Future<_i4.JNAPResult>.value(_FakeJNAPResult_2(
          this,
          Invocation.method(
            #startBlinkNodeLED,
            [deviceId],
          ),
        )),
        returnValueForMissingStub:
            _i7.Future<_i4.JNAPResult>.value(_FakeJNAPResult_2(
          this,
          Invocation.method(
            #startBlinkNodeLED,
            [deviceId],
          ),
        )),
      ) as _i7.Future<_i4.JNAPResult>);

  @override
  _i7.Future<_i4.JNAPResult> stopBlinkNodeLED() => (super.noSuchMethod(
        Invocation.method(
          #stopBlinkNodeLED,
          [],
        ),
        returnValue: _i7.Future<_i4.JNAPResult>.value(_FakeJNAPResult_2(
          this,
          Invocation.method(
            #stopBlinkNodeLED,
            [],
          ),
        )),
        returnValueForMissingStub:
            _i7.Future<_i4.JNAPResult>.value(_FakeJNAPResult_2(
          this,
          Invocation.method(
            #stopBlinkNodeLED,
            [],
          ),
        )),
      ) as _i7.Future<_i4.JNAPResult>);

  @override
  _i7.Future<void> toggleBlinkNode() => (super.noSuchMethod(
        Invocation.method(
          #toggleBlinkNode,
          [],
        ),
        returnValue: _i7.Future<void>.value(),
        returnValueForMissingStub: _i7.Future<void>.value(),
      ) as _i7.Future<void>);

  @override
  _i7.Future<void> updateDeviceName(String? newName) => (super.noSuchMethod(
        Invocation.method(
          #updateDeviceName,
          [newName],
        ),
        returnValue: _i7.Future<void>.value(),
        returnValueForMissingStub: _i7.Future<void>.value(),
      ) as _i7.Future<void>);

  @override
  bool updateShouldNotify(
    _i3.NodeDetailState? previous,
    _i3.NodeDetailState? next,
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

/// A class which mocks [FirmwareUpdateNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockFirmwareUpdateNotifier extends _i2.Notifier<_i5.FirmwareUpdateState> with _i1.Mock
    implements _i9.FirmwareUpdateNotifier {
  @override
  _i2.NotifierProviderRef<_i5.FirmwareUpdateState> get ref =>
      (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeNotifierProviderRef_0<_i5.FirmwareUpdateState>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub:
            _FakeNotifierProviderRef_0<_i5.FirmwareUpdateState>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.NotifierProviderRef<_i5.FirmwareUpdateState>);

  @override
  _i5.FirmwareUpdateState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeFirmwareUpdateState_3(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakeFirmwareUpdateState_3(
          this,
          Invocation.getter(#state),
        ),
      ) as _i5.FirmwareUpdateState);

  @override
  set state(_i5.FirmwareUpdateState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i5.FirmwareUpdateState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _FakeFirmwareUpdateState_3(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
        returnValueForMissingStub: _FakeFirmwareUpdateState_3(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
      ) as _i5.FirmwareUpdateState);

  @override
  _i7.Future<dynamic> setFirmwareUpdatePolicy(String? policy) =>
      (super.noSuchMethod(
        Invocation.method(
          #setFirmwareUpdatePolicy,
          [policy],
        ),
        returnValue: _i7.Future<dynamic>.value(),
        returnValueForMissingStub: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);

  @override
  _i7.Stream<List<_i10.FirmwareUpdateStatus>> checkFirmwareUpdateStream({
    bool? force = false,
    int? retry = 3,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #checkFirmwareUpdateStream,
          [],
          {
            #force: force,
            #retry: retry,
          },
        ),
        returnValue: _i7.Stream<List<_i10.FirmwareUpdateStatus>>.empty(),
        returnValueForMissingStub:
            _i7.Stream<List<_i10.FirmwareUpdateStatus>>.empty(),
      ) as _i7.Stream<List<_i10.FirmwareUpdateStatus>>);

  @override
  _i7.Future<dynamic> checkFirmwareUpdateStatus() => (super.noSuchMethod(
        Invocation.method(
          #checkFirmwareUpdateStatus,
          [],
        ),
        returnValue: _i7.Future<dynamic>.value(),
        returnValueForMissingStub: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);

  @override
  _i7.Future<dynamic> updateFirmware() => (super.noSuchMethod(
        Invocation.method(
          #updateFirmware,
          [],
        ),
        returnValue: _i7.Future<dynamic>.value(),
        returnValueForMissingStub: _i7.Future<dynamic>.value(),
      ) as _i7.Future<dynamic>);

  @override
  bool isRecordConsistent(
    List<_i10.FirmwareUpdateStatus>? list,
    List<_i10.FirmwareUpdateStatus>? records,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #isRecordConsistent,
          [
            list,
            records,
          ],
        ),
        returnValue: false,
        returnValueForMissingStub: false,
      ) as bool);

  @override
  bool updateShouldNotify(
    _i5.FirmwareUpdateState? previous,
    _i5.FirmwareUpdateState? next,
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