import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/services/usp_port_forwarding_data_service.dart';

/// Shared data provider for Port Forwarding rules.
///
/// NOT autoDispose — persists across tab switches.
/// SSE: listens for [InvalidationDomain.portForwarding].
final portForwardingDataProvider =
    AsyncNotifierProvider<PortForwardingDataNotifier, PortForwardingData>(
  PortForwardingDataNotifier.new,
);

class PortForwardingData extends Equatable with DiagnosticLoggable {
  final List<PortForwardingRuleUIModel> ruleModels;

  const PortForwardingData({
    required this.ruleModels,
  });

  @override
  Map<String, Object?> get namedProps => {'ruleModels': ruleModels};
}

class PortForwardingDataNotifier extends AsyncNotifier<PortForwardingData> {
  Timer? _debounce;

  @override
  Future<PortForwardingData> build() async {
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain == InvalidationDomain.portForwarding) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () {
          ref.invalidateSelf();
        });
      }
    });
    ref.onDispose(() => _debounce?.cancel());
    return _fetch();
  }

  Future<PortForwardingData> _fetch() async {
    final svc = ref.read(uspPortForwardingDataServiceProvider);
    final ruleModels = await svc.fetch();
    return PortForwardingData(ruleModels: ruleModels);
  }
}
