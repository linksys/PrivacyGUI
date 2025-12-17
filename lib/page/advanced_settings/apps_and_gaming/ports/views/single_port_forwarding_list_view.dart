import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/widgets/_widgets.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

class SinglePortForwardingListView extends ArgumentsConsumerStatelessView {
  const SinglePortForwardingListView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SinglePortForwardingListContentView(args: super.args);
  }
}

class SinglePortForwardingListContentView
    extends ArgumentsConsumerStatefulView {
  const SinglePortForwardingListContentView({super.key, super.args});

  @override
  ConsumerState<SinglePortForwardingListContentView> createState() =>
      _SinglePortForwardingContentViewState();
}

class _SinglePortForwardingContentViewState
    extends ConsumerState<SinglePortForwardingListContentView> {
  late final SinglePortForwardingListNotifier _notifier;

  // Controllers for editing
  final TextEditingController _applicationTextController =
      TextEditingController();
  final TextEditingController _internalPortTextController =
      TextEditingController();
  final TextEditingController _externalPortTextController =
      TextEditingController();
  final TextEditingController _ipAddressTextController =
      TextEditingController();

  // Editing state
  SinglePortForwardingRule? _editingRule;
  bool _isInitializing = false;
  StateSetter? _sheetStateSetter;

  // Validation errors
  String? _nameError;
  String? _ipError;
  String? _externalPortError;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(singlePortForwardingListProvider.notifier);

    // Add listeners for validation
    _applicationTextController.addListener(_onNameChanged);
    _internalPortTextController.addListener(_onInternalPortChanged);
    _externalPortTextController.addListener(_onExternalPortChanged);
    _ipAddressTextController.addListener(_onIpChanged);
  }

  @override
  void dispose() {
    _applicationTextController.removeListener(_onNameChanged);
    _internalPortTextController.removeListener(_onInternalPortChanged);
    _externalPortTextController.removeListener(_onExternalPortChanged);
    _ipAddressTextController.removeListener(_onIpChanged);

    _applicationTextController.dispose();
    _internalPortTextController.dispose();
    _externalPortTextController.dispose();
    _ipAddressTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(singlePortForwardingListProvider);
    final isAddEnabled = !_notifier.isExceedMax();

    return AppDataTable<SinglePortForwardingRule>(
      data: state.current.rules,
      columns: _buildColumns(context, state),
      totalRows: state.current.rules.length,
      currentPage: 1,
      rowsPerPage: 50,
      onPageChanged: (_) {},
      onSave: _handleSave,
      emptyMessage: loc(context).noSinglePortForwarding,
      showAddButton: isAddEnabled,
      onCreateTemplate: () => SinglePortForwardingRule(
        isEnabled: true,
        externalPort: 0,
        protocol: 'Both',
        internalServerIPAddress: state.status.routerIp,
        internalPort: 0,
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

  List<AppTableColumn<SinglePortForwardingRule>> _buildColumns(
      BuildContext context, SinglePortForwardingListState state) {
    return [
      // Column 0: Application Name
      AppTableColumn<SinglePortForwardingRule>(
        label: loc(context).applicationName,
        cellBuilder: (_, rule) => AppText.bodyMedium(rule.description),
        editBuilder: (_, rule, setSheetState) {
          _sheetStateSetter = setSheetState;
          if (_editingRule != rule) {
            _isInitializing = true;
            try {
              _editingRule = rule;
              _applicationTextController.text = rule.description;
              _internalPortTextController.text = '${rule.internalPort}';
              _externalPortTextController.text = '${rule.externalPort}';
              _ipAddressTextController.text = rule.internalServerIPAddress;
              _nameError = null;
              _ipError = null;
              _externalPortError = null;
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

      // Column 1: Internal Port
      AppTableColumn<SinglePortForwardingRule>(
        label: loc(context).internalPort,
        cellBuilder: (_, rule) => AppText.bodyMedium('${rule.internalPort}'),
        editBuilder: (_, rule, setSheetState) {
          return AppTextField(
            key: ValueKey('intPort_${identityHashCode(rule)}'),
            controller: _internalPortTextController,
            hintText: loc(context).internalPort,
            keyboardType: TextInputType.number,
          );
        },
      ),

      // Column 2: External Port
      AppTableColumn<SinglePortForwardingRule>(
        label: loc(context).externalPort,
        cellBuilder: (_, rule) => AppText.bodyMedium('${rule.externalPort}'),
        editBuilder: (_, rule, setSheetState) {
          return AppTextField(
            key: ValueKey('extPort_${identityHashCode(rule)}'),
            controller: _externalPortTextController,
            hintText: loc(context).externalPort,
            keyboardType: TextInputType.number,
            errorText: _externalPortError,
          );
        },
      ),

      // Column 3: Protocol
      AppTableColumn<SinglePortForwardingRule>(
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
            key: ValueKey('protocol_${identityHashCode(rule)}'),
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

      // Column 4: Device IP
      AppTableColumn<SinglePortForwardingRule>(
        label: loc(context).deviceIP,
        cellBuilder: (_, rule) =>
            AppText.bodyMedium(rule.internalServerIPAddress),
        editBuilder: (_, rule, setSheetState) {
          return AppTextField(
            key: ValueKey('ip_${identityHashCode(rule)}'),
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
    final ruleNotifier = ref.read(singlePortForwardingRuleProvider.notifier);
    final currentRule = ref.read(singlePortForwardingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(currentRule.copyWith(protocol: protocol));
    }
  }

  void _updateIp(String ip) {
    final ruleNotifier = ref.read(singlePortForwardingRuleProvider.notifier);
    final currentRule = ref.read(singlePortForwardingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier
          .updateRule(currentRule.copyWith(internalServerIPAddress: ip));
    }
  }

  // --- Listeners ---

  void _onNameChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(singlePortForwardingRuleProvider.notifier);
    final currentRule = ref.read(singlePortForwardingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(
          currentRule.copyWith(description: _applicationTextController.text));
    }
    _validateAll();
  }

  void _onInternalPortChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(singlePortForwardingRuleProvider.notifier);
    final currentRule = ref.read(singlePortForwardingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(currentRule.copyWith(
          internalPort: int.tryParse(_internalPortTextController.text) ?? 0));
    }
  }

  void _onExternalPortChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(singlePortForwardingRuleProvider.notifier);
    final currentRule = ref.read(singlePortForwardingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(currentRule.copyWith(
          externalPort: int.tryParse(_externalPortTextController.text) ?? 0));
    }
    _validateAll();
  }

  void _onIpChanged() {
    if (_isInitializing) return;
    _updateIp(_ipAddressTextController.text);
    _validateAll();
  }

  // --- Validation ---

  void _validateAll() {
    final ruleNotifier = ref.read(singlePortForwardingRuleProvider.notifier);

    setState(() {
      // Validate name
      _nameError = ruleNotifier.isNameValid(_applicationTextController.text)
          ? null
          : loc(context).theNameMustNotBeEmpty;

      // Validate IP
      _ipError = ruleNotifier.isDeviceIpValidate(_ipAddressTextController.text)
          ? null
          : loc(context).invalidIpAddress;

      // Validate external port (conflict check)
      final externalPort = int.tryParse(_externalPortTextController.text) ?? 0;
      final protocol =
          ref.read(singlePortForwardingRuleProvider).rule?.protocol ?? 'Both';
      _externalPortError = ruleNotifier.isPortConflict(externalPort, protocol)
          ? loc(context).rulesOverlapError
          : null;
    });

    _sheetStateSetter?.call(() {});
  }

  bool _isValid() {
    final ruleNotifier = ref.read(singlePortForwardingRuleProvider.notifier);

    if (!ruleNotifier.isNameValid(_applicationTextController.text)) {
      return false;
    }
    if (!ruleNotifier.isDeviceIpValidate(_ipAddressTextController.text)) {
      return false;
    }

    final externalPort = int.tryParse(_externalPortTextController.text) ?? 0;
    final protocol =
        ref.read(singlePortForwardingRuleProvider).rule?.protocol ?? 'Both';
    if (ruleNotifier.isPortConflict(externalPort, protocol)) {
      return false;
    }

    return true;
  }

  void _clearControllers() {
    _applicationTextController.clear();
    _internalPortTextController.clear();
    _externalPortTextController.clear();
    _ipAddressTextController.clear();
    _nameError = null;
    _ipError = null;
    _externalPortError = null;
    setState(() {});
  }

  // --- CRUD Handlers ---

  void _handleCancel() {
    _editingRule = null;
    _sheetStateSetter = null;
    _clearControllers();
  }

  Future<bool> _handleDelete(SinglePortForwardingRule rule) async {
    _notifier.deleteRule(rule);
    _clearControllers();
    return true;
  }

  Future<bool> _handleAdd(SinglePortForwardingRule templateRule) async {
    // Initialize provider with template
    final state = ref.read(singlePortForwardingListProvider);
    ref.read(singlePortForwardingRuleProvider.notifier).init(
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

  Future<bool> _handleSave(SinglePortForwardingRule originalRule) async {
    _validateAll();
    if (!_isValid()) {
      return false;
    }

    final editedRule = _buildRuleFromControllers(originalRule);
    final state = ref.read(singlePortForwardingListProvider);
    final index = state.current.rules.indexOf(originalRule);

    if (index >= 0) {
      _notifier.editRule(index, editedRule);
    }

    _editingRule = null;
    _clearControllers();
    return true;
  }

  SinglePortForwardingRule _buildRuleFromControllers(
      SinglePortForwardingRule template) {
    return template.copyWith(
      description: _applicationTextController.text,
      internalPort: int.tryParse(_internalPortTextController.text) ?? 0,
      externalPort: int.tryParse(_externalPortTextController.text) ?? 0,
      internalServerIPAddress: _ipAddressTextController.text,
      protocol:
          ref.read(singlePortForwardingRuleProvider).rule?.protocol ?? 'Both',
    );
  }
}
