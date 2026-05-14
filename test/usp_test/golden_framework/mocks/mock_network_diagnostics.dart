import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/network_diagnostics/models/network_diagnostics_ui_model.dart';
import 'package:privacy_gui/page/network_diagnostics/providers/usp_network_diagnostics_notifier.dart';

/// Fixed notifier that returns a pre-determined [NetworkDiagnosticsState].
///
/// Used for data-level golden tests (idle, running, completed, error).
class FixedNetworkDiagnosticsNotifier extends UspNetworkDiagnosticsNotifier {
  final NetworkDiagnosticsState _fixedState;

  FixedNetworkDiagnosticsNotifier(this._fixedState);

  @override
  Future<NetworkDiagnosticsState> build() async => _fixedState;

  @override
  void updateHost(String host) {}

  @override
  void updatePingCount(int count) {}

  @override
  void updateMaxHops(int hops) {}

  @override
  void switchTab(DiagnosticType tab) {}

  @override
  Future<void> runPing() async {}

  @override
  Future<void> runTraceroute() async {}
}

/// Notifier whose [build] never completes — keeps the provider in loading state.
class _LoadingNetworkDiagnosticsNotifier extends UspNetworkDiagnosticsNotifier {
  @override
  Future<NetworkDiagnosticsState> build() =>
      Completer<NetworkDiagnosticsState>().future;

  @override
  void updateHost(String host) {}

  @override
  void updatePingCount(int count) {}

  @override
  void updateMaxHops(int hops) {}

  @override
  void switchTab(DiagnosticType tab) {}

  @override
  Future<void> runPing() async {}

  @override
  Future<void> runTraceroute() async {}
}

/// Notifier whose [build] throws — puts the provider into error state.
class _ErrorNetworkDiagnosticsNotifier extends UspNetworkDiagnosticsNotifier {
  @override
  Future<NetworkDiagnosticsState> build() async =>
      throw Exception('Connection failed');

  @override
  void updateHost(String host) {}

  @override
  void updatePingCount(int count) {}

  @override
  void updateMaxHops(int hops) {}

  @override
  void switchTab(DiagnosticType tab) {}

  @override
  Future<void> runPing() async {}

  @override
  Future<void> runTraceroute() async {}
}

/// Returns provider overrides that keep the provider in AsyncValue.loading.
List<Override> networkDiagnosticsLoadingOverrides() => [
      uspNetworkDiagnosticsProvider
          .overrideWith(() => _LoadingNetworkDiagnosticsNotifier()),
    ];

/// Returns provider overrides that put the provider into AsyncValue.error.
List<Override> networkDiagnosticsErrorOverrides() => [
      uspNetworkDiagnosticsProvider
          .overrideWith(() => _ErrorNetworkDiagnosticsNotifier()),
    ];

/// Returns provider overrides with a fixed [NetworkDiagnosticsState] data value.
List<Override> networkDiagnosticsOverrides(NetworkDiagnosticsState state) => [
      uspNetworkDiagnosticsProvider
          .overrideWith(() => FixedNetworkDiagnosticsNotifier(state)),
    ];
