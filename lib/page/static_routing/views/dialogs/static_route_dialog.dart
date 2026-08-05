import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/page/static_routing/services/usp_static_routing_service.dart';
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
/// Pass [lanIp] and [lanSubnetMask] to enable gateway subnet validation.
class StaticRouteDialog extends StatefulWidget {
  final StaticRouteUIModel? route;
  final String? lanIp;
  final String? lanSubnetMask;

  const StaticRouteDialog({
    super.key,
    this.route,
    this.lanIp,
    this.lanSubnetMask,
  });

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
    // Pre-populate validation state only in edit mode. On add-dialog open all
    // fields are empty, so computing errors immediately would show "required"
    // errors before the user has typed anything (confusing, non-standard UX).
    _errors = _isEdit ? _computeErrors() : {};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destIpController.dispose();
    _subnetMaskController.dispose();
    _gatewayController.dispose();
    super.dispose();
  }

  Map<String, String> _computeErrors() {
    return UspStaticRoutingService.validateRoute(
      name: _nameController.text.trim(),
      destIp: _destIpController.text.trim(),
      subnetMask: _subnetMaskController.text.trim(),
      gateway: _gatewayController.text.trim(),
      interfaceName: _interfaceName,
      lanIp: widget.lanIp,
      lanSubnetMask: widget.lanSubnetMask,
    );
  }

  void _validate() {
    setState(() {
      _errors = _computeErrors();
    });
  }

  /// Convert error key to localized string.
  String? _localizeError(String? key) {
    if (key == null) return null;
    final l = loc(context);
    return switch (key) {
      StaticRoutingErrorKeys.nameRequired => l.invalidInput,
      StaticRoutingErrorKeys.nameTooLong => l.invalidInput,
      StaticRoutingErrorKeys.destIpRequired => l.ipAddressRequired,
      StaticRoutingErrorKeys.invalidIpAddress => l.invalidIpAddress,
      StaticRoutingErrorKeys.subnetMaskRequired => l.invalidInput,
      StaticRoutingErrorKeys.invalidSubnetMask => l.invalidInput,
      StaticRoutingErrorKeys.gatewayMustBeWithinLanSubnet =>
        l.gatewayMustBeWithinLanSubnet,
      StaticRoutingErrorKeys.gatewayMustBeOutsideLanSubnet =>
        l.gatewayMustBeOutsideLanSubnet,
      _ => key,
    };
  }

  // Compute validity from the live field values rather than the cached
  // [_errors] map. In add mode [_errors] starts empty (errors are suppressed
  // on open for UX), so relying on it would enable the Save button on a blank
  // form and allow submitting an empty route. Recomputing here reflects the
  // true form state without surfacing "required" errors before the user types.
  bool get _isFormValid => _computeErrors().isEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          _isEdit ? loc(context).editStaticRoute : loc(context).addStaticRoute),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              identifier: 'static-route-name',
              hintText: loc(context).routeName,
              errorText: _localizeError(_errors['name']),
              onChanged: (_) => _validate(),
            ),
            AppGap.lg(),
            AppIpv4TextField(
              controller: _destIpController,
              identifier: 'static-route-dest-ip',
              label: loc(context).destinationIp,
              errorText: _localizeError(_errors['destIp']),
              onChanged: (_) => _validate(),
            ),
            AppGap.lg(),
            AppIpv4TextField(
              controller: _subnetMaskController,
              identifier: 'static-route-subnet-mask',
              label: loc(context).subnetMask,
              errorText: _localizeError(_errors['subnetMask']),
              onChanged: (_) => _validate(),
            ),
            AppGap.lg(),
            AppIpv4TextField(
              controller: _gatewayController,
              identifier: 'static-route-gateway',
              label: loc(context).gatewayIp,
              errorText: _localizeError(_errors['gateway']),
              onChanged: (_) => _validate(),
            ),
            AppGap.lg(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.bodyMedium(loc(context).labelInterface),
                SegmentedButton<String>(
                  segments: UspStaticRoutingService.interfaceOptions
                      .map((name) =>
                          ButtonSegment(value: name, label: Text(name)))
                      .toList(),
                  selected: {_interfaceName},
                  onSelectionChanged: (v) {
                    setState(() => _interfaceName = v.first);
                    _validate();
                  },
                ),
              ],
            ),
            AppGap.lg(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.bodyMedium(loc(context).enabled),
                AppSwitch(
                  identifier: 'static-route-enabled',
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
          child: Text(loc(context).cancel),
        ),
        FilledButton(
          onPressed: _isFormValid ? _submit : null,
          child: Text(_isEdit ? loc(context).save : loc(context).add),
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
