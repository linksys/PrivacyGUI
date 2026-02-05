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
          return AppRadioList<HealthCheckServer>(
            initial: selected,
            itemHeight: 56,
            items: servers
                .map((server) => AppRadioListItem(
                      title: server.toString(),
                      value: server,
                    ))
                .toList(),
            onChanged: (index, value) {
              notifier.value = value;
            },
          );
        },
      ),
    );
  }
}
