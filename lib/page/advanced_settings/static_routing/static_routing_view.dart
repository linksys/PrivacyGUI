import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_rule_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/page/components/composed/app_radio_list.dart';
import 'package:ui_kit_library/ui_kit.dart';

class StaticRoutingView extends ArgumentsConsumerStatefulView {
  const StaticRoutingView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<StaticRoutingView> createState() => _StaticRoutingViewState();
}

class _StaticRoutingViewState extends ConsumerState<StaticRoutingView>
    with PageSnackbarMixin {
  late final StaticRoutingNotifier _notifier;

  // Controllers for editing
  final TextEditingController _routerNameController = TextEditingController();
  final TextEditingController _destinationIPController =
      TextEditingController();
  final TextEditingController _subnetMaskController = TextEditingController();
  final TextEditingController _gatewayController = TextEditingController();

  // Editing state
  NamedStaticRouteEntry? _editingRule;
  RoutingSettingInterface _selectedInterface = RoutingSettingInterface.lan;
  bool _isInitializing = false;
  StateSetter? _sheetStateSetter;

  // Validation errors
  String? _nameError;
  String? _destIpError;
  String? _subnetError;
  String? _gatewayError;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(staticRoutingProvider.notifier);

    doSomethingWithSpinner(context, _notifier.fetch());

    // Add listeners
    _routerNameController.addListener(_onNameChanged);
    _destinationIPController.addListener(_onDestIpChanged);
    _subnetMaskController.addListener(_onSubnetChanged);
    _gatewayController.addListener(_onGatewayChanged);
  }

  @override
  void dispose() {
    _routerNameController.removeListener(_onNameChanged);
    _destinationIPController.removeListener(_onDestIpChanged);
    _subnetMaskController.removeListener(_onSubnetChanged);
    _gatewayController.removeListener(_onGatewayChanged);

    _routerNameController.dispose();
    _destinationIPController.dispose();
    _subnetMaskController.dispose();
    _gatewayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staticRoutingProvider);
    final isAddEnabled = !_notifier.isExceedMax();

    return UiKitPageView.withSliver(
      title: loc(context).advancedRouting,
      scrollable: true,
      bottomBar: UiKitBottomBarConfig(
        isPositiveEnabled: state.isDirty,
        onPositiveTap: () {
          doSomethingWithSpinner(context, _notifier.save()).then((_) {
            showChangesSavedSnackBar();
          }).onError((error, stackTrace) {
            showErrorMessageSnackBar(error);
          });
        },
      ),
      child: (context, constraints) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppRadioList(
              key: const Key('settingNetwork'),
              selected: state.current.isNATEnabled
                  ? RoutingSettingNetwork.nat
                  : RoutingSettingNetwork.dynamicRouting,
              itemHeight: 56,
              items: [
                AppRadioListItem(
                  title: loc(context).nat,
                  value: RoutingSettingNetwork.nat,
                ),
                AppRadioListItem(
                  title: loc(context).dynamicRouting,
                  value: RoutingSettingNetwork.dynamicRouting,
                ),
              ],
              onChanged: (index, value) {
                if (value != null) {
                  _notifier.updateSettingNetwork(value);
                }
              },
            ),
            AppGap.xxl(),
            _buildDataTable(state, isAddEnabled),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(StaticRoutingState state, bool isAddEnabled) {
    return AppDataTable<NamedStaticRouteEntry>(
      data: state.current.entries.entries,
      columns: _buildColumns(context),
      totalRows: state.current.entries.entries.length,
      currentPage: 1,
      rowsPerPage: 50,
      onPageChanged: (_) {},
      onSave: _handleSave,
      emptyMessage: loc(context).noStaticRoutes,
      showAddButton: isAddEnabled,
      onCreateTemplate: () => NamedStaticRouteEntry(
        name: '',
        settings: StaticRouteEntry(
          destinationLAN: '',
          interface: 'LAN',
          networkPrefixLength: 24,
        ),
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

  List<AppTableColumn<NamedStaticRouteEntry>> _buildColumns(
      BuildContext context) {
    return [
      // Column 0: Route Name
      AppTableColumn<NamedStaticRouteEntry>(
        label: loc(context).routeName,
        cellBuilder: (_, rule) => AppText.bodyMedium(rule.name),
        editBuilder: (_, rule, setSheetState) {
          _sheetStateSetter = setSheetState;
          _initEditingState(rule);
          return AppTextField(
            key: ValueKey('routeName_${identityHashCode(rule)}'),
            controller: _routerNameController,
            hintText: loc(context).routeName,
            errorText: _nameError,
          );
        },
      ),

      // Column 1: Destination IP
      AppTableColumn<NamedStaticRouteEntry>(
        label: loc(context).destinationIPAddress,
        cellBuilder: (_, rule) =>
            AppText.bodyMedium(rule.settings.destinationLAN),
        editBuilder: (_, rule, setSheetState) {
          return AppTextField(
            key: ValueKey('destIP_${identityHashCode(rule)}'),
            controller: _destinationIPController,
            hintText: loc(context).destinationIPAddress,
            errorText: _destIpError,
          );
        },
      ),

      // Column 2: Subnet Mask
      AppTableColumn<NamedStaticRouteEntry>(
        label: loc(context).subnetMask,
        cellBuilder: (_, rule) => AppText.bodyMedium(
            NetworkUtils.prefixLengthToSubnetMask(
                rule.settings.networkPrefixLength)),
        editBuilder: (_, rule, setSheetState) {
          return AppTextField(
            key: ValueKey('subnet_${identityHashCode(rule)}'),
            controller: _subnetMaskController,
            hintText: loc(context).subnetMask,
            errorText: _subnetError,
          );
        },
      ),

      // Column 3: Gateway
      AppTableColumn<NamedStaticRouteEntry>(
        label: loc(context).gateway,
        cellBuilder: (_, rule) =>
            AppText.bodyMedium(rule.settings.gateway ?? '--'),
        editBuilder: (_, rule, setSheetState) {
          return AppTextField(
            key: ValueKey('gateway_${identityHashCode(rule)}'),
            controller: _gatewayController,
            hintText: loc(context).gateway,
            errorText: _gatewayError,
          );
        },
      ),

      // Column 4: Interface
      AppTableColumn<NamedStaticRouteEntry>(
        label: loc(context).labelInterface,
        cellBuilder: (_, rule) =>
            AppText.bodyMedium(_getInterfaceTitle(rule.settings.interface)),
        editBuilder: (_, rule, setSheetState) {
          final interfaceDisplayMap = {
            RoutingSettingInterface.lan: _getInterfaceTitle('LAN'),
            RoutingSettingInterface.internet: _getInterfaceTitle('Internet'),
          };
          return AppDropdown<String>(
            key: ValueKey('interface_${identityHashCode(rule)}'),
            items: interfaceDisplayMap.values.toList(),
            value: interfaceDisplayMap[_selectedInterface],
            hint: loc(context).labelInterface,
            onChanged: (displayValue) {
              if (displayValue != null) {
                final interfaceKey = interfaceDisplayMap.entries
                    .firstWhere((e) => e.value == displayValue,
                        orElse: () => MapEntry(RoutingSettingInterface.lan, ''))
                    .key;
                _selectedInterface = interfaceKey;
                _onInterfaceChanged();
                setSheetState(() {});
              }
            },
          );
        },
      ),
    ];
  }

  void _initEditingState(NamedStaticRouteEntry rule) {
    if (_editingRule != rule) {
      _isInitializing = true;
      try {
        _editingRule = rule;
        final state = ref.read(staticRoutingProvider);

        // Initialize provider
        ref.read(staticRoutingRuleProvider.notifier).init(
              state.current.entries.entries,
              rule,
              state.current.entries.entries.indexOf(rule),
              state.status.routerIp,
              state.status.subnetMask,
            );

        // Set controller values
        _routerNameController.text = rule.name;
        _destinationIPController.text = rule.settings.destinationLAN;
        _subnetMaskController.text = NetworkUtils.prefixLengthToSubnetMask(
            rule.settings.networkPrefixLength);
        _gatewayController.text = rule.settings.gateway ?? '';
        _selectedInterface =
            RoutingSettingInterface.resolve(rule.settings.interface);

        // Clear errors
        _nameError = null;
        _destIpError = null;
        _subnetError = null;
        _gatewayError = null;
      } finally {
        _isInitializing = false;
      }
    }
  }

  // --- Listeners ---

  void _onNameChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(staticRoutingRuleProvider.notifier);
    final currentRule = ref.read(staticRoutingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier
          .updateRule(currentRule.copyWith(name: _routerNameController.text));
    }
    _validateAll();
  }

  void _onDestIpChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(staticRoutingRuleProvider.notifier);
    final currentRule = ref.read(staticRoutingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(currentRule.copyWith(
        settings: currentRule.settings
            .copyWith(destinationLAN: _destinationIPController.text),
      ));
    }
    _validateAll();
  }

  void _onSubnetChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(staticRoutingRuleProvider.notifier);
    final currentRule = ref.read(staticRoutingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(currentRule.copyWith(
        settings: currentRule.settings.copyWith(
          networkPrefixLength:
              NetworkUtils.subnetMaskToPrefixLength(_subnetMaskController.text),
        ),
      ));
    }
    _validateAll();
  }

  void _onGatewayChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(staticRoutingRuleProvider.notifier);
    final currentRule = ref.read(staticRoutingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(currentRule.copyWith(
        settings: currentRule.settings
            .copyWith(gateway: () => _gatewayController.text),
      ));
    }
    _validateAll();
  }

  void _onInterfaceChanged() {
    if (_isInitializing) return;
    final ruleNotifier = ref.read(staticRoutingRuleProvider.notifier);
    final currentRule = ref.read(staticRoutingRuleProvider).rule;
    if (currentRule != null) {
      ruleNotifier.updateRule(currentRule.copyWith(
        settings:
            currentRule.settings.copyWith(interface: _selectedInterface.value),
      ));
    }
    _validateAll();
  }

  // --- Validation ---

  void _validateAll() {
    final ruleNotifier = ref.read(staticRoutingRuleProvider.notifier);
    final currentRule = ref.read(staticRoutingRuleProvider).rule;

    setState(() {
      // Validate name
      _nameError = ruleNotifier.isNameValid(_routerNameController.text)
          ? null
          : loc(context).theNameMustNotBeEmpty;

      // Validate destination IP
      _destIpError =
          ruleNotifier.isValidIpAddress(_destinationIPController.text)
              ? null
              : loc(context).invalidIpAddress;

      // Validate subnet mask
      final prefixLength =
          NetworkUtils.subnetMaskToPrefixLength(_subnetMaskController.text);
      _subnetError = ruleNotifier.isValidSubnetMask(prefixLength)
          ? null
          : loc(context).invalidSubnetMask;

      // Validate gateway (depends on interface)
      final isLan = (currentRule?.settings.interface ?? 'LAN') == 'LAN';
      _gatewayError =
          ruleNotifier.isValidIpAddress(_gatewayController.text, isLan)
              ? null
              : loc(context).invalidGatewayIpAddress;
    });

    _sheetStateSetter?.call(() {});
  }

  bool _isValid() {
    final ruleNotifier = ref.read(staticRoutingRuleProvider.notifier);
    final currentRule = ref.read(staticRoutingRuleProvider).rule;

    if (!ruleNotifier.isNameValid(_routerNameController.text)) return false;
    if (!ruleNotifier.isValidIpAddress(_destinationIPController.text)) {
      return false;
    }

    final prefixLength =
        NetworkUtils.subnetMaskToPrefixLength(_subnetMaskController.text);
    if (!ruleNotifier.isValidSubnetMask(prefixLength)) return false;

    final isLan = (currentRule?.settings.interface ?? 'LAN') == 'LAN';
    if (!ruleNotifier.isValidIpAddress(_gatewayController.text, isLan)) {
      return false;
    }

    return true;
  }

  void _clearControllers() {
    _routerNameController.clear();
    _destinationIPController.clear();
    _subnetMaskController.clear();
    _gatewayController.clear();
    _selectedInterface = RoutingSettingInterface.lan;
    _nameError = null;
    _destIpError = null;
    _subnetError = null;
    _gatewayError = null;
    setState(() {});
  }

  // --- CRUD Handlers ---

  void _handleCancel() {
    _editingRule = null;
    _sheetStateSetter = null;
    _clearControllers();
  }

  Future<bool> _handleDelete(NamedStaticRouteEntry rule) async {
    _notifier.deleteRule(rule);
    _clearControllers();
    return true;
  }

  Future<bool> _handleAdd(NamedStaticRouteEntry templateRule) async {
    final state = ref.read(staticRoutingProvider);
    ref.read(staticRoutingRuleProvider.notifier).init(
          state.current.entries.entries,
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

  Future<bool> _handleSave(NamedStaticRouteEntry originalRule) async {
    _validateAll();
    if (!_isValid()) {
      return false;
    }

    final editedRule = _buildRuleFromControllers(originalRule);
    final state = ref.read(staticRoutingProvider);
    final index = state.current.entries.entries.indexOf(originalRule);

    if (index >= 0) {
      _notifier.editRule(index, editedRule);
    }

    _editingRule = null;
    _clearControllers();
    return true;
  }

  NamedStaticRouteEntry _buildRuleFromControllers(
      NamedStaticRouteEntry template) {
    return template.copyWith(
      name: _routerNameController.text,
      settings: template.settings.copyWith(
        destinationLAN: _destinationIPController.text,
        networkPrefixLength:
            NetworkUtils.subnetMaskToPrefixLength(_subnetMaskController.text),
        gateway: () => _gatewayController.text,
        interface: _selectedInterface.value,
      ),
    );
  }

  String _getInterfaceTitle(String interface) {
    final resolved = RoutingSettingInterface.resolve(interface);
    return switch (resolved) {
      RoutingSettingInterface.lan => loc(context).lanWireless,
      RoutingSettingInterface.internet =>
        RoutingSettingInterface.internet.value,
    };
  }
}
