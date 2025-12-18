import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/widgets/protocol_utils.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';


class Ipv6PortServiceListView extends ArgumentsConsumerStatefulView {
  const Ipv6PortServiceListView({super.key, super.args});

  @override
  ConsumerState<Ipv6PortServiceListView> createState() =>
      _Ipv6PortServiceListViewState();
}

class _Ipv6PortServiceListViewState
    extends ConsumerState<Ipv6PortServiceListView> {
  late final Ipv6PortServiceListNotifier _notifier;

  // Controllers for edit mode
  final TextEditingController _applicationTextController =
      TextEditingController();
  final TextEditingController _firstPortTextController =
      TextEditingController();
  final TextEditingController _lastPortTextController = TextEditingController();
  final TextEditingController _ipAddressTextController =
      TextEditingController();

  // Validation state
  String? _nameError;
  String? _ipError;
  String? _portRangeError;

  // Track which rule is being edited to avoid reinitializing controllers
  IPv6FirewallRule? _editingRule;
  bool _isInitializing = false;
  StateSetter? _sheetStateSetter;

  @override
  void initState() {
    _notifier = ref.read(ipv6PortServiceListProvider.notifier);
    _applicationTextController.addListener(_onApplicationNameChanged);
    _firstPortTextController.addListener(_onStartPortChanged);
    _lastPortTextController.addListener(_onEndPortChanged);
    super.initState();
  }

  @override
  void dispose() {
    _applicationTextController.removeListener(_onApplicationNameChanged);
    _firstPortTextController.removeListener(_onStartPortChanged);
    _lastPortTextController.removeListener(_onEndPortChanged);
    _applicationTextController.dispose();
    _firstPortTextController.dispose();
    _lastPortTextController.dispose();
    _ipAddressTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ipv6PortServiceListProvider);
    final isAddEnabled = !_notifier.isExceedMax();

    return AppDataTable<IPv6FirewallRule>(
      data: state.current.rules,
      columns: _buildColumns(context),
      totalRows: state.current.rules.length,
      currentPage: 1,
      rowsPerPage: 50,
      onPageChanged: (_) {},
      onSave: _handleSave,
      emptyMessage: loc(context).noIPv6PortService,
      // New Add Row API
      showAddButton: isAddEnabled,
      onCreateTemplate: () => IPv6FirewallRule(
        isEnabled: true,
        description: '',
        ipv6Address: '',
        portRanges: [PortRange(protocol: 'Both', firstPort: 0, lastPort: 0)],
      ),
      onAdd: _handleAdd,
      onDelete: _handleDelete,
      onCancel: _handleCancel,
      localization: AppTableLocalization(
        edit: loc(context).edit,
        save: loc(context).save,
        delete: loc(context).delete,
        cancel: loc(context).cancel,
        actions: loc(context).action,
        add: loc(context).add,
      ),
    );
  }

  void _handleCancel() {
    _editingRule = null;
    _sheetStateSetter = null;
    _clearControllers();
  }

  Future<bool> _handleDelete(IPv6FirewallRule rule) async {
    _notifier.deleteRule(rule);
    _clearControllers();
    return true;
  }

  List<AppTableColumn<IPv6FirewallRule>> _buildColumns(BuildContext context) {
    return [
      // Column 0: Application Name
      AppTableColumn<IPv6FirewallRule>(
        label: loc(context).applicationName,
        cellBuilder: (_, rule) => Text(rule.description),
        editBuilder: (_, rule, setSheetState) {
          // Store the sheet's StateSetter for validation updates
          _sheetStateSetter = setSheetState;
          // Only initialize when starting to edit a new rule
          if (_editingRule != rule) {
            _isInitializing = true;
            try {
              _editingRule = rule;
              _applicationTextController.text = rule.description;
              _firstPortTextController.text =
                  '${rule.portRanges.firstOrNull?.firstPort ?? 0}';
              _lastPortTextController.text =
                  '${rule.portRanges.firstOrNull?.lastPort ?? 0}';
              _ipAddressTextController.text = rule.ipv6Address;
              _nameError = null;
              _portRangeError = null;
            } finally {
              _isInitializing = false;
            }
          }
          return AppTextField(
            key: ValueKey('appName_${identityHashCode(rule)}'),
            controller: _applicationTextController,
            hintText: loc(context).applicationName,
            errorText: _nameError,
          );
        },
      ),

      // Column 1: Protocol
      AppTableColumn<IPv6FirewallRule>(
        label: loc(context).protocol,
        cellBuilder: (_, rule) => Text(
          getProtocolTitle(
              context, rule.portRanges.firstOrNull?.protocol ?? 'Both'),
        ),
        editBuilder: (_, rule, setSheetState) {
          final currentProtocol =
              rule.portRanges.firstOrNull?.protocol ?? 'Both';
          // Map protocol values to display names
          final protocolDisplayMap = {
            'TCP': getProtocolTitle(context, 'TCP'),
            'UDP': getProtocolTitle(context, 'UDP'),
            'Both': getProtocolTitle(context, 'Both'),
          };
          return AppDropdown<String>(
            key: ValueKey('protocol_${identityHashCode(rule)}'),
            items: protocolDisplayMap.values.toList(),
            value: protocolDisplayMap[currentProtocol],
            hint: loc(context).protocol,
            onChanged: (displayValue) {
              if (displayValue != null) {
                // Reverse map: find protocol key by display value
                final protocolKey = protocolDisplayMap.entries
                    .firstWhere((e) => e.value == displayValue,
                        orElse: () => const MapEntry('Both', 'Both'))
                    .key;
                _updateProtocol(protocolKey);
              }
            },
          );
        },
      ),

      // Column 2: Device IP (IPv6)
      AppTableColumn<IPv6FirewallRule>(
        label: loc(context).deviceIP,
        cellBuilder: (_, rule) => Text(rule.ipv6Address),
        editBuilder: (_, rule, setSheetState) {
          // Controller is initialized in column 0's editBuilder
          return Row(
            children: [
              Expanded(
                child: AppIPv6TextField(
                  key: ValueKey('ip_${identityHashCode(rule)}'),
                  label: loc(context).ipAddress,
                  controller: _ipAddressTextController,
                  invalidFormatMessage: loc(context).invalidIpAddress,
                  errorText: _ipError,
                  onChanged: (value) {
                    _updateIpAddress(value);
                    _validateAll();
                  },
                ),
              ),
              AppGap.sm(),
              AppIconButton(
                icon: Icon(AppFontIcons.devices),
                onTap: () => _openDevicePicker(context),
              ),
            ],
          );
        },
      ),

      // Column 3: Start/End Ports
      AppTableColumn<IPv6FirewallRule>(
        label: loc(context).startEndPorts,
        cellBuilder: (_, rule) => Text(
          '${rule.portRanges.firstOrNull?.firstPort ?? 0} ${loc(context).to} ${rule.portRanges.firstOrNull?.lastPort ?? 0}',
        ),
        editBuilder: (_, rule, setSheetState) {
          // Controllers are initialized in column 0's editBuilder
          return AppRangeInput(
            key: ValueKey('range_${identityHashCode(rule)}'),
            startController: _firstPortTextController,
            endController: _lastPortTextController,
            startLabel: loc(context).startPort,
            endLabel: loc(context).endPort,
            errorText: _portRangeError,
          );
        },
      ),
    ];
  }

  // --- Update Methods ---

  void _updateRuleName(String value) {
    final ruleNotifier = ref.read(ipv6PortServiceRuleProvider.notifier);
    final currentRule = ref.read(ipv6PortServiceRuleProvider).rule;
    ruleNotifier.updateRule(currentRule?.copyWith(description: value));
  }

  void _updateProtocol(String value) {
    final ruleNotifier = ref.read(ipv6PortServiceRuleProvider.notifier);
    final currentRule = ref.read(ipv6PortServiceRuleProvider).rule;
    final portRanges = currentRule?.portRanges ?? [];
    final portRange = portRanges.firstOrNull;
    ruleNotifier.updateRule(
      currentRule?.copyWith(
        portRanges:
            portRange == null ? null : [portRange.copyWith(protocol: value)],
      ),
    );
  }

  void _updateIpAddress(String value) {
    final ruleNotifier = ref.read(ipv6PortServiceRuleProvider.notifier);
    final currentRule = ref.read(ipv6PortServiceRuleProvider).rule;
    ruleNotifier.updateRule(currentRule?.copyWith(ipv6Address: value));
  }

  void _updateFirstPort(String value) {
    final ruleNotifier = ref.read(ipv6PortServiceRuleProvider.notifier);
    final currentRule = ref.read(ipv6PortServiceRuleProvider).rule;
    final portRanges = currentRule?.portRanges ?? [];
    final portRange = portRanges.firstOrNull;
    ruleNotifier.updateRule(
      currentRule?.copyWith(
        portRanges: portRange == null
            ? null
            : [portRange.copyWith(firstPort: int.tryParse(value) ?? 0)],
      ),
    );
  }

  void _updateLastPort(String value) {
    final ruleNotifier = ref.read(ipv6PortServiceRuleProvider.notifier);
    final currentRule = ref.read(ipv6PortServiceRuleProvider).rule;
    final portRanges = currentRule?.portRanges ?? [];
    final portRange = portRanges.firstOrNull;
    ruleNotifier.updateRule(
      currentRule?.copyWith(
        portRanges: portRange == null
            ? null
            : [portRange.copyWith(lastPort: int.tryParse(value) ?? 0)],
      ),
    );
  }

  // --- Validation ---

  void _onApplicationNameChanged() {
    if (_isInitializing) return;
    _updateRuleName(_applicationTextController.text);
    _validateAll();
  }

  void _onStartPortChanged() {
    if (_isInitializing) return;
    _updateFirstPort(_firstPortTextController.text);
    _validateAll();
  }

  void _onEndPortChanged() {
    if (_isInitializing) return;
    _updateLastPort(_lastPortTextController.text);
    _validateAll();
  }

  void _validateAll() {
    final ruleNotifier = ref.read(ipv6PortServiceRuleProvider.notifier);
    final ruleState = ref.read(ipv6PortServiceRuleProvider);

    setState(() {
      // Validate rule name
      _nameError =
          ruleNotifier.isRuleNameValidate(_applicationTextController.text)
              ? null
              : loc(context).notBeEmptyAndLessThanThirtyThree;

      // Validate IPv6 address
      _ipError = ruleNotifier.isDeviceIpValidate(_ipAddressTextController.text)
          ? null
          : loc(context).invalidIpAddress;

      // Validate port range
      final firstPortText = _firstPortTextController.text;
      final lastPortText = _lastPortTextController.text;

      if (firstPortText.isEmpty || lastPortText.isEmpty) {
        _portRangeError = loc(context).portRangeError;
      } else {
        final firstPort = int.tryParse(firstPortText) ?? 0;
        final lastPort = int.tryParse(lastPortText) ?? 0;
        final protocol =
            ruleState.rule?.portRanges.firstOrNull?.protocol ?? 'Both';

        if (!ruleNotifier.isPortRangeValid(firstPort, lastPort)) {
          _portRangeError = loc(context).portRangeError;
        } else if (ruleNotifier.isPortConflict(firstPort, lastPort, protocol)) {
          _portRangeError = loc(context).rulesOverlapError;
        } else {
          _portRangeError = null;
        }
      }
    });
    // Also update bottom sheet state if available (for mobile)
    _sheetStateSetter?.call(() {});
  }

  void _clearControllers() {
    _applicationTextController.clear();
    _firstPortTextController.clear();
    _lastPortTextController.clear();
    _ipAddressTextController.clear();
    _nameError = null;
    _ipError = null;
    _portRangeError = null;
    setState(() {});
  }

  // --- Device Picker ---

  Future<void> _openDevicePicker(BuildContext context) async {
    final result = await context.pushNamed<List<DeviceListItem>?>(
      RouteNamed.devicePicker,
      extra: {'type': 'ipv6', 'selectMode': 'single'},
    );
    if (result != null && result.isNotEmpty) {
      final selectedIpv6Address = result.first.ipv6Address;
      _ipAddressTextController.text = selectedIpv6Address;
      _updateIpAddress(selectedIpv6Address);
      _validateAll();
    }
  }

  Future<bool> _handleAdd(IPv6FirewallRule templateRule) async {
    // Validate before saving
    _validateAll();
    if (!_isValid()) {
      return false; // Don't add if validation fails
    }

    // Build new rule from controller values
    final newRule = _buildRuleFromControllers(templateRule);
    _notifier.addRule(newRule);

    // Clear editing state
    _editingRule = null;
    _clearControllers();
    return true;
  }

  // --- Save Handler ---

  Future<bool> _handleSave(IPv6FirewallRule originalRule) async {
    // Validate before saving
    _validateAll();
    if (!_isValid()) {
      return false; // Don't save if validation fails
    }

    // Build edited rule from controller values
    final editedRule = _buildRuleFromControllers(originalRule);

    // Find index of original rule in the list
    final state = ref.read(ipv6PortServiceListProvider);
    final index = state.current.rules.indexOf(originalRule);

    if (index >= 0) {
      // Edit existing rule
      _notifier.editRule(index, editedRule);
    }

    // Clear editing state
    _editingRule = null;
    _clearControllers();
    return true;
  }

  /// Check if current form state is valid
  bool _isValid() {
    final ruleNotifier = ref.read(ipv6PortServiceRuleProvider.notifier);

    // Check name
    if (!ruleNotifier.isRuleNameValidate(_applicationTextController.text)) {
      return false;
    }

    // Check IPv6 address
    if (!ruleNotifier.isDeviceIpValidate(_ipAddressTextController.text)) {
      return false;
    }

    // Check port range
    if (_firstPortTextController.text.isEmpty ||
        _lastPortTextController.text.isEmpty) {
      return false;
    }
    final firstPort = int.tryParse(_firstPortTextController.text) ?? 0;
    final lastPort = int.tryParse(_lastPortTextController.text) ?? 0;
    if (!ruleNotifier.isPortRangeValid(firstPort, lastPort)) {
      return false;
    }

    return true;
  }

  /// Build a new rule from controller values
  IPv6FirewallRule _buildRuleFromControllers(IPv6FirewallRule template) {
    final firstPort = int.tryParse(_firstPortTextController.text) ?? 0;
    final lastPort = int.tryParse(_lastPortTextController.text) ?? 0;

    return template.copyWith(
      description: _applicationTextController.text,
      ipv6Address: _ipAddressTextController.text,
      portRanges: [
        PortRange(
          protocol: template.portRanges.firstOrNull?.protocol ?? 'Both',
          firstPort: firstPort,
          lastPort: lastPort,
        ),
      ],
    );
  }
}
