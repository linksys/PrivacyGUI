import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/widgets/protocol_utils.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

class PortRangeForwardingListView extends ArgumentsConsumerStatelessView {
  const PortRangeForwardingListView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortRangeForwardingListContentView(args: super.args);
  }
}

class PortRangeForwardingListContentView extends ArgumentsConsumerStatefulView {
  const PortRangeForwardingListContentView({super.key, super.args});

  @override
  ConsumerState<PortRangeForwardingListContentView> createState() =>
      _PortRangeForwardingContentViewState();
}

class _PortRangeForwardingContentViewState
    extends ConsumerState<PortRangeForwardingListContentView> {
  late final PortRangeForwardingListNotifier _notifier;

  // Controllers for editing
  final TextEditingController _applicationTextController =
      TextEditingController();
  final TextEditingController _firstPortTextController =
      TextEditingController();
  final TextEditingController _lastPortTextController = TextEditingController();
  final TextEditingController _ipAddressTextController =
      TextEditingController();

  // Editing state
  PortRangeForwardingRuleUIModel? _editingRule;
  bool _isInitializing = false;
  StateSetter? _sheetStateSetter;

  // Validation errors
  String? _nameError;
  String? _ipError;
  String? _portRangeError;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(portRangeForwardingListProvider.notifier);

    // Add listeners for validation
    _applicationTextController.addListener(_onNameChanged);
    _firstPortTextController.addListener(_onFirstPortChanged);
    _lastPortTextController.addListener(_onLastPortChanged);
    _ipAddressTextController.addListener(_onIpChanged);
  }

  @override
  void dispose() {
    _applicationTextController.removeListener(_onNameChanged);
    _firstPortTextController.removeListener(_onFirstPortChanged);
    _lastPortTextController.removeListener(_onLastPortChanged);
    _ipAddressTextController.removeListener(_onIpChanged);

    _applicationTextController.dispose();
    _firstPortTextController.dispose();
    _lastPortTextController.dispose();
    _ipAddressTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portRangeForwardingListProvider);
    final isAddEnabled = !_notifier.isExceedMax();

    return AppDataTable<PortRangeForwardingRuleUIModel>(
      data: state.current.rules,
      columns: _buildColumns(context, state),
      totalRows: state.current.rules.length,
      currentPage: 1,
      rowsPerPage: 50,
      onPageChanged: (_) {},
      onSave: _handleSave,
      emptyMessage: loc(context).noPortRangeForwarding,
      showAddButton: isAddEnabled,
      onCreateTemplate: () => PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 0,
        lastExternalPort: 0,
        protocol: 'Both',
        internalServerIPAddress: state.status.routerIp,
        description: '',
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

  List<AppTableColumn<PortRangeForwardingRuleUIModel>> _buildColumns(
      BuildContext context, PortRangeForwardingListState state) {
    return [
      // Column 0: Application Name
      AppTableColumn<PortRangeForwardingRuleUIModel>(
        label: loc(context).applicationName,
        cellBuilder: (_, rule) => AppText.bodyMedium(rule.description),
        editBuilder: (_, rule, setSheetState) {
          _sheetStateSetter = setSheetState;
          if (_editingRule != rule) {
            _isInitializing = true;
            try {
              _editingRule = rule;
              _applicationTextController.text = rule.description;
              _firstPortTextController.text = '${rule.firstExternalPort}';
              _lastPortTextController.text = '${rule.lastExternalPort}';
              _ipAddressTextController.text = rule.internalServerIPAddress;
              _nameError = null;
              _ipError = null;
              _portRangeError = null;
            } finally {
              _isInitializing = false;
            }
          }
          return AppTextField(
            key: const Key('applicationNameTextField'),
            controller: _applicationTextController,
            hintText: loc(context).applicationName,
            errorText: _nameError,
          );
        },
      ),

      // Column 1: Port Range (Start - End)
      AppTableColumn<PortRangeForwardingRuleUIModel>(
        label: loc(context).startEndPorts,
        cellBuilder: (_, rule) => AppText.bodyMedium(
            '${rule.firstExternalPort} ${loc(context).to} ${rule.lastExternalPort}'),
        editBuilder: (_, rule, setSheetState) {
          return AppRangeInput(
            key: const Key('portRangeInput'),
            startKey: const Key('firstExternalPortTextField'),
            endKey: const Key('lastExternalPortTextField'),
            startController: _firstPortTextController,
            endController: _lastPortTextController,
            errorText: _portRangeError,
          );
        },
      ),

      // Column 2: Protocol
      AppTableColumn<PortRangeForwardingRuleUIModel>(
        label: loc(context).protocol,
        cellBuilder: (_, rule) =>
            AppText.bodyMedium(getProtocolTitle(context, rule.protocol)),
        editBuilder: (_, rule, setSheetState) {
          final currentProtocol = rule.protocol;
          final protocolDisplayMap = {
            'TCP': getProtocolTitle(context, 'TCP'),
            'UDP': getProtocolTitle(context, 'UDP'),
            'Both': getProtocolTitle(context, 'Both'),
          };
          return AppDropdown<String>(
            key: const Key('protocolDropdown'),
            items: protocolDisplayMap.values.toList(),
            value: protocolDisplayMap[currentProtocol],
            hint: loc(context).protocol,
            onChanged: (displayValue) {
              if (displayValue != null) {
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

      // Column 3: Device IP
      AppTableColumn<PortRangeForwardingRuleUIModel>(
        label: loc(context).deviceIP,
        cellBuilder: (_, rule) =>
            AppText.bodyMedium(rule.internalServerIPAddress),
        editBuilder: (_, rule, setSheetState) {
          return AppTextField(
            key: const Key('ipAddressTextField'),
            controller: _ipAddressTextController,
            hintText: loc(context).ipAddress,
            errorText: _ipError,
          );
        },
      ),
    ];
  }

  // --- Update Methods ---

  void _updateProtocol(String protocol) {
    final ruleNotifier = ref.read(portRangeForwardingRuleProvider.notifier);
    final currentRule = ref.read(portRangeForwardingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(currentRule.copyWith(protocol: protocol));
    }
  }

  // --- Listeners ---

  void _onNameChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(portRangeForwardingRuleProvider.notifier);
    final currentRule = ref.read(portRangeForwardingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(
          currentRule.copyWith(description: _applicationTextController.text));
    }
    _validateAll();
  }

  void _onFirstPortChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(portRangeForwardingRuleProvider.notifier);
    final currentRule = ref.read(portRangeForwardingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(currentRule.copyWith(
          firstExternalPort: int.tryParse(_firstPortTextController.text) ?? 0));
    }
    _validateAll();
  }

  void _onLastPortChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(portRangeForwardingRuleProvider.notifier);
    final currentRule = ref.read(portRangeForwardingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(currentRule.copyWith(
          lastExternalPort: int.tryParse(_lastPortTextController.text) ?? 0));
    }
    _validateAll();
  }

  void _onIpChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(portRangeForwardingRuleProvider.notifier);
    final currentRule = ref.read(portRangeForwardingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(currentRule.copyWith(
          internalServerIPAddress: _ipAddressTextController.text));
    }
    _validateAll();
  }

  // --- Validation ---

  void _validateAll() {
    final ruleNotifier = ref.read(portRangeForwardingRuleProvider.notifier);

    setState(() {
      // Validate name
      _nameError = ruleNotifier.isNameValid(_applicationTextController.text)
          ? null
          : loc(context).theNameMustNotBeEmpty;

      // Validate IP
      _ipError = ruleNotifier.isDeviceIpValidate(_ipAddressTextController.text)
          ? null
          : loc(context).invalidIpAddress;

      // Validate port range
      final firstPort = int.tryParse(_firstPortTextController.text) ?? 0;
      final lastPort = int.tryParse(_lastPortTextController.text) ?? 0;
      final protocol =
          ref.read(portRangeForwardingRuleProvider).rule?.protocol ?? 'Both';

      if (_firstPortTextController.text.isEmpty ||
          _lastPortTextController.text.isEmpty) {
        _portRangeError = loc(context).portRangeError;
      } else if (!ruleNotifier.isPortRangeValid(firstPort, lastPort)) {
        _portRangeError = loc(context).portRangeError;
      } else if (ruleNotifier.isPortConflict(firstPort, lastPort, protocol)) {
        _portRangeError = loc(context).rulesOverlapError;
      } else {
        _portRangeError = null;
      }
    });

    _sheetStateSetter?.call(() {});
  }

  bool _isValid() {
    final ruleNotifier = ref.read(portRangeForwardingRuleProvider.notifier);

    if (!ruleNotifier.isNameValid(_applicationTextController.text)) {
      return false;
    }
    if (!ruleNotifier.isDeviceIpValidate(_ipAddressTextController.text)) {
      return false;
    }

    final firstPort = int.tryParse(_firstPortTextController.text) ?? 0;
    final lastPort = int.tryParse(_lastPortTextController.text) ?? 0;
    final protocol =
        ref.read(portRangeForwardingRuleProvider).rule?.protocol ?? 'Both';

    if (_firstPortTextController.text.isEmpty ||
        _lastPortTextController.text.isEmpty) {
      return false;
    }
    if (!ruleNotifier.isPortRangeValid(firstPort, lastPort)) {
      return false;
    }
    if (ruleNotifier.isPortConflict(firstPort, lastPort, protocol)) {
      return false;
    }

    return true;
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

  // --- CRUD Handlers ---

  void _handleCancel() {
    _editingRule = null;
    _sheetStateSetter = null;
    _clearControllers();
  }

  Future<bool> _handleDelete(PortRangeForwardingRuleUIModel rule) async {
    _notifier.deleteRule(rule);
    _clearControllers();
    return true;
  }

  Future<bool> _handleAdd(PortRangeForwardingRuleUIModel templateRule) async {
    // Initialize provider with template
    final state = ref.read(portRangeForwardingListProvider);
    ref.read(portRangeForwardingRuleProvider.notifier).init(
          state.current.rules,
          templateRule,
          -1,
          state.status.routerIp,
          state.status.subnetMask,
        );

    _validateAll();
    if (!_isValid()) {
      return false;
    }

    final newRule = _buildRuleFromControllers(templateRule);
    _notifier.addRule(newRule);

    _editingRule = null;
    _clearControllers();
    return true;
  }

  Future<bool> _handleSave(PortRangeForwardingRuleUIModel originalRule) async {
    _validateAll();
    if (!_isValid()) {
      return false;
    }

    final editedRule = _buildRuleFromControllers(originalRule);
    final state = ref.read(portRangeForwardingListProvider);
    final index = state.current.rules.indexOf(originalRule);

    if (index >= 0) {
      _notifier.editRule(index, editedRule);
    }

    _editingRule = null;
    _clearControllers();
    return true;
  }

  PortRangeForwardingRuleUIModel _buildRuleFromControllers(
      PortRangeForwardingRuleUIModel template) {
    return template.copyWith(
      description: _applicationTextController.text,
      firstExternalPort: int.tryParse(_firstPortTextController.text) ?? 0,
      lastExternalPort: int.tryParse(_lastPortTextController.text) ?? 0,
      internalServerIPAddress: _ipAddressTextController.text,
      protocol:
          ref.read(portRangeForwardingRuleProvider).rule?.protocol ?? 'Both',
    );
  }
}