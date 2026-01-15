import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_helpers.dart';

final ethernetPortsProvider = Provider<EthernetPortsState>((ref) {
  final pollingData = ref.watch(pollingProvider).value;

  String? wanConnection;
  List<String> lanConnections = [];

  final portsOutput =
      getPollingOutput(pollingData, JNAPAction.getEthernetPortConnections);
  if (portsOutput != null) {
    wanConnection = portsOutput['wanPortConnection'] as String?;
    lanConnections = List<String>.from(portsOutput['lanPortConnections'] ?? []);
  }

  return EthernetPortsState(
    wanConnection: wanConnection,
    lanConnections: lanConnections,
  );
});

class EthernetPortsState extends Equatable {
  final String? wanConnection;
  final List<String> lanConnections;

  const EthernetPortsState({
    this.wanConnection,
    this.lanConnections = const [],
  });

  @override
  List<Object?> get props => [wanConnection, lanConnections];
}
