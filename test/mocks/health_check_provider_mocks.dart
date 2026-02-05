// Custom mock for HealthCheckProvider that extends the real provider
// to inherit Riverpod's internal methods while allowing method stubbing.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;

import 'package:mockito/mockito.dart' as _i1;
import 'package:privacy_gui/page/health_check/models/health_check_server.dart'
    as _i6;
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart'
    as _i4;
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart'
    as _i3;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class
// ignore_for_file: invalid_use_of_internal_member

/// A class which mocks [HealthCheckProvider].
///
/// This mock extends the real HealthCheckProvider to inherit Riverpod's
/// internal methods (like _setElement) while mixing in Mock for stubbing.
class MockHealthCheckProvider extends _i4.HealthCheckProvider with _i1.Mock {
  @override
  _i3.HealthCheckState build() => (super.noSuchMethod(
        Invocation.method(
          #build,
          [],
        ),
        returnValue: _i3.HealthCheckState.init(),
        returnValueForMissingStub: _i3.HealthCheckState.init(),
      ) as _i3.HealthCheckState);

  @override
  _i5.Future<void> loadData() => (super.noSuchMethod(
        Invocation.method(
          #loadData,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> loadServers() => (super.noSuchMethod(
        Invocation.method(
          #loadServers,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  void setSelectedServer(_i6.HealthCheckServer? server) => super.noSuchMethod(
        Invocation.method(
          #setSelectedServer,
          [server],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i5.Future<void> runHealthCheck(
    _i4.Module? module, {
    int? serverId,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #runHealthCheck,
          [module],
          {#serverId: serverId},
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);

  @override
  _i5.Future<void> stopHealthCheck() => (super.noSuchMethod(
        Invocation.method(
          #stopHealthCheck,
          [],
        ),
        returnValue: _i5.Future<void>.value(),
        returnValueForMissingStub: _i5.Future<void>.value(),
      ) as _i5.Future<void>);
}
