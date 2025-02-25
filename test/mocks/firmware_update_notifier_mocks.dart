// Mocks generated by Mockito 5.4.4 from annotations
// in privacy_gui/test/mocks/mockito_specs/firmware_update_notifier_spec.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;

import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart'
    as _i6;
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart'
    as _i7;
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart'
    as _i4;
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart'
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

class _FakeFirmwareUpdateState_1 extends _i1.SmartFake
    implements _i3.FirmwareUpdateState {
  _FakeFirmwareUpdateState_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [FirmwareUpdateNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockFirmwareUpdateNotifier extends _i2.Notifier<_i3.FirmwareUpdateState>
    with _i1.Mock
    implements _i4.FirmwareUpdateNotifier {
  @override
  _i2.NotifierProviderRef<_i3.FirmwareUpdateState> get ref =>
      (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeNotifierProviderRef_0<_i3.FirmwareUpdateState>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub:
            _FakeNotifierProviderRef_0<_i3.FirmwareUpdateState>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.NotifierProviderRef<_i3.FirmwareUpdateState>);

  @override
  _i3.FirmwareUpdateState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeFirmwareUpdateState_1(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakeFirmwareUpdateState_1(
          this,
          Invocation.getter(#state),
        ),
      ) as _i3.FirmwareUpdateState);

  @override
  set state(_i3.FirmwareUpdateState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.FirmwareUpdateState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _FakeFirmwareUpdateState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
        returnValueForMissingStub: _FakeFirmwareUpdateState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
      ) as _i3.FirmwareUpdateState);

  @override
  _i5.Future<dynamic> setFirmwareUpdatePolicy(String? policy) =>
      (super.noSuchMethod(
        Invocation.method(
          #setFirmwareUpdatePolicy,
          [policy],
        ),
        returnValue: _i5.Future<dynamic>.value(),
        returnValueForMissingStub: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);

  @override
  _i5.Future<dynamic> fetchAvailableFirmwareUpdates() => (super.noSuchMethod(
        Invocation.method(
          #fetchAvailableFirmwareUpdates,
          [],
        ),
        returnValue: _i5.Future<dynamic>.value(),
        returnValueForMissingStub: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);

  @override
  _i5.Stream<List<_i6.FirmwareUpdateStatus>> fetchFirmwareUpdateStream({
    bool? force = false,
    int? retry = 3,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #fetchFirmwareUpdateStream,
          [],
          {
            #force: force,
            #retry: retry,
          },
        ),
        returnValue: _i5.Stream<List<_i6.FirmwareUpdateStatus>>.empty(),
        returnValueForMissingStub:
            _i5.Stream<List<_i6.FirmwareUpdateStatus>>.empty(),
      ) as _i5.Stream<List<_i6.FirmwareUpdateStatus>>);

  @override
  _i5.Future<dynamic> updateFirmware() => (super.noSuchMethod(
        Invocation.method(
          #updateFirmware,
          [],
        ),
        returnValue: _i5.Future<dynamic>.value(),
        returnValueForMissingStub: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);

  @override
  _i5.Future<dynamic> finishFirmwareUpdate() => (super.noSuchMethod(
        Invocation.method(
          #finishFirmwareUpdate,
          [],
        ),
        returnValue: _i5.Future<dynamic>.value(),
        returnValueForMissingStub: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);

  @override
  List<(_i7.LinksysDevice, _i6.FirmwareUpdateStatus)> getIDStatusRecords() =>
      (super.noSuchMethod(
        Invocation.method(
          #getIDStatusRecords,
          [],
        ),
        returnValue: <(_i7.LinksysDevice, _i6.FirmwareUpdateStatus)>[],
        returnValueForMissingStub: <(
          _i7.LinksysDevice,
          _i6.FirmwareUpdateStatus
        )>[],
      ) as List<(_i7.LinksysDevice, _i6.FirmwareUpdateStatus)>);

  @override
  int getAvailableUpdateNumber() => (super.noSuchMethod(
        Invocation.method(
          #getAvailableUpdateNumber,
          [],
        ),
        returnValue: 0,
        returnValueForMissingStub: 0,
      ) as int);

  @override
  bool isRecordConsistent(
    List<_i6.FirmwareUpdateStatus>? list,
    List<_i6.FirmwareUpdateStatus>? records,
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
  _i5.Future<bool> manualFirmwareUpdate(
    String? filename,
    List<int>? bytes,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #manualFirmwareUpdate,
          [
            filename,
            bytes,
          ],
        ),
        returnValue: _i5.Future<bool>.value(false),
        returnValueForMissingStub: _i5.Future<bool>.value(false),
      ) as _i5.Future<bool>);

  @override
  _i5.Future<dynamic> waitForRouterBackOnline() => (super.noSuchMethod(
        Invocation.method(
          #waitForRouterBackOnline,
          [],
        ),
        returnValue: _i5.Future<dynamic>.value(),
        returnValueForMissingStub: _i5.Future<dynamic>.value(),
      ) as _i5.Future<dynamic>);

  @override
  void listenSelf(
    void Function(
      _i3.FirmwareUpdateState?,
      _i3.FirmwareUpdateState,
    )? listener, {
    void Function(
      Object,
      StackTrace,
    )? onError,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #listenSelf,
          [listener],
          {#onError: onError},
        ),
        returnValueForMissingStub: null,
      );

  @override
  bool updateShouldNotify(
    _i3.FirmwareUpdateState? previous,
    _i3.FirmwareUpdateState? next,
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
