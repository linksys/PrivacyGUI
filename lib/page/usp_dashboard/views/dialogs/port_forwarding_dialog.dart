import 'package:flutter/material.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Result returned by [PortForwardingDialog].
class PortForwardingDialogResult {
  final String description;
  final int externalPort;
  final int internalPort;
  final String internalClient;
  final String protocol;
  final bool enabled;

  const PortForwardingDialogResult({
    required this.description,
    required this.externalPort,
    required this.internalPort,
    required this.internalClient,
    required this.protocol,
    required this.enabled,
  });
}

/// Dialog for adding or editing a port forwarding rule.
///
/// Pass [rule] to pre-fill for editing; omit for adding.
class PortForwardingDialog extends StatefulWidget {
  final PortForwardingRule? rule;

  const PortForwardingDialog({super.key, this.rule});

  @override
  State<PortForwardingDialog> createState() => _PortForwardingDialogState();
}

class _PortForwardingDialogState extends State<PortForwardingDialog> {
  late TextEditingController _descController;
  late TextEditingController _extPortController;
  late TextEditingController _intPortController;
  late TextEditingController _intClientController;
  late String _protocol;
  late bool _enabled;

  bool get _isEdit => widget.rule != null;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _descController = TextEditingController(text: r?.description ?? '');
    _extPortController =
        TextEditingController(text: r != null ? '${r.externalPort}' : '');
    _intPortController =
        TextEditingController(text: r != null ? '${r.internalPort}' : '');
    _intClientController =
        TextEditingController(text: r?.internalClient ?? '');
    _protocol = r?.protocol ?? 'TCP';
    _enabled = r?.enabled ?? true;
  }

  @override
  void dispose() {
    _descController.dispose();
    _extPortController.dispose();
    _intPortController.dispose();
    _intClientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Port Forwarding' : 'Add Port Forwarding'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _descController,
              hintText: 'Description',
            ),
            AppGap.lg(),
            AppTextField(
              controller: _extPortController,
              hintText: 'External Port',
              keyboardType: TextInputType.number,
            ),
            AppGap.lg(),
            AppTextField(
              controller: _intPortController,
              hintText: 'Internal Port',
              keyboardType: TextInputType.number,
            ),
            AppGap.lg(),
            AppTextField(
              controller: _intClientController,
              hintText: 'Internal IP (e.g. 192.168.1.100)',
            ),
            AppGap.lg(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.bodyMedium('Protocol'),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'TCP', label: Text('TCP')),
                    ButtonSegment(value: 'UDP', label: Text('UDP')),
                    ButtonSegment(value: 'Both', label: Text('Both')),
                  ],
                  selected: {_protocol},
                  onSelectionChanged: (v) =>
                      setState(() => _protocol = v.first),
                ),
              ],
            ),
            AppGap.lg(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.bodyMedium('Enabled'),
                AppSwitch(
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _submit() {
    final extPort = int.tryParse(_extPortController.text.trim());
    final intPort = int.tryParse(_intPortController.text.trim());
    final client = _intClientController.text.trim();
    if (extPort == null || intPort == null || client.isEmpty) return;
    Navigator.of(context).pop(PortForwardingDialogResult(
      description: _descController.text.trim(),
      externalPort: extPort,
      internalPort: intPort,
      internalClient: client,
      protocol: _protocol,
      enabled: _enabled,
    ));
  }
}
