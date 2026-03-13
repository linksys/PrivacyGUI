import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/dashboard/models/port_forwarding_rule_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Result returned by [PortRangeForwardingDialog].
class PortRangeForwardingDialogResult {
  final String description;
  final int externalPortStart;
  final int externalPortEnd;
  final int internalPort;
  final String internalClient;
  final String protocol;
  final bool enabled;

  const PortRangeForwardingDialogResult({
    required this.description,
    required this.externalPortStart,
    required this.externalPortEnd,
    required this.internalPort,
    required this.internalClient,
    required this.protocol,
    required this.enabled,
  });
}

/// Dialog for adding or editing a port range forwarding rule.
///
/// Pass [rule] to pre-fill for editing; omit for adding.
class PortRangeForwardingDialog extends StatefulWidget {
  final PortForwardingRuleUIModel? rule;

  const PortRangeForwardingDialog({super.key, this.rule});

  @override
  State<PortRangeForwardingDialog> createState() =>
      _PortRangeForwardingDialogState();
}

class _PortRangeForwardingDialogState extends State<PortRangeForwardingDialog> {
  late TextEditingController _descController;
  late TextEditingController _extPortStartController;
  late TextEditingController _extPortEndController;
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
    _extPortStartController =
        TextEditingController(text: r != null ? '${r.externalPort}' : '');
    _extPortEndController = TextEditingController(
        text: r != null ? '${r.externalPortEndRange}' : '');
    _intPortController =
        TextEditingController(text: r != null ? '${r.internalPort}' : '');
    _intClientController = TextEditingController(text: r?.internalClient ?? '');
    _protocol = r?.protocol ?? 'TCP';
    _enabled = r?.enabled ?? true;
  }

  @override
  void dispose() {
    _descController.dispose();
    _extPortStartController.dispose();
    _extPortEndController.dispose();
    _intPortController.dispose();
    _intClientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          _isEdit ? 'Edit Port Range Forwarding' : 'Add Port Range Forwarding'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _descController,
              hintText: 'Description',
            ),
            AppGap.lg(),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _extPortStartController,
                    hintText: 'External Port Start',
                    keyboardType: TextInputType.number,
                  ),
                ),
                AppGap.md(),
                Expanded(
                  child: AppTextField(
                    controller: _extPortEndController,
                    hintText: 'External Port End',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
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
    final extStart = int.tryParse(_extPortStartController.text.trim());
    final extEnd = int.tryParse(_extPortEndController.text.trim());
    final intPort = int.tryParse(_intPortController.text.trim());
    final client = _intClientController.text.trim();
    if (extStart == null ||
        extEnd == null ||
        intPort == null ||
        client.isEmpty) {
      return;
    }
    if (extEnd <= extStart) return;
    Navigator.of(context).pop(PortRangeForwardingDialogResult(
      description: _descController.text.trim(),
      externalPortStart: extStart,
      externalPortEnd: extEnd,
      internalPort: intPort,
      internalClient: client,
      protocol: _protocol,
      enabled: _enabled,
    ));
  }
}
