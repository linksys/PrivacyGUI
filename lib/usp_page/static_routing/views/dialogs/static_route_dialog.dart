import 'package:flutter/material.dart';
import 'package:privacy_gui/usp_page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/usp_page/static_routing/services/usp_static_routing_service.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Result returned by [StaticRouteDialog].
class StaticRouteDialogResult {
  final String name;
  final String destIpAddress;
  final String destSubnetMask;
  final String gatewayIpAddress;
  final String interfaceName;
  final bool enabled;

  const StaticRouteDialogResult({
    required this.name,
    required this.destIpAddress,
    required this.destSubnetMask,
    required this.gatewayIpAddress,
    required this.interfaceName,
    required this.enabled,
  });
}

/// Dialog for adding or editing a static route.
///
/// Pass [route] to pre-fill for editing; omit for adding.
class StaticRouteDialog extends StatefulWidget {
  final StaticRouteUIModel? route;

  const StaticRouteDialog({super.key, this.route});

  @override
  State<StaticRouteDialog> createState() => _StaticRouteDialogState();
}

class _StaticRouteDialogState extends State<StaticRouteDialog> {
  late TextEditingController _nameController;
  late TextEditingController _destIpController;
  late TextEditingController _subnetMaskController;
  late TextEditingController _gatewayController;
  late String _interfaceName;
  late bool _enabled;

  Map<String, String> _errors = {};

  bool get _isEdit => widget.route != null;

  @override
  void initState() {
    super.initState();
    final r = widget.route;
    _nameController = TextEditingController(text: r?.name ?? '');
    _destIpController = TextEditingController(text: r?.destIpAddress ?? '');
    _subnetMaskController =
        TextEditingController(text: r?.destSubnetMask ?? '');
    _gatewayController = TextEditingController(text: r?.gatewayIpAddress ?? '');
    _interfaceName = r?.interfaceName ?? 'LAN';
    _enabled = r?.enabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destIpController.dispose();
    _subnetMaskController.dispose();
    _gatewayController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _errors = UspStaticRoutingService.validateRoute(
        name: _nameController.text.trim(),
        destIp: _destIpController.text.trim(),
        subnetMask: _subnetMaskController.text.trim(),
        gateway: _gatewayController.text.trim(),
      );
    });
  }

  bool get _isFormValid {
    final errors = UspStaticRoutingService.validateRoute(
      name: _nameController.text.trim(),
      destIp: _destIpController.text.trim(),
      subnetMask: _subnetMaskController.text.trim(),
      gateway: _gatewayController.text.trim(),
    );
    return errors.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Static Route' : 'Add Static Route'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              hintText: 'Route Name',
              errorText: _errors['name'],
              onChanged: (_) => _validate(),
            ),
            AppGap.lg(),
            AppIpv4TextField(
              controller: _destIpController,
              label: 'Destination IP',
              errorText: _errors['destIp'],
              onChanged: (_) => _validate(),
            ),
            AppGap.lg(),
            AppIpv4TextField(
              controller: _subnetMaskController,
              label: 'Subnet Mask',
              errorText: _errors['subnetMask'],
              onChanged: (_) => _validate(),
            ),
            AppGap.lg(),
            AppIpv4TextField(
              controller: _gatewayController,
              label: 'Gateway IP',
              errorText: _errors['gateway'],
              onChanged: (_) => _validate(),
            ),
            AppGap.lg(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.bodyMedium('Interface'),
                SegmentedButton<String>(
                  segments: UspStaticRoutingService.interfaceOptions
                      .map((name) =>
                          ButtonSegment(value: name, label: Text(name)))
                      .toList(),
                  selected: {_interfaceName},
                  onSelectionChanged: (v) =>
                      setState(() => _interfaceName = v.first),
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
          onPressed: _isFormValid ? _submit : null,
          child: Text(_isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop(StaticRouteDialogResult(
      name: _nameController.text.trim(),
      destIpAddress: _destIpController.text.trim(),
      destSubnetMask: _subnetMaskController.text.trim(),
      gatewayIpAddress: _gatewayController.text.trim(),
      interfaceName: _interfaceName,
      enabled: _enabled,
    ));
  }
}
