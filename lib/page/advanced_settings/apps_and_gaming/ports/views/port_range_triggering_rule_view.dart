import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

class PortRangeTriggeringRuleView extends ArgumentsConsumerStatelessView {
  const PortRangeTriggeringRuleView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortRangeTriggeringRuleContentView(
      args: super.args,
    );
  }
}

class PortRangeTriggeringRuleContentView extends ArgumentsConsumerStatefulView {
  const PortRangeTriggeringRuleContentView({super.key, super.args});

  @override
  ConsumerState<PortRangeTriggeringRuleContentView> createState() =>
      _AddRuleContentViewState();
}

class _AddRuleContentViewState
    extends ConsumerState<PortRangeTriggeringRuleContentView> {
  late final PortRangeTriggeringRuleNotifier _notifier;

  final TextEditingController _ruleNameController = TextEditingController();
  final TextEditingController _firstTriggerPortController =
      TextEditingController();
  final TextEditingController _lastTriggerPortController =
      TextEditingController();
  final TextEditingController _firstForwardedPortController =
      TextEditingController();
  final TextEditingController _lastForwardedPortController =
      TextEditingController();

  String? _triggeredPortError;
  String? _forwardedPortError;
  String? _descriptionError;
  bool _isEdit = false;

  @override
  void initState() {
    _notifier = ref.read(portRangeTriggeringRuleProvider.notifier);

    final List<PortRangeTriggeringRule> rules = widget.args['items'] ?? [];
    var rule = widget.args['edit'];
    int? index;

    if (rule != null) {
      _isEdit = true;
      _ruleNameController.text = rule.description;
      _firstTriggerPortController.text = '${rule.firstTriggerPort}';
      _lastTriggerPortController.text = '${rule.lastTriggerPort}';
      _firstForwardedPortController.text = '${rule.firstForwardedPort}';
      _lastForwardedPortController.text = '${rule.lastForwardedPort}';
      index = rules.indexOf(rule);
    } else {
      _isEdit = false;
      rule = PortRangeTriggeringRule(
          isEnabled: true,
          firstTriggerPort: 0,
          lastTriggerPort: 0,
          firstForwardedPort: 0,
          lastForwardedPort: 0,
          description: '');
    }
    doSomethingWithSpinner(context, Future.doWhile(() => !mounted)).then((_) {
      _notifier.init(rules, rule, index);
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    _ruleNameController.dispose();
    _firstTriggerPortController.dispose();
    _lastTriggerPortController.dispose();
    _firstForwardedPortController.dispose();
    _lastForwardedPortController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portRangeTriggeringRuleProvider);
    return StyledAppPageView.withSliver(
      scrollable: true,
      title: loc(context).portRangeTriggering,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _notifier.isRuleValid(),
        onPositiveTap: () {
          final rule = ref.read(portRangeTriggeringRuleProvider).rule;
          context.pop(rule);
        },
      ),
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppGap.large2(),
          if (_isEdit)
            ..._buildEditContents(state)
          else
            ..._buildAddContents(state)
        ],
      ),
    );
  }

  List<Widget> _buildAddContents(PortRangeTriggeringRuleState state) {
    return buildInputForms();
  }

  List<Widget> _buildEditContents(PortRangeTriggeringRuleState state) {
    return [
      AppListCard(
        title: AppText.labelLarge(loc(context).ruleEnabled),
        trailing: AppSwitch(
          semanticLabel: 'rule enabled',
          value: state.rule?.isEnabled ?? true,
          onChanged: (value) {
            _notifier.updateRule(state.rule?.copyWith(isEnabled: value));
          },
        ),
      ),
      const AppGap.large2(),
      ...buildInputForms(),
    ];
  }

  List<Widget> buildInputForms() {
    final state = ref.watch(portRangeTriggeringRuleProvider);
    return [
      AppTextField.outline(
        key: const Key('ruleNameTextField'),
        headerText: loc(context).ruleName,
        controller: _ruleNameController,
        onFocusChanged: (focus) {
          if (!focus) {
            setState(() {
              _descriptionError =
                  _notifier.isNameValid(_ruleNameController.text)
                      ? null
                      : loc(context).theNameMustNotBeEmpty;
            });
          }
        },
        onChanged: (value) {
          _notifier.updateRule(state.rule?.copyWith(description: value));
        },
        errorText: _descriptionError,
      ),
      const AppGap.large2(),
      AppText.bodyMedium(loc(context).triggeredRange),
      const AppGap.small2(),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField.minMaxNumber(
              key: const Key('firstTriggerPortTextField'),
              border: const OutlineInputBorder(),
              headerText: loc(context).startPort,
              inputType: TextInputType.number,
              controller: _firstTriggerPortController,
              max: 65535,
              onFocusChanged: _onTriggeredPortFocusChange,
              errorText: _triggeredPortError != null ? '' : null,
              onChanged: (value) {
                _notifier.updateRule(state.rule
                    ?.copyWith(firstTriggerPort: int.tryParse(value) ?? 0));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: Spacing.small2,
                right: Spacing.small2,
                top: Spacing.medium),
            child: AppText.bodyMedium(loc(context).to),
          ),
          Expanded(
            child: AppTextField.minMaxNumber(
              key: const Key('lastTriggerPortTextField'),
              border: const OutlineInputBorder(),
              headerText: loc(context).endPort,
              inputType: TextInputType.number,
              controller: _lastTriggerPortController,
              max: 65535,
              onFocusChanged: _onTriggeredPortFocusChange,
              errorText: _triggeredPortError,
              onChanged: (value) {
                _notifier.updateRule(state.rule
                    ?.copyWith(lastTriggerPort: int.tryParse(value) ?? 0));
              },
            ),
          ),
        ],
      ),
      const AppGap.large2(),
      AppText.bodyMedium(loc(context).forwardedRange),
      const AppGap.small2(),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField.minMaxNumber(
              key: const Key('firstForwardedPortTextField'),
              border: const OutlineInputBorder(),
              headerText: loc(context).startPort,
              inputType: TextInputType.number,
              controller: _firstForwardedPortController,
              max: 65535,
              onFocusChanged: _onForwardedPortFocusChange,
              errorText: _forwardedPortError != null ? '' : null,
              onChanged: (value) {
                _notifier.updateRule(state.rule
                    ?.copyWith(firstForwardedPort: int.tryParse(value) ?? 0));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: Spacing.small2,
                right: Spacing.small2,
                top: Spacing.medium),
            child: AppText.bodyMedium(loc(context).to),
          ),
          Expanded(
            child: AppTextField.minMaxNumber(
              key: const Key('lastForwardedPortTextField'),
              border: const OutlineInputBorder(),
              headerText: loc(context).endPort,
              inputType: TextInputType.number,
              controller: _lastForwardedPortController,
              max: 65535,
              onFocusChanged: _onForwardedPortFocusChange,
              errorText: _forwardedPortError,
              onChanged: (value) {
                _notifier.updateRule(state.rule
                    ?.copyWith(lastForwardedPort: int.tryParse(value) ?? 0));
              },
            ),
          ),
        ],
      ),
    ];
  }

  void _onForwardedPortFocusChange(bool focus) {
    if (!focus) {
      if (_firstForwardedPortController.text.isEmpty ||
          _lastForwardedPortController.text.isEmpty) {
        return;
      }
      final firstPort = int.tryParse(_firstForwardedPortController.text) ?? 0;
      final lastPort = int.tryParse(_lastForwardedPortController.text) ?? 0;
      bool isValidPortRange = lastPort - firstPort >= 0;
      bool isRuleOverlap =
          _notifier.isForwardedPortConflict(firstPort, lastPort);
      _forwardedPortError = !isValidPortRange
          ? loc(context).portRangeError
          : isRuleOverlap
              ? loc(context).rulesOverlapError
              : null;
      _onFocusChange(focus);
    }
  }

  void _onTriggeredPortFocusChange(bool focus) {
    if (!focus) {
      if (_firstTriggerPortController.text.isEmpty ||
          _lastTriggerPortController.text.isEmpty) {
        return;
      }
      final firstPort = int.tryParse(_firstTriggerPortController.text) ?? 0;
      final lastPort = int.tryParse(_lastTriggerPortController.text) ?? 0;
      bool isValidPortRange = lastPort - firstPort >= 0;
      bool isRuleOverlap =
          _notifier.isTriggeredPortConflict(firstPort, lastPort);
      _triggeredPortError = !isValidPortRange
          ? loc(context).portRangeError
          : isRuleOverlap
              ? loc(context).rulesOverlapError
              : null;
      _onFocusChange(focus);
    }
  }

  void _onFocusChange(bool focus) {
    if (!focus) {
      setState(() {});
    }
  }
}
