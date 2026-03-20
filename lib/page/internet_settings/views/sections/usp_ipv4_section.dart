import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// IPv4 connection settings section.
///
/// Displays connection type selector and conditional fields based on type:
/// - DHCP: no extra fields
/// - Static IP: IP, subnet, gateway, DNS 1-3
/// - PPPoE: username, password, service name, connection mode, VLAN
/// - Bridge: warning message
class UspIpv4Section extends ConsumerStatefulWidget {
  final InternetSettingsFeatureState state;
  final bool isEditing;

  const UspIpv4Section({
    super.key,
    required this.state,
    required this.isEditing,
  });

  @override
  ConsumerState<UspIpv4Section> createState() => _UspIpv4SectionState();
}

class _UspIpv4SectionState extends ConsumerState<UspIpv4Section> {
  late TextEditingController _ipController;
  late TextEditingController _subnetController;
  late TextEditingController _gatewayController;
  late TextEditingController _dns1Controller;
  late TextEditingController _dns2Controller;
  late TextEditingController _dns3Controller;
  late TextEditingController _pppUsernameController;
  late TextEditingController _pppPasswordController;
  late TextEditingController _pppServiceNameController;
  late TextEditingController _vlanIdController;
  late TextEditingController _idleTimeController;
  late TextEditingController _lcpEchoController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final form = widget.state.edited;
    _ipController = TextEditingController(text: form.staticIpAddress);
    _subnetController = TextEditingController(text: form.subnetMask);
    _gatewayController = TextEditingController(text: form.defaultGateway);
    _dns1Controller = TextEditingController(text: form.dnsServer1);
    _dns2Controller = TextEditingController(text: form.dnsServer2);
    _dns3Controller = TextEditingController(text: form.dnsServer3);
    _pppUsernameController = TextEditingController(text: form.pppUsername);
    _pppPasswordController = TextEditingController(text: form.pppPassword);
    _pppServiceNameController =
        TextEditingController(text: form.pppoeServiceName);
    _vlanIdController = TextEditingController(text: form.vlanId.toString());
    _idleTimeController =
        TextEditingController(text: form.idleDisconnectTime.toString());
    _lcpEchoController =
        TextEditingController(text: form.lcpEchoInterval.toString());
  }

  @override
  void didUpdateWidget(covariant UspIpv4Section oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.edited != widget.state.edited) {
      _syncControllers();
    }
  }

  void _syncControllers() {
    final form = widget.state.edited;
    _syncIfDifferent(_ipController, form.staticIpAddress);
    _syncIfDifferent(_subnetController, form.subnetMask);
    _syncIfDifferent(_gatewayController, form.defaultGateway);
    _syncIfDifferent(_dns1Controller, form.dnsServer1);
    _syncIfDifferent(_dns2Controller, form.dnsServer2);
    _syncIfDifferent(_dns3Controller, form.dnsServer3);
    _syncIfDifferent(_pppUsernameController, form.pppUsername);
    _syncIfDifferent(_pppPasswordController, form.pppPassword);
    _syncIfDifferent(_pppServiceNameController, form.pppoeServiceName);
    _syncIfDifferent(_vlanIdController, form.vlanId.toString());
    _syncIfDifferent(_idleTimeController, form.idleDisconnectTime.toString());
    _syncIfDifferent(_lcpEchoController, form.lcpEchoInterval.toString());
  }

  void _syncIfDifferent(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.text = value;
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _subnetController.dispose();
    _gatewayController.dispose();
    _dns1Controller.dispose();
    _dns2Controller.dispose();
    _dns3Controller.dispose();
    _pppUsernameController.dispose();
    _pppPasswordController.dispose();
    _pppServiceNameController.dispose();
    _vlanIdController.dispose();
    _idleTimeController.dispose();
    _lcpEchoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.state.edited;
    final isEditing = widget.isEditing;

    return UspSectionCard(
      title: loc(context).ipv4Connection,
      leadingIcon: Icons.language,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection type
          if (isEditing)
            AppDropdown<UspWanConnectionType>(
              label: loc(context).connectionType,
              items: UspWanConnectionType.values,
              value: form.connectionType,
              itemAsString: (type) => _connectionTypeLabel(context, type),
              onChanged: (type) {
                if (type != null) {
                  ref
                      .read(uspInternetSettingsProvider.notifier)
                      .updateConnectionType(type);
                }
              },
            )
          else
            UspInfoRow(
              label: loc(context).connectionType,
              value: _connectionTypeLabel(context, form.connectionType),
            ),
          AppGap.md(),
          // Conditional fields based on connection type
          ..._buildTypeSpecificFields(form, isEditing),
        ],
      ),
    );
  }

  List<Widget> _buildTypeSpecificFields(
    UspInternetSettingsForm form,
    bool isEditing,
  ) {
    switch (form.connectionType) {
      case UspWanConnectionType.dhcp:
        return [];
      case UspWanConnectionType.staticIp:
        return _buildStaticIpFields(form, isEditing);
      case UspWanConnectionType.pppoe:
        return _buildPppoeFields(form, isEditing);
      case UspWanConnectionType.bridge:
        return _buildBridgeFields();
    }
  }

  List<Widget> _buildStaticIpFields(
      UspInternetSettingsForm form, bool isEditing) {
    final l = loc(context);
    if (!isEditing) {
      return [
        UspInfoRow(label: l.ipAddress, value: form.staticIpAddress),
        UspInfoRow(label: l.subnetMask, value: form.subnetMask),
        UspInfoRow(label: l.defaultGateway, value: form.defaultGateway),
        UspInfoRow(label: l.dns1, value: form.dnsServer1),
        if (form.dnsServer2.isNotEmpty)
          UspInfoRow(label: l.dns2Optional, value: form.dnsServer2),
        if (form.dnsServer3.isNotEmpty)
          UspInfoRow(label: l.dns3Optional, value: form.dnsServer3),
      ];
    }
    return [
      AppTextFormField(
        controller: _ipController,
        label: l.ipAddress,
        hintText: '192.168.1.100',
        onChanged: (v) => _updateField((f) => f.copyWith(staticIpAddress: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _subnetController,
        label: l.subnetMask,
        hintText: '255.255.255.0',
        onChanged: (v) => _updateField((f) => f.copyWith(subnetMask: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _gatewayController,
        label: l.defaultGateway,
        hintText: '192.168.1.1',
        onChanged: (v) => _updateField((f) => f.copyWith(defaultGateway: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _dns1Controller,
        label: l.dns1,
        hintText: '8.8.8.8',
        onChanged: (v) => _updateField((f) => f.copyWith(dnsServer1: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _dns2Controller,
        label: l.dns2Optional,
        hintText: '8.8.4.4',
        onChanged: (v) => _updateField((f) => f.copyWith(dnsServer2: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _dns3Controller,
        label: l.dns3Optional,
        onChanged: (v) => _updateField((f) => f.copyWith(dnsServer3: v)),
      ),
    ];
  }

  List<Widget> _buildPppoeFields(UspInternetSettingsForm form, bool isEditing) {
    final l = loc(context);
    if (!isEditing) {
      return [
        UspInfoRow(label: l.username, value: form.pppUsername),
        UspInfoRow(label: l.serviceName, value: form.pppoeServiceName),
        UspInfoRow(label: l.connectionMode, value: form.connectionTrigger),
        UspInfoRow(label: l.pppStatus, value: widget.state.pppConnectionStatus),
        if (form.vlanEnabled)
          UspInfoRow(label: l.vlanIdOptional, value: '${form.vlanId}'),
      ];
    }
    return [
      AppTextFormField(
        controller: _pppUsernameController,
        label: l.username,
        onChanged: (v) => _updateField((f) => f.copyWith(pppUsername: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _pppPasswordController,
        label: l.password,
        obscureText: true,
        onChanged: (v) => _updateField((f) => f.copyWith(pppPassword: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _pppServiceNameController,
        label: l.serviceNameOptional,
        onChanged: (v) => _updateField((f) => f.copyWith(pppoeServiceName: v)),
      ),
      AppGap.lg(),
      // Connection mode
      AppText.labelLarge(l.connectionMode),
      AppGap.sm(),
      AppRadioList<String>(
        items: [
          AppRadioListItem(title: l.keepAlive, value: 'AlwaysOn'),
          AppRadioListItem(title: l.connectOnDemand, value: 'OnDemand'),
        ],
        selected: form.connectionTrigger,
        onChanged: (_, v) {
          if (v != null) {
            _updateField((f) => f.copyWith(connectionTrigger: v));
          }
        },
      ),
      AppGap.md(),
      if (form.connectionTrigger == 'OnDemand') ...[
        AppTextFormField(
          controller: _idleTimeController,
          label: l.maxIdleTime,
          keyboardType: TextInputType.number,
          onChanged: (v) => _updateField(
              (f) => f.copyWith(idleDisconnectTime: int.tryParse(v) ?? 0)),
        ),
        AppGap.md(),
      ],
      if (form.connectionTrigger == 'AlwaysOn') ...[
        AppTextFormField(
          controller: _lcpEchoController,
          label: l.lcpEchoInterval,
          keyboardType: TextInputType.number,
          onChanged: (v) => _updateField(
              (f) => f.copyWith(lcpEchoInterval: int.tryParse(v) ?? 0)),
        ),
        AppGap.md(),
      ],
      // VLAN
      AppGap.md(),
      Row(
        children: [
          AppText.labelLarge(l.vlanTagging),
          const Spacer(),
          AppSwitch(
            value: form.vlanEnabled,
            onChanged: (v) => _updateField((f) => f.copyWith(vlanEnabled: v)),
          ),
        ],
      ),
      if (form.vlanEnabled) ...[
        AppGap.md(),
        AppTextFormField(
          controller: _vlanIdController,
          label: l.vlanIdOptional,
          keyboardType: TextInputType.number,
          onChanged: (v) =>
              _updateField((f) => f.copyWith(vlanId: int.tryParse(v) ?? 0)),
        ),
      ],
    ];
  }

  List<Widget> _buildBridgeFields() {
    return [
      AppGap.md(),
      AppText.bodyMedium(loc(context).bridgeModeWarning),
    ];
  }

  String _connectionTypeLabel(BuildContext context, UspWanConnectionType type) {
    final l = loc(context);
    return switch (type) {
      UspWanConnectionType.dhcp => l.connectionTypeDhcp,
      UspWanConnectionType.staticIp => l.connectionTypeStatic,
      UspWanConnectionType.pppoe => l.connectionTypePppoe,
      UspWanConnectionType.bridge => l.connectionTypeBridge,
    };
  }

  void _updateField(
      UspInternetSettingsForm Function(UspInternetSettingsForm) updater) {
    ref.read(uspInternetSettingsProvider.notifier).updateField(updater);
  }
}
