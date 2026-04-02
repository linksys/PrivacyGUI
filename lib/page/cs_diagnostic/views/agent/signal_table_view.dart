import 'package:flutter/material.dart';
import 'package:privacy_gui/page/cs_diagnostic/models/diagnostic_client.dart';

class SignalTableView extends StatelessWidget {
  final List<DiagnosticClient> clients;

  const SignalTableView({super.key, required this.clients});

  @override
  Widget build(BuildContext context) {
    if (clients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No connected devices found.')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 12,
            dataRowMinHeight: 32,
            dataRowMaxHeight: 40,
            headingRowHeight: 36,
            columns: const [
              DataColumn(label: Text('Device', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('IP', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Band', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Signal', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('TX', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('RX', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('\u26a0', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: clients.map((client) => DataRow(
              cells: [
                DataCell(SizedBox(
                  width: 160,
                  child: Text(client.displayNameWithOui, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: client.isFlagged ? FontWeight.bold : FontWeight.normal)),
                )),
                DataCell(Text(client.deviceType ?? client.manufacturer ?? '—',
                    style: TextStyle(fontSize: 11,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600))),
                DataCell(Text(client.ipAddress ?? '—', style: const TextStyle(fontSize: 12))),
                DataCell(_bandChip(context, client.band)),
                DataCell(client.isWireless ? _signalCell(context, client) : const Text('—')),
                DataCell(Text(client.txRateMbps != null ? '${client.txRateMbps} Mb' : '—',
                    style: const TextStyle(fontSize: 12))),
                DataCell(Text(client.rxRateMbps != null ? '${client.rxRateMbps} Mb' : '—',
                    style: const TextStyle(fontSize: 12))),
                DataCell(client.isFlagged
                    ? const Icon(Icons.warning_amber, color: Colors.orange, size: 18)
                    : const SizedBox.shrink()),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _bandChip(BuildContext context, String band) {
    final color = switch (band) {
      '6GHz' => Colors.purple.shade300,
      '5GHz' => Colors.blue.shade300,
      '2.4GHz' => Colors.orange.shade300,
      'Wired' => Colors.grey.shade400,
      _ => Colors.grey.shade300,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(band, style: TextStyle(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w600,
      )),
    );
  }

  Widget _signalCell(BuildContext context, DiagnosticClient client) {
    final signal = client.signalDecibels;
    if (signal == null) return const Text('—');
    final color = switch (client.signalStrength) {
      SignalStrength.excellent => Colors.green,
      SignalStrength.fair => Colors.amber,
      SignalStrength.weak => Colors.orange,
      SignalStrength.veryWeak => Colors.red,
      SignalStrength.unknown => Colors.grey,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 4),
        Text('$signal dBm', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
