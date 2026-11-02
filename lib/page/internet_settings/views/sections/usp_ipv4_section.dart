import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/auto_ipoe_log_view.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_page_provider.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/auto_ipoe_section.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/auto_ipoe_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_connection_type_label.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_section_card.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_form_validator.dart';
import 'package:privacy_gui/page/internet_settings/views/helpers/wan_field_error_localization.dart';
import 'package:flutter/services.dart';
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
  late TextEditingController _serverAddressController;
  late TextEditingController _vlanIdController;
  late TextEditingController _idleTimeController;
  late TextEditingController _lcpEchoController;
  late TextEditingController _underlayIpController;
  late TextEditingController _underlayMaskController;
  late TextEditingController _underlayGatewayController;
  late TextEditingController _underlayDns1Controller;
  late TextEditingController _underlayDns2Controller;
  late TextEditingController _underlayDns3Controller;

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
    _serverAddressController = TextEditingController(text: form.serverAddress);
    _vlanIdController = TextEditingController(text: form.vlanId.toString());
    _idleTimeController =
        TextEditingController(text: form.idleDisconnectTime.toString());
    _lcpEchoController =
        TextEditingController(text: form.lcpEchoInterval.toString());
    _underlayIpController = TextEditingController(text: form.underlayIpAddress);
    _underlayMaskController =
        TextEditingController(text: form.underlaySubnetMask);
    _underlayGatewayController =
        TextEditingController(text: form.underlayGateway);
    _underlayDns1Controller = TextEditingController(text: form.underlayDns1);
    _underlayDns2Controller = TextEditingController(text: form.underlayDns2);
    _underlayDns3Controller = TextEditingController(text: form.underlayDns3);
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
    _syncIfDifferent(_serverAddressController, form.serverAddress);
    _syncIfDifferent(_vlanIdController, form.vlanId.toString());
    _syncIfDifferent(_idleTimeController, form.idleDisconnectTime.toString());
    _syncIfDifferent(_lcpEchoController, form.lcpEchoInterval.toString());
    _syncIfDifferent(_underlayIpController, form.underlayIpAddress);
    _syncIfDifferent(_underlayMaskController, form.underlaySubnetMask);
    _syncIfDifferent(_underlayGatewayController, form.underlayGateway);
    _syncIfDifferent(_underlayDns1Controller, form.underlayDns1);
    _syncIfDifferent(_underlayDns2Controller, form.underlayDns2);
    _syncIfDifferent(_underlayDns3Controller, form.underlayDns3);
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
    _serverAddressController.dispose();
    _vlanIdController.dispose();
    _idleTimeController.dispose();
    _lcpEchoController.dispose();
    _underlayIpController.dispose();
    _underlayMaskController.dispose();
    _underlayGatewayController.dispose();
    _underlayDns1Controller.dispose();
    _underlayDns2Controller.dispose();
    _underlayDns3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.state.edited;
    final supportsAutoIPoE =
        ref.watch(deviceCapabilitiesProvider).has(DeviceCapability.autoIPoE);
    final isEditing = widget.isEditing && !widget.state.status.isSaving;
    // Capability loss must not trap the user on an IPoE draft.
    final canEditFields = isEditing &&
        (form.connectionType != UspWanConnectionType.ipoe || supportsAutoIPoE);
    final ipoe = ref.watch(autoIPoEDataProvider).valueOrNull;
    final submission = ref.watch(autoIPoESubmissionProvider);
    final rejection = ref.watch(autoIPoERejectionProvider);
    final outcome = ipoe?.outcomeFor(submission) ?? AutoIPoEOutcome.idle;

    return UspSectionCard(
      title: loc(context).ipv4Connection,
      leadingIcon: Icons.language,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection type
          if (isEditing)
            AppDropdown<UspWanConnectionType>(
              identifier: 'internet-connection-type',
              itemIdentifier: _connectionTypeSlug,
              label: loc(context).connectionType,
              items: UspWanConnectionType.values
                  .where((type) =>
                      type != UspWanConnectionType.ipoe ||
                      (supportsAutoIPoE &&
                          (ipoe?.capabilities.isSupported == true ||
                              form.connectionType ==
                                  UspWanConnectionType.ipoe)))
                  .toList(),
              value: form.connectionType,
              itemAsString: (type) => type.localizedLabel(context),
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
              value: form.connectionType.localizedLabel(context),
            ),
          AppGap.md(),
          // Conditional fields based on connection type
          ..._buildTypeSpecificFields(form, canEditFields),
          if (ipoe != null && submission != null) ...[
            AppGap.md(),
            buildAutoIPoERuntime(
                context,
                ref,
                ipoe,
                rejection != null ? AutoIPoEOutcome.rejected : outcome,
                submission),
          ],
          if (ipoe != null &&
              form.connectionType == UspWanConnectionType.ipoe) ...[
            AppGap.md(),
            AutoIPoELogView(
                log: ipoe.log,
                onRefresh: () async =>
                    await ref.read(autoIPoEDataProvider.notifier).refresh() !=
                    null),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildTypeSpecificFields(
    UspInternetSettingsForm form,
    bool isEditing,
  ) {
    switch (form.connectionType) {
      case UspWanConnectionType.ipoe:
        final page = ref.watch(autoIPoEPageProvider);
        if (page.status.loading) return [const AppLoader()];
        return [
          AutoIPoESection(
              settings: page.current,
              status: page.status.snapshot.runtime,
              capabilities: page.status.snapshot.capabilities,
              isEditing:
                  isEditing && page.status.snapshot.capabilitiesAvailable,
              onChanged: ref.read(autoIPoEPageProvider.notifier).updateSettings)
        ];
      case UspWanConnectionType.dhcp:
        return [];
      case UspWanConnectionType.staticIp:
        return _buildStaticIpFields(form, isEditing);
      case UspWanConnectionType.pppoe:
        return _buildPppoeFields(form, isEditing);
      case UspWanConnectionType.pptp:
      case UspWanConnectionType.l2tp:
        return _buildTunnelFields(form, isEditing);
      case UspWanConnectionType.bridge:
        return _buildBridgeFields(isEditing);
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
    final errors = validateStaticIpv4(
      ipAddress: form.staticIpAddress,
      subnetMask: form.subnetMask,
      gateway: form.defaultGateway,
      dns1: form.dnsServer1,
      dns2: form.dnsServer2,
      dns3: form.dnsServer3,
    );
    String? error(String field) => wanFieldErrorText(context, errors[field]);
    return [
      AppTextFormField(
        controller: _ipController,
        label: l.ipAddress,
        hintText: '192.168.1.100',
        externalErrorText: error(StaticIpv4Field.ipAddress),
        onChanged: (v) => _updateField((f) => f.copyWith(staticIpAddress: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _subnetController,
        label: l.subnetMask,
        hintText: '255.255.255.0',
        externalErrorText: error(StaticIpv4Field.subnetMask),
        onChanged: (v) => _updateField((f) => f.copyWith(subnetMask: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _gatewayController,
        label: l.defaultGateway,
        hintText: '192.168.1.1',
        externalErrorText: error(StaticIpv4Field.gateway),
        onChanged: (v) => _updateField((f) => f.copyWith(defaultGateway: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _dns1Controller,
        label: l.dns1,
        hintText: '8.8.8.8',
        externalErrorText: error(StaticIpv4Field.dns1),
        onChanged: (v) => _updateField((f) => f.copyWith(dnsServer1: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _dns2Controller,
        label: l.dns2Optional,
        hintText: '8.8.4.4',
        externalErrorText: error(StaticIpv4Field.dns2),
        onChanged: (v) => _updateField((f) => f.copyWith(dnsServer2: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _dns3Controller,
        label: l.dns3Optional,
        externalErrorText: error(StaticIpv4Field.dns3),
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
      ..._credentialFields(form),
      AppGap.md(),
      AppTextFormField(
        controller: _pppServiceNameController,
        label: l.serviceNameOptional,
        onChanged: (v) => _updateField((f) => f.copyWith(pppoeServiceName: v)),
      ),
      AppGap.lg(),
      ..._connectionModeFields(form),
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

  List<Widget> _buildTunnelFields(
      UspInternetSettingsForm form, bool isEditing) {
    final l = loc(context);
    final typeName =
        form.connectionType == UspWanConnectionType.pptp ? 'PPTP' : 'L2TP';
    final isPptp = form.connectionType == UspWanConnectionType.pptp;
    if (!isEditing) {
      return [
        UspInfoRow(label: '$typeName Server', value: form.serverAddress),
        if (isPptp && form.underlayStatic) ..._underlayInfoRows(form),
        UspInfoRow(label: l.username, value: form.pppUsername),
        UspInfoRow(label: l.connectionMode, value: form.connectionTrigger),
        UspInfoRow(label: l.pppStatus, value: widget.state.pppConnectionStatus),
        if (form.vlanEnabled)
          UspInfoRow(label: l.vlanIdOptional, value: '${form.vlanId}'),
      ];
    }
    return [
      AppTextFormField(
        controller: _serverAddressController,
        identifier: 'internet-tunnel-server',
        label: '$typeName Server',
        hintText: '203.0.113.1',
        externalErrorText: wanFieldErrorText(
            context, validateTunnelServer(form.serverAddress)),
        onChanged: (v) => _updateField((f) => f.copyWith(serverAddress: v)),
      ),
      // 1.0 offers the static underlay for PPTP only.
      if (isPptp) ...[
        AppGap.md(),
        ..._underlayFields(form),
      ],
      AppGap.md(),
      ..._credentialFields(form),
      AppGap.lg(),
      ..._connectionModeFields(form),
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

  /// The PPP user name and password, each at most 255 characters.
  List<Widget> _credentialFields(UspInternetSettingsForm form) {
    final l = loc(context);
    return [
      AppTextFormField(
        controller: _pppUsernameController,
        label: l.username,
        externalErrorText: _credentialError(form.pppUsername),
        onChanged: (v) => _updateField((f) => f.copyWith(pppUsername: v)),
      ),
      AppGap.md(),
      AppTextFormField(
        controller: _pppPasswordController,
        label: l.password,
        obscureText: true,
        externalErrorText: _credentialError(form.pppPassword),
        onChanged: (v) => _updateField((f) => f.copyWith(pppPassword: v)),
      ),
    ];
  }

  String? _credentialError(String value) =>
      wanFieldErrorText(context, validatePppCredential(value),
          max: kPppCredentialMaxLength);

  /// Keep Alive with its "reconnect after" interval, or On Demand with its
  /// idle time in minutes — 1.0's PPP connection modes.
  List<Widget> _connectionModeFields(UspInternetSettingsForm form) {
    final l = loc(context);
    return [
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
      if (form.connectionTrigger == 'OnDemand')
        AppTextFormField(
          controller: _idleTimeController,
          identifier: 'internet-max-idle-time',
          label: l.maxIdleTime,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          externalErrorText: wanFieldErrorText(
              context, validateIdleMinutes(form.idleDisconnectTime),
              min: kPppIdleMinutesMin, max: kPppIdleMinutesMax),
          onChanged: (v) => _updateField(
              (f) => f.copyWith(idleDisconnectTime: int.tryParse(v) ?? 0)),
        )
      else
        AppTextFormField(
          controller: _lcpEchoController,
          identifier: 'internet-keep-alive-interval',
          label: l.lcpEchoInterval,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          externalErrorText: wanFieldErrorText(
              context, validateKeepAliveInterval(form.lcpEchoInterval),
              min: kPppKeepAliveSecondsMin, max: kPppKeepAliveSecondsMax),
          onChanged: (v) => _updateField(
              (f) => f.copyWith(lcpEchoInterval: int.tryParse(v) ?? 0)),
        ),
      AppGap.md(),
    ];
  }

  /// PPTP's static underlay (1.0 useStaticSettings): a switch, and when on the
  /// address set of the WAN port under the tunnel, checked as a Static WAN.
  List<Widget> _underlayFields(UspInternetSettingsForm form) {
    final l = loc(context);
    final errors =
        form.underlayStatic ? validateUnderlay(form) : const <String, String>{};
    String? error(String field) => wanFieldErrorText(context, errors[field]);
    return [
      Row(
        children: [
          AppText.labelLarge(l.staticIp),
          const Spacer(),
          AppSwitch(
            identifier: 'internet-underlay-static',
            value: form.underlayStatic,
            onChanged: (v) =>
                _updateField((f) => f.copyWith(underlayStatic: v)),
          ),
        ],
      ),
      if (form.underlayStatic) ...[
        AppGap.md(),
        AppTextFormField(
          controller: _underlayIpController,
          identifier: 'internet-underlay-ip',
          label: l.ipAddress,
          hintText: '198.51.100.10',
          externalErrorText: error(StaticIpv4Field.ipAddress),
          onChanged: (v) =>
              _updateField((f) => f.copyWith(underlayIpAddress: v)),
        ),
        AppGap.md(),
        AppTextFormField(
          controller: _underlayMaskController,
          identifier: 'internet-underlay-mask',
          label: l.subnetMask,
          hintText: '255.255.255.0',
          externalErrorText: error(StaticIpv4Field.subnetMask),
          onChanged: (v) =>
              _updateField((f) => f.copyWith(underlaySubnetMask: v)),
        ),
        AppGap.md(),
        AppTextFormField(
          controller: _underlayGatewayController,
          identifier: 'internet-underlay-gateway',
          label: l.defaultGateway,
          hintText: '198.51.100.1',
          externalErrorText: error(StaticIpv4Field.gateway),
          onChanged: (v) => _updateField((f) => f.copyWith(underlayGateway: v)),
        ),
        AppGap.md(),
        AppTextFormField(
          controller: _underlayDns1Controller,
          identifier: 'internet-underlay-dns1',
          label: l.dns1,
          hintText: '8.8.8.8',
          externalErrorText: error(StaticIpv4Field.dns1),
          onChanged: (v) => _updateField((f) => f.copyWith(underlayDns1: v)),
        ),
        AppGap.md(),
        AppTextFormField(
          controller: _underlayDns2Controller,
          identifier: 'internet-underlay-dns2',
          label: l.dns2Optional,
          externalErrorText: error(StaticIpv4Field.dns2),
          onChanged: (v) => _updateField((f) => f.copyWith(underlayDns2: v)),
        ),
        AppGap.md(),
        AppTextFormField(
          controller: _underlayDns3Controller,
          identifier: 'internet-underlay-dns3',
          label: l.dns3Optional,
          externalErrorText: error(StaticIpv4Field.dns3),
          onChanged: (v) => _updateField((f) => f.copyWith(underlayDns3: v)),
        ),
      ],
    ];
  }

  List<Widget> _underlayInfoRows(UspInternetSettingsForm form) {
    final l = loc(context);
    return [
      UspInfoRow(label: l.ipAddress, value: form.underlayIpAddress),
      UspInfoRow(label: l.subnetMask, value: form.underlaySubnetMask),
      UspInfoRow(label: l.defaultGateway, value: form.underlayGateway),
      UspInfoRow(label: l.dns1, value: form.underlayDns1),
      if (form.underlayDns2.isNotEmpty)
        UspInfoRow(label: l.dns2Optional, value: form.underlayDns2),
      if (form.underlayDns3.isNotEmpty)
        UspInfoRow(label: l.dns3Optional, value: form.underlayDns3),
    ];
  }

  List<Widget> _buildBridgeFields(bool isEditing) {
    final l = loc(context);
    final hostName = widget.state.readOnlyInfo.hostName;
    final showHint = isEditing && hostName.isNotEmpty;
    return [
      AppGap.md(),
      AppText.bodyMedium(l.bridgeModeWarning),
      if (showHint) ...[
        AppGap.md(),
        AppText(
          l.bridgeReconnectHint('https://$hostName.local'),
          variant: AppTextVariant.bodyMedium,
          fontWeight: FontWeight.bold,
        ),
      ],
    ];
  }

  void _updateField(
      UspInternetSettingsForm Function(UspInternetSettingsForm) updater) {
    ref.read(uspInternetSettingsProvider.notifier).updateField(updater);
  }
}

/// Builds the E2E test-hook identifier for each connection-type option.
///
/// The enum member name is used verbatim by Dart, so `staticIp` would emit a
/// mixed-case slug. The E2E identifier generator only accepts all-lowercase
/// kebab hooks (`PrivacyGUI-USP-E2E/scripts/gen-identifiers.mts` STATIC_RE:
/// `/^[a-z0-9]+(?:-[a-z0-9]+)+$/`) and silently drops anything else, so a
/// non-normalised `staticIp` hook would never reach `identifiers.generated.ts`.
/// This normalises camelCase to kebab and prefixes the page/control anchor
/// (`internet-connection-type-`) per `constitution.md:1529`
/// (`{page}-{control}[-{instance-key}]`). Do NOT "simplify" this back to
/// `type.name` — it will break the Static IP hook.
String _connectionTypeSlug(UspWanConnectionType type) =>
    'internet-connection-type-'
    '${type.name.replaceAllMapped(RegExp(r'(?<=[a-z0-9])([A-Z])'), (m) => '-${m[1]!.toLowerCase()}').toLowerCase()}';
