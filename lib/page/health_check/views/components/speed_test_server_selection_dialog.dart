import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/health_check/models/health_check_server.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class SpeedTestServerSelectionDialog extends StatefulWidget {
  final List<HealthCheckServer> servers;
  const SpeedTestServerSelectionDialog({super.key, required this.servers});

  @override
  State<SpeedTestServerSelectionDialog> createState() =>
      _SpeedTestServerSelectionDialogState();
}

class _SpeedTestServerSelectionDialogState
    extends State<SpeedTestServerSelectionDialog> {
  HealthCheckServer? _selectedServer;

  @override
  void initState() {
    super.initState();
    if (widget.servers.isNotEmpty) {
      _selectedServer = widget.servers.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AppText.titleLarge('Select Speed Test Server'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.servers.length,
            itemBuilder: (context, index) {
              final server = widget.servers[index];
              return RadioListTile<HealthCheckServer>(
                title: AppText.bodyMedium(server.toString()),
                value: server,
                groupValue: _selectedServer,
                onChanged: (HealthCheckServer? value) {
                  setState(() {
                    _selectedServer = value;
                  });
                },
              );
            }),
      ),
      actions: [
        AppTextButton(
          loc(context).cancel,
          onTap: () => Navigator.of(context).pop(),
        ),
        AppTextButton(
          loc(context).ok,
          onTap: _selectedServer != null
              ? () => Navigator.of(context).pop(_selectedServer)
              : null,
        ),
      ],
    );
  }
}
