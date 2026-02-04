import 'package:flutter/material.dart';
import 'package:privacy_gui/page/health_check/models/health_check_server.dart';
import 'package:ui_kit_library/ui_kit.dart';

class SpeedTestServerSelectionList extends StatelessWidget {
  final List<HealthCheckServer> servers;
  final ValueNotifier<HealthCheckServer?> notifier;

  const SpeedTestServerSelectionList({
    super.key,
    required this.servers,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: ValueListenableBuilder<HealthCheckServer?>(
        valueListenable: notifier,
        builder: (context, selected, child) {
          return ListView.builder(
            shrinkWrap: true,
            itemCount: servers.length,
            itemBuilder: (context, index) {
              final server = servers[index];
              return RadioListTile<HealthCheckServer>(
                title: AppText.bodyMedium(server.toString()),
                value: server,
                groupValue: selected,
                onChanged: (HealthCheckServer? value) {
                  notifier.value = value;
                },
              );
            },
          );
        },
      ),
    );
  }
}
