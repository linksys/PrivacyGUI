// Mocks generated by Mockito 5.4.4 from annotations
// in privacy_gui/test/mocks/mockito_specs/pnp_notifier_spec.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i8;

import 'package:flutter_riverpod/flutter_riverpod.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i10;
import 'package:privacy_gui/core/jnap/actions/better_action.dart' as _i12;
import 'package:privacy_gui/core/jnap/models/auto_configuration_settings.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart' as _i7;
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart' as _i3;
import 'package:privacy_gui/page/instant_setup/data/pnp_step_state.dart' as _i4;
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart' as _i11;
import 'package:privacy_gui/providers/connectivity/availability_info.dart'
    as _i6;
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart'
    as _i9;
import 'package:privacy_gui/providers/connectivity/connectivity_state.dart'
    as _i5;

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

class _FakePnpState_1 extends _i1.SmartFake implements _i3.PnpState {
  _FakePnpState_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeDuration_2 extends _i1.SmartFake implements Duration {
  _FakeDuration_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakePnpStepState_3 extends _i1.SmartFake implements _i4.PnpStepState {
  _FakePnpStepState_3(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeConnectivityState_4 extends _i1.SmartFake
    implements _i5.ConnectivityState {
  _FakeConnectivityState_4(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeAvailabilityInfo_5 extends _i1.SmartFake
    implements _i6.AvailabilityInfo {
  _FakeAvailabilityInfo_5(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [PnpNotifier].
///
/// See the documentation for Mockito's code generation for more information.
class MockPnpNotifier extends _i2.Notifier<_i3.PnpState>
    with _i1.Mock
    implements _i7.PnpNotifier {
  @override
  _i2.NotifierProviderRef<_i3.PnpState> get ref => (super.noSuchMethod(
        Invocation.getter(#ref),
        returnValue: _FakeNotifierProviderRef_0<_i3.PnpState>(
          this,
          Invocation.getter(#ref),
        ),
        returnValueForMissingStub: _FakeNotifierProviderRef_0<_i3.PnpState>(
          this,
          Invocation.getter(#ref),
        ),
      ) as _i2.NotifierProviderRef<_i3.PnpState>);

  @override
  _i3.PnpState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakePnpState_1(
          this,
          Invocation.getter(#state),
        ),
        returnValueForMissingStub: _FakePnpState_1(
          this,
          Invocation.getter(#state),
        ),
      ) as _i3.PnpState);

  @override
  set state(_i3.PnpState? value) => super.noSuchMethod(
        Invocation.setter(
          #state,
          value,
        ),
        returnValueForMissingStub: null,
      );

  @override
  Duration get internetCheckPeriod => (super.noSuchMethod(
        Invocation.getter(#internetCheckPeriod),
        returnValue: _FakeDuration_2(
          this,
          Invocation.getter(#internetCheckPeriod),
        ),
        returnValueForMissingStub: _FakeDuration_2(
          this,
          Invocation.getter(#internetCheckPeriod),
        ),
      ) as Duration);

  @override
  set internetCheckPeriod(Duration? _internetCheckPeriod) => super.noSuchMethod(
        Invocation.setter(
          #internetCheckPeriod,
          _internetCheckPeriod,
        ),
        returnValueForMissingStub: null,
      );

  @override
  set timer(_i8.Timer? _timer) => super.noSuchMethod(
        Invocation.setter(
          #timer,
          _timer,
        ),
        returnValueForMissingStub: null,
      );

  @override
  set callback(
          dynamic Function(
            bool,
            _i9.ConnectivityInfo,
            _i6.AvailabilityInfo?,
          )? callback) =>
      super.noSuchMethod(
        Invocation.setter(
          #callback,
          callback,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i8.Future<dynamic> fetchDeviceInfo() => (super.noSuchMethod(
        Invocation.method(
          #fetchDeviceInfo,
          [],
        ),
        returnValue: _i8.Future<dynamic>.value(),
        returnValueForMissingStub: _i8.Future<dynamic>.value(),
      ) as _i8.Future<dynamic>);

  @override
  _i8.Future<dynamic> checkAdminPassword(String? password) =>
      (super.noSuchMethod(
        Invocation.method(
          #checkAdminPassword,
          [password],
        ),
        returnValue: _i8.Future<dynamic>.value(),
        returnValueForMissingStub: _i8.Future<dynamic>.value(),
      ) as _i8.Future<dynamic>);

  @override
  _i8.Future<dynamic> checkInternetConnection([int? retries = 1]) =>
      (super.noSuchMethod(
        Invocation.method(
          #checkInternetConnection,
          [retries],
        ),
        returnValue: _i8.Future<dynamic>.value(),
        returnValueForMissingStub: _i8.Future<dynamic>.value(),
      ) as _i8.Future<dynamic>);

  @override
  _i8.Future<AutoConfigurationSettings?> autoConfigurationCheck() => (super.noSuchMethod(
        Invocation.method(
          #pnpCheck,
          [],
        ),
        returnValue: _i8.Future<AutoConfigurationSettings?>.value(null),
        returnValueForMissingStub: _i8.Future<AutoConfigurationSettings?>.value(null),
      ) as _i8.Future<AutoConfigurationSettings?>);

  @override
  _i8.Future<bool> isRouterPasswordSet() => (super.noSuchMethod(
        Invocation.method(
          #isRouterPasswordSet,
          [],
        ),
        returnValue: _i8.Future<bool>.value(false),
        returnValueForMissingStub: _i8.Future<bool>.value(false),
      ) as _i8.Future<bool>);

  @override
  _i8.Future<dynamic> fetchData() => (super.noSuchMethod(
        Invocation.method(
          #fetchData,
          [],
        ),
        returnValue: _i8.Future<dynamic>.value(),
        returnValueForMissingStub: _i8.Future<dynamic>.value(),
      ) as _i8.Future<dynamic>);

  @override
  ({String name, String password, String security})
      getDefaultWiFiNameAndPassphrase() => (super.noSuchMethod(
            Invocation.method(
              #getDefaultWiFiNameAndPassphrase,
              [],
            ),
            returnValue: (
              name: _i10.dummyValue<String>(
                this,
                Invocation.method(
                  #getDefaultWiFiNameAndPassphrase,
                  [],
                ),
              ),
              password: _i10.dummyValue<String>(
                this,
                Invocation.method(
                  #getDefaultWiFiNameAndPassphrase,
                  [],
                ),
              ),
              security: _i10.dummyValue<String>(
                this,
                Invocation.method(
                  #getDefaultWiFiNameAndPassphrase,
                  [],
                ),
              )
            ),
            returnValueForMissingStub: (
              name: _i10.dummyValue<String>(
                this,
                Invocation.method(
                  #getDefaultWiFiNameAndPassphrase,
                  [],
                ),
              ),
              password: _i10.dummyValue<String>(
                this,
                Invocation.method(
                  #getDefaultWiFiNameAndPassphrase,
                  [],
                ),
              ),
              security: _i10.dummyValue<String>(
                this,
                Invocation.method(
                  #getDefaultWiFiNameAndPassphrase,
                  [],
                ),
              )
            ),
          ) as ({String name, String password, String security}));

  @override
  ({String name, String password}) getDefaultGuestWiFiNameAndPassPhrase() =>
      (super.noSuchMethod(
        Invocation.method(
          #getDefaultGuestWiFiNameAndPassPhrase,
          [],
        ),
        returnValue: (
          name: _i10.dummyValue<String>(
            this,
            Invocation.method(
              #getDefaultGuestWiFiNameAndPassPhrase,
              [],
            ),
          ),
          password: _i10.dummyValue<String>(
            this,
            Invocation.method(
              #getDefaultGuestWiFiNameAndPassPhrase,
              [],
            ),
          )
        ),
        returnValueForMissingStub: (
          name: _i10.dummyValue<String>(
            this,
            Invocation.method(
              #getDefaultGuestWiFiNameAndPassPhrase,
              [],
            ),
          ),
          password: _i10.dummyValue<String>(
            this,
            Invocation.method(
              #getDefaultGuestWiFiNameAndPassPhrase,
              [],
            ),
          )
        ),
      ) as ({String name, String password}));

  @override
  _i8.Future<dynamic> save() => (super.noSuchMethod(
        Invocation.method(
          #save,
          [],
        ),
        returnValue: _i8.Future<dynamic>.value(),
        returnValueForMissingStub: _i8.Future<dynamic>.value(),
      ) as _i8.Future<dynamic>);

  @override
  _i8.Future<dynamic> testConnectionReconnected() => (super.noSuchMethod(
        Invocation.method(
          #testConnectionReconnected,
          [],
        ),
        returnValue: _i8.Future<dynamic>.value(),
        returnValueForMissingStub: _i8.Future<dynamic>.value(),
      ) as _i8.Future<dynamic>);

  @override
  _i8.Future<dynamic> checkRouterConfigured() => (super.noSuchMethod(
        Invocation.method(
          #checkRouterConfigured,
          [],
        ),
        returnValue: _i8.Future<dynamic>.value(),
        returnValueForMissingStub: _i8.Future<dynamic>.value(),
      ) as _i8.Future<dynamic>);

  @override
  _i8.Future<dynamic> fetchDevices() => (super.noSuchMethod(
        Invocation.method(
          #fetchDevices,
          [],
        ),
        returnValue: _i8.Future<dynamic>.value(),
        returnValueForMissingStub: _i8.Future<dynamic>.value(),
      ) as _i8.Future<dynamic>);

  @override
  void setAttachedPassword(String? password) => super.noSuchMethod(
        Invocation.method(
          #setAttachedPassword,
          [password],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void setForceLogin(bool? force) => super.noSuchMethod(
        Invocation.method(
          #setForceLogin,
          [force],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.PnpState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _FakePnpState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
        returnValueForMissingStub: _FakePnpState_1(
          this,
          Invocation.method(
            #build,
            [],
          ),
        ),
      ) as _i3.PnpState);

  @override
  _i4.PnpStepState getStepState(int? index) => (super.noSuchMethod(
        Invocation.method(
          #getStepState,
          [index],
        ),
        returnValue: _FakePnpStepState_3(
          this,
          Invocation.method(
            #getStepState,
            [index],
          ),
        ),
        returnValueForMissingStub: _FakePnpStepState_3(
          this,
          Invocation.method(
            #getStepState,
            [index],
          ),
        ),
      ) as _i4.PnpStepState);

  @override
  void setStepState(
    int? index,
    _i4.PnpStepState? stepState,
  ) =>
      super.noSuchMethod(
        Invocation.method(
          #setStepState,
          [
            index,
            stepState,
          ],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void setStepStatus(
    int? index, {
    required _i11.StepViewStatus? status,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #setStepStatus,
          [index],
          {#status: status},
        ),
        returnValueForMissingStub: null,
      );

  @override
  void setStepData(
    int? index, {
    required Map<String, dynamic>? data,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #setStepData,
          [index],
          {#data: data},
        ),
        returnValueForMissingStub: null,
      );

  @override
  void setStepError(
    int? index, {
    Object? error,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #setStepError,
          [index],
          {#error: error},
        ),
        returnValueForMissingStub: null,
      );

  @override
  Map<String, dynamic>? getData(_i12.JNAPAction? action) => (super.noSuchMethod(
        Invocation.method(
          #getData,
          [action],
        ),
        returnValueForMissingStub: null,
      ) as Map<String, dynamic>?);

  @override
  bool updateShouldNotify(
    _i3.PnpState? previous,
    _i3.PnpState? next,
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

  @override
  _i8.Future<_i5.ConnectivityState> check(_i9.ConnectivityInfo? info) =>
      (super.noSuchMethod(
        Invocation.method(
          #check,
          [info],
        ),
        returnValue:
            _i8.Future<_i5.ConnectivityState>.value(_FakeConnectivityState_4(
          this,
          Invocation.method(
            #check,
            [info],
          ),
        )),
        returnValueForMissingStub:
            _i8.Future<_i5.ConnectivityState>.value(_FakeConnectivityState_4(
          this,
          Invocation.method(
            #check,
            [info],
          ),
        )),
      ) as _i8.Future<_i5.ConnectivityState>);

  @override
  _i8.Future<bool> testConnection() => (super.noSuchMethod(
        Invocation.method(
          #testConnection,
          [],
        ),
        returnValue: _i8.Future<bool>.value(false),
        returnValueForMissingStub: _i8.Future<bool>.value(false),
      ) as _i8.Future<bool>);

  @override
  _i8.Future<_i6.AvailabilityInfo> testCloudAvailability() =>
      (super.noSuchMethod(
        Invocation.method(
          #testCloudAvailability,
          [],
        ),
        returnValue:
            _i8.Future<_i6.AvailabilityInfo>.value(_FakeAvailabilityInfo_5(
          this,
          Invocation.method(
            #testCloudAvailability,
            [],
          ),
        )),
        returnValueForMissingStub:
            _i8.Future<_i6.AvailabilityInfo>.value(_FakeAvailabilityInfo_5(
          this,
          Invocation.method(
            #testCloudAvailability,
            [],
          ),
        )),
      ) as _i8.Future<_i6.AvailabilityInfo>);
}
