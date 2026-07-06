import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/services/usp_port_triggering_data_service.dart';

/// Shared data provider for Port Triggering rules.
///
/// NOT autoDispose — persists across tab switches.
/// No SSE invalidation domain defined for port triggering.
final portTriggeringDataProvider =
    AsyncNotifierProvider<PortTriggeringDataNotifier, PortTriggeringData>(
  PortTriggeringDataNotifier.new,
);

class PortTriggeringData extends Equatable with DiagnosticLoggable {
  final List<PortTriggeringRuleUIModel> ruleModels;

  const PortTriggeringData({
    required this.ruleModels,
  });

  @override
  Map<String, Object?> get namedProps => {'ruleModels': ruleModels};
}

class PortTriggeringDataNotifier extends AsyncNotifier<PortTriggeringData> {
  @override
  Future<PortTriggeringData> build() async {
    return _fetch();
  }

  Future<PortTriggeringData> _fetch() async {
    final svc = ref.read(uspPortTriggeringDataServiceProvider);
    final ruleModels = await svc.fetch();
    return PortTriggeringData(ruleModels: ruleModels);
  }
}
