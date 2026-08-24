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
  // Focus node for the (plain-text) name field. Validation runs on focus-loss,
  // not on every keystroke: assigning _errors in onChanged calls setState →
  // rebuild → the CanvasKit <input> is torn down mid-edit, dropping focus and
  // the value being typed (#1332). The three IPv4 fields use AppIpv4TextField's
  // own onFocusChanged callback (_onIpv4FocusChanged) for the same purpose.
  // (Same focus-loss pattern as port_forwarding_dialog / usp_local_network_view.)
  final _nameFocus = FocusNode();
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
    // Validate the name field when it loses focus (updates the shown errorText)
    // instead of on every keystroke.
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus && mounted) _validate();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destIpController.dispose();
    _subnetMaskController.dispose();
    _gatewayController.dispose();
    _nameFocus.dispose();
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

  /// Rebuild to re-evaluate the Add-button enable state (_isFormValid) WITHOUT
  /// surfacing errors mid-edit. Error text is refreshed on focus-loss (via
  /// _nameFocus / _onIpv4FocusChanged), so it must NOT be assigned here:
  /// assigning _errors in onChanged → setState → rebuild tears down the
  /// CanvasKit <input> mid-edit and drops the keystroke (#1332).
  void _onInputChanged() {
    setState(() {});
  }

  /// Validate when focus leaves the entire IPv4 field (not per segment).
  void _onIpv4FocusChanged(int? index, bool hasFocus) {
    if (index == null && !hasFocus && mounted) _validate();
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
              focusNode: _nameFocus,
              identifier: 'static-route-name',
              hintText: loc(context).routeName,
              errorText: _localizeError(_errors['name']),
              onChanged: (_) => _onInputChanged(),
            ),
            AppGap.lg(),
            AppIpv4TextField(
              controller: _destIpController,
              identifier: 'static-route-dest-ip',
              label: loc(context).destinationIp,
              errorText: _localizeError(_errors['destIp']),
              onChanged: (_) => _onInputChanged(),
              onFocusChanged: _onIpv4FocusChanged,
            ),
            AppGap.lg(),
            AppIpv4TextField(
              controller: _subnetMaskController,
              identifier: 'static-route-subnet-mask',
              label: loc(context).subnetMask,
              errorText: _localizeError(_errors['subnetMask']),
              onChanged: (_) => _onInputChanged(),
              onFocusChanged: _onIpv4FocusChanged,
            ),
            AppGap.lg(),
            AppIpv4TextField(
              controller: _gatewayController,
              identifier: 'static-route-gateway',
              label: loc(context).gatewayIp,
              errorText: _localizeError(_errors['gateway']),
              onChanged: (_) => _onInputChanged(),
              onFocusChanged: _onIpv4FocusChanged,
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
        AppButton.text(
          identifier: 'static-route-cancel',
          label: loc(context).cancel,
          onTap: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          identifier: 'static-route-submit',
          label: _isEdit ? loc(context).save : loc(context).add,
          onTap: _isFormValid ? _submit : null,
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
