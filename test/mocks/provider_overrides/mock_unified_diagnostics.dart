import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/manual_tools_state.dart';
import 'package:privacy_gui/page/unified_diagnostics/providers/manual_tools_notifier.dart';
import 'package:privacy_gui/page/unified_diagnostics/providers/unified_diagnostics_notifier.dart';

class FixedUnifiedDiagnosticsNotifier extends UnifiedDiagnosticsNotifier {
  final UnifiedDiagnosticsState _fixedState;

  FixedUnifiedDiagnosticsNotifier(this._fixedState);

  @override
  UnifiedDiagnosticsState build() => _fixedState;

  @override
  Future<void> runFullDiagnostic() async {}

  @override
  void openManualTools() {}

  @override
  Future<void> startWithPreQualifier() async {}

  @override
  Future<void> selectFlow(DiagnosticFlow flow) async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> restart() async {}

  @override
  bool goBack() => false;
}

class FixedManualToolsNotifier extends ManualToolsNotifier {
  final NetworkDiagnosticsState _fixedState;

  FixedManualToolsNotifier(this._fixedState);

  @override
  Future<NetworkDiagnosticsState> build() async => _fixedState;

  @override
  void updateHost(String host) {}

  @override
  void updatePingCount(int count) {}

  @override
  void updateMaxHops(int hops) {}

  @override
  void updateDnsServer(String server) {}

  @override
  void switchTab(DiagnosticType tab) {}

  @override
  Future<void> runPing() async {}

  @override
  Future<void> runTraceroute() async {}

  @override
  Future<void> runNsLookup() async {}
}

List<Override> unifiedDiagnosticsOverrides(UnifiedDiagnosticsState state) => [
      unifiedDiagnosticsProvider
          .overrideWith(() => FixedUnifiedDiagnosticsNotifier(state)),
    ];

List<Override> manualToolsOverrides(NetworkDiagnosticsState state) => [
      unifiedDiagnosticsProvider.overrideWith(() =>
          FixedUnifiedDiagnosticsNotifier(
              const UnifiedDiagnosticsState(step: DiagnosticStep.manualTools))),
      manualToolsProvider.overrideWith(() => FixedManualToolsNotifier(state)),
    ];
