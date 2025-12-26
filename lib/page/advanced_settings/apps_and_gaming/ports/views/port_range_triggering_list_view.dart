import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

class PortRangeTriggeringListView extends ArgumentsConsumerStatelessView {
  const PortRangeTriggeringListView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortRangeTriggeringListContentView(args: super.args);
  }
}

class PortRangeTriggeringListContentView extends ArgumentsConsumerStatefulView {
  const PortRangeTriggeringListContentView({super.key, super.args});

  @override
  ConsumerState<PortRangeTriggeringListContentView> createState() =>
      _PortRangeTriggeringContentViewState();
}

class _PortRangeTriggeringContentViewState
    extends ConsumerState<PortRangeTriggeringListContentView> {
  late final PortRangeTriggeringListNotifier _notifier;

  // Controllers for editing
  final TextEditingController _applicationTextController =
      TextEditingController();
  final TextEditingController _firstTriggerPortController =
      TextEditingController();
  final TextEditingController _lastTriggerPortController =
      TextEditingController();
  final TextEditingController _firstForwardedPortController =
      TextEditingController();
  final TextEditingController _lastForwardedPortController =
      TextEditingController();

  // Editing state
  PortRangeTriggeringRuleUIModel? _editingRule;
  bool _isInitializing = false;
  StateSetter? _sheetStateSetter;

  // Validation errors
  String? _nameError;
  String? _triggeredRangeError;
  String? _forwardedRangeError;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(portRangeTriggeringListProvider.notifier);

    // Add listeners for validation
    _applicationTextController.addListener(_onNameChanged);
    _firstTriggerPortController.addListener(_onTriggerPortChanged);
    _lastTriggerPortController.addListener(_onTriggerPortChanged);
    _firstForwardedPortController.addListener(_onForwardedPortChanged);
    _lastForwardedPortController.addListener(_onForwardedPortChanged);
  }

  @override
  void dispose() {
    _applicationTextController.removeListener(_onNameChanged);
    _firstTriggerPortController.removeListener(_onTriggerPortChanged);
    _lastTriggerPortController.removeListener(_onTriggerPortChanged);
    _firstForwardedPortController.removeListener(_onForwardedPortChanged);
    _lastForwardedPortController.removeListener(_onForwardedPortChanged);

    _applicationTextController.dispose();
    _firstTriggerPortController.dispose();
    _lastTriggerPortController.dispose();
    _firstForwardedPortController.dispose();
    _lastForwardedPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portRangeTriggeringListProvider);
    final isAddEnabled = !_notifier.isExceedMax();

    return AppDataTable<PortRangeTriggeringRuleUIModel>(
      data: state.current.rules,
      columns: _buildColumns(context),
      totalRows: state.current.rules.length,
      currentPage: 1,
      rowsPerPage: 50,
      onPageChanged: (_) {},
      onSave: _handleSave,
      emptyMessage: loc(context).noPortRangeTriggering,
      showAddButton: isAddEnabled,
      onCreateTemplate: () => PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        description: '',
        firstTriggerPort: 0,
        lastTriggerPort: 0,
        firstForwardedPort: 0,
        lastForwardedPort: 0,
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

  List<AppTableColumn<PortRangeTriggeringRuleUIModel>> _buildColumns(
      BuildContext context) {
    return [
      // Column 0: Application Name
      AppTableColumn<PortRangeTriggeringRuleUIModel>(
        label: loc(context).applicationName,
        cellBuilder: (_, rule) => AppText.bodyMedium(rule.description),
        editBuilder: (_, rule, setSheetState) {
          _sheetStateSetter = setSheetState;
          if (_editingRule != rule) {
            _isInitializing = true;
            try {
              _editingRule = rule;
              _applicationTextController.text = rule.description;
              _firstTriggerPortController.text = '${rule.firstTriggerPort}';
              _lastTriggerPortController.text = '${rule.lastTriggerPort}';
              _firstForwardedPortController.text = '${rule.firstForwardedPort}';
              _lastForwardedPortController.text = '${rule.lastForwardedPort}';
              _nameError = null;
              _triggeredRangeError = null;
              _forwardedRangeError = null;
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

      // Column 1: Triggered Range
      AppTableColumn<PortRangeTriggeringRuleUIModel>(
        label: loc(context).triggeredRange,
        cellBuilder: (_, rule) => AppText.bodyMedium(
            '${rule.firstTriggerPort} ${loc(context).to} ${rule.lastTriggerPort}'),
        editBuilder: (_, rule, setSheetState) {
          return AppRangeInput(
            key: const Key('triggeredRangeInput'),
            startKey: const Key('firstTriggerPortTextField'),
            endKey: const Key('lastTriggerPortTextField'),
            startController: _firstTriggerPortController,
            endController: _lastTriggerPortController,
            errorText: _triggeredRangeError,
          );
        },
      ),

      // Column 2: Forwarded Range
      AppTableColumn<PortRangeTriggeringRuleUIModel>(
        label: loc(context).forwardedRange,
        cellBuilder: (_, rule) => AppText.bodyMedium(
            '${rule.firstForwardedPort} ${loc(context).to} ${rule.lastForwardedPort}'),
        editBuilder: (_, rule, setSheetState) {
          return AppRangeInput(
            key: const Key('forwardedRangeInput'),
            startKey: const Key('firstForwardedPortTextField'),
            endKey: const Key('lastForwardedPortTextField'),
            startController: _firstForwardedPortController,
            endController: _lastForwardedPortController,
            errorText: _forwardedRangeError,
          );
        },
      ),
    ];
  }

  // --- Listeners ---

  void _onNameChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(portRangeTriggeringRuleProvider.notifier);
    final currentRule = ref.read(portRangeTriggeringRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(
          currentRule.copyWith(description: _applicationTextController.text));
    }
    _validateAll();
  }

  void _onTriggerPortChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(portRangeTriggeringRuleProvider.notifier);
    final currentRule = ref.read(portRangeTriggeringRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(currentRule.copyWith(
        firstTriggerPort: int.tryParse(_firstTriggerPortController.text) ?? 0,
        lastTriggerPort: int.tryParse(_lastTriggerPortController.text) ?? 0,
      ));
    }
    _validateAll();
  }

  void _onForwardedPortChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(portRangeTriggeringRuleProvider.notifier);
    final currentRule = ref.read(portRangeTriggeringRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(currentRule.copyWith(
        firstForwardedPort:
            int.tryParse(_firstForwardedPortController.text) ?? 0,
        lastForwardedPort: int.tryParse(_lastForwardedPortController.text) ?? 0,
      ));
    }
    _validateAll();
  }

  // --- Validation ---

  void _validateAll() {
    final ruleNotifier = ref.read(portRangeTriggeringRuleProvider.notifier);

    setState(() {
      // Validate name
      _nameError = ruleNotifier.isNameValid(_applicationTextController.text)
          ? null
          : loc(context).theNameMustNotBeEmpty;

      // Validate triggered range
      final firstTrigger = int.tryParse(_firstTriggerPortController.text) ?? 0;
      final lastTrigger = int.tryParse(_lastTriggerPortController.text) ?? 0;

      if (_firstTriggerPortController.text.isEmpty ||
          _lastTriggerPortController.text.isEmpty) {
        _triggeredRangeError = loc(context).portRangeError;
      } else if (!ruleNotifier.isPortRangeValid(firstTrigger, lastTrigger)) {
        _triggeredRangeError = loc(context).portRangeError;
      } else if (ruleNotifier.isTriggeredPortConflict(
          firstTrigger, lastTrigger)) {
        _triggeredRangeError = loc(context).rulesOverlapError;
      } else {
        _triggeredRangeError = null;
      }

      // Validate forwarded range
      final firstForwarded =
          int.tryParse(_firstForwardedPortController.text) ?? 0;
      final lastForwarded =
          int.tryParse(_lastForwardedPortController.text) ?? 0;

      if (_firstForwardedPortController.text.isEmpty ||
          _lastForwardedPortController.text.isEmpty) {
        _forwardedRangeError = loc(context).portRangeError;
      } else if (!ruleNotifier.isPortRangeValid(
          firstForwarded, lastForwarded)) {
        _forwardedRangeError = loc(context).portRangeError;
      } else if (ruleNotifier.isForwardedPortConflict(
          firstForwarded, lastForwarded)) {
        _forwardedRangeError = loc(context).rulesOverlapError;
      } else {
        _forwardedRangeError = null;
      }
    });

    _sheetStateSetter?.call(() {});
  }

  bool _isValid() {
    final ruleNotifier = ref.read(portRangeTriggeringRuleProvider.notifier);

    if (!ruleNotifier.isNameValid(_applicationTextController.text)) {
      return false;
    }

    // Validate triggered range
    final firstTrigger = int.tryParse(_firstTriggerPortController.text) ?? 0;
    final lastTrigger = int.tryParse(_lastTriggerPortController.text) ?? 0;

    if (_firstTriggerPortController.text.isEmpty ||
        _lastTriggerPortController.text.isEmpty) {
      return false;
    }
    if (!ruleNotifier.isPortRangeValid(firstTrigger, lastTrigger)) {
      return false;
    }
    if (ruleNotifier.isTriggeredPortConflict(firstTrigger, lastTrigger)) {
      return false;
    }

    // Validate forwarded range
    final firstForwarded =
        int.tryParse(_firstForwardedPortController.text) ?? 0;
    final lastForwarded = int.tryParse(_lastForwardedPortController.text) ?? 0;

    if (_firstForwardedPortController.text.isEmpty ||
        _lastForwardedPortController.text.isEmpty) {
      return false;
    }
    if (!ruleNotifier.isPortRangeValid(firstForwarded, lastForwarded)) {
      return false;
    }
    if (ruleNotifier.isForwardedPortConflict(firstForwarded, lastForwarded)) {
      return false;
    }

    return true;
  }

  void _clearControllers() {
    _applicationTextController.clear();
    _firstTriggerPortController.clear();
    _lastTriggerPortController.clear();
    _firstForwardedPortController.clear();
    _lastForwardedPortController.clear();
    _nameError = null;
    _triggeredRangeError = null;
    _forwardedRangeError = null;
    setState(() {});
  }

  // --- CRUD Handlers ---

  void _handleCancel() {
    _editingRule = null;
    _sheetStateSetter = null;
    _clearControllers();
  }

  Future<bool> _handleDelete(PortRangeTriggeringRuleUIModel rule) async {
    _notifier.deleteRule(rule);
    _clearControllers();
    return true;
  }

  Future<bool> _handleAdd(PortRangeTriggeringRuleUIModel templateRule) async {
    // Initialize provider with template
    final state = ref.read(portRangeTriggeringListProvider);
    ref.read(portRangeTriggeringRuleProvider.notifier).init(
          state.current.rules,
          templateRule,
          -1,
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

  Future<bool> _handleSave(PortRangeTriggeringRuleUIModel originalRule) async {
    _validateAll();
    if (!_isValid()) {
      return false;
    }

    final editedRule = _buildRuleFromControllers(originalRule);
    final state = ref.read(portRangeTriggeringListProvider);
    final index = state.current.rules.indexOf(originalRule);

    if (index >= 0) {
      _notifier.editRule(index, editedRule);
    }

    _editingRule = null;
    _clearControllers();
    return true;
  }

  PortRangeTriggeringRuleUIModel _buildRuleFromControllers(
      PortRangeTriggeringRuleUIModel template) {
    return template.copyWith(
      description: _applicationTextController.text,
      firstTriggerPort: int.tryParse(_firstTriggerPortController.text) ?? 0,
      lastTriggerPort: int.tryParse(_lastTriggerPortController.text) ?? 0,
      firstForwardedPort: int.tryParse(_firstForwardedPortController.text) ?? 0,
      lastForwardedPort: int.tryParse(_lastForwardedPortController.text) ?? 0,
    );
  }
}
