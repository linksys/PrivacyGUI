import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/jnap/models/port_range_triggering_rule.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/_port_forwarding.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/providers/consts.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/panel/general_section.dart';

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

  bool _isEnabled = false;
  List<PortRangeTriggeringRule> _rules = [];

  @override
  void initState() {
    _notifier = ref.read(portRangeTriggeringRuleProvider.notifier);
    _rules = widget.args['rules'] ?? [];
    final PortRangeTriggeringRule? rule = widget.args['edit'];
    if (rule != null) {
      _notifier.goEdit(_rules, rule).then((_) {
        _ruleNameController.text = rule.description;
        _firstTriggerPortController.text = '${rule.firstTriggerPort}';
        _lastTriggerPortController.text = '${rule.lastTriggerPort}';
        _firstForwardedPortController.text = '${rule.firstForwardedPort}';
        _lastForwardedPortController.text = '${rule.lastForwardedPort}';
        setState(() {
          _isEnabled = rule.isEnabled;
        });
      });
    } else {
      _notifier.goAdd(_rules).then((_) {
        setState(() {
          _isEnabled = true;
        });
      });
    }
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
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).portRangeTriggering,
      bottomBar: PageBottomBar(
        isPositiveEnabled: true,
        isNegitiveEnabled: state.mode == RuleMode.editing ? true : null,
        negitiveLable: loc(context).delete,
        onPositiveTap: () {
          final rule = PortRangeTriggeringRule(
              isEnabled: _isEnabled,
              firstTriggerPort: int.parse(_firstTriggerPortController.text),
              lastTriggerPort: int.parse(_lastTriggerPortController.text),
              firstForwardedPort: int.parse(_firstForwardedPortController.text),
              lastForwardedPort: int.parse(_lastForwardedPortController.text),
              description: _ruleNameController.text);
          doSomethingWithSpinner(
            context,
            _notifier.save(rule).then(
              (value) {
                if (value) {
                  showSuccessSnackBar(
                      context,
                      _notifier.isEdit()
                          ? loc(context).ruleUpdated
                          : loc(context).ruleAdded);

                  context.pop(true);
                }
              },
            ),
          );
        },
        onNegitiveTap: () {
          _notifier.delete().then((value) {
            if (value) {
              showSimpleSnackBar(context, loc(context).ruleDeleted);
            }
            context.pop(true);
          });
        },
      ),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large2(),
            if (state.mode == RuleMode.editing)
              ..._buildEditContents(state)
            else
              ..._buildAddContents(state)
          ],
        ),
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
          value: _isEnabled,
          onChanged: (value) {
            setState(() {
              _isEnabled = value;
            });
          },
        ),
      ),
      const AppGap.large2(),
      ...buildInputForms(),
    ];
  }

  List<Widget> buildInputForms() {
    return [
      AppTextField.outline(
          headerText: loc(context).ruleName, controller: _ruleNameController),
      const AppGap.large2(),
      AppSection.withLabel(
        title: loc(context).triggeredRange,
        content: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField.minMaxNumber(
              border: const OutlineInputBorder(),
              headerText: loc(context).startPort,
              inputType: TextInputType.number,
              controller: _firstTriggerPortController,
              max: 65535,
            ),
            const AppGap.medium(),
            AppTextField.minMaxNumber(
              border: const OutlineInputBorder(),
              headerText: loc(context).endPort,
              inputType: TextInputType.number,
              controller: _lastTriggerPortController,
              max: 65535,
            ),
            const AppGap.medium(),
          ],
        ),
      ),
      AppSection.withLabel(
        title: loc(context).forwardedRange,
        content: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField.minMaxNumber(
              border: const OutlineInputBorder(),
              headerText: loc(context).startPort,
              inputType: TextInputType.number,
              controller: _firstForwardedPortController,
              max: 65535,
            ),
            const AppGap.medium(),
            AppTextField.minMaxNumber(
              border: const OutlineInputBorder(),
              headerText: loc(context).endPort,
              inputType: TextInputType.number,
              controller: _lastForwardedPortController,
              max: 65535,
            ),
            const AppGap.medium(),
          ],
        ),
      ),
    ];
  }
}
