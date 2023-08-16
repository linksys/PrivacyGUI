import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/core/jnap/models/port_range_triggering_rule.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/port_range_triggering/bloc/port_range_triggering_rule_cubit.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PortRangeTriggeringRuleView extends ArgumentsConsumerStatelessView {
  const PortRangeTriggeringRuleView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider(
      create: (context) => PortRangeTriggeringRuleCubit(
          repository: context.read<RouterRepository>()),
      child: PortRangeTriggeringRuleContentView(
        args: super.args,
      ),
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
  late final PortRangeTriggeringRuleCubit _cubit;

  final TextEditingController _ruleNameController = TextEditingController();
  final TextEditingController _firstTriggerPortController =
      TextEditingController();
  final TextEditingController _lastTriggerPortController =
      TextEditingController();
  final TextEditingController _firstForwardedPortController =
      TextEditingController();
  final TextEditingController _lastForwardedPortController =
      TextEditingController();

  List<PortRangeTriggeringRule> _rules = [];

  @override
  void initState() {
    _cubit = context.read<PortRangeTriggeringRuleCubit>();
    _rules = widget.args['rules'] ?? [];
    final PortRangeTriggeringRule? rule = widget.args['edit'];
    if (rule != null) {
      _ruleNameController.text = rule.description;
      _firstTriggerPortController.text = '${rule.firstTriggerPort}';
      _lastTriggerPortController.text = '${rule.lastTriggerPort}';
      _firstForwardedPortController.text = '${rule.firstForwardedPort}';
      _lastForwardedPortController.text = '${rule.lastForwardedPort}';
      _cubit.goEdit(_rules, rule);
    } else {
      _cubit.goAdd(_rules);
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortRangeTriggeringRuleCubit,
        PortRangeTriggeringRuleState>(builder: (context, state) {
      return StyledAppPageView(
        scrollable: true,
        title: getAppLocalizations(context).single_port_forwarding,
        actions: [
          AppTertiaryButton(
            getAppLocalizations(context).save,
            onTap: () {
              final rule = PortRangeTriggeringRule(
                  isEnabled: true,
                  firstTriggerPort: int.parse(_firstTriggerPortController.text),
                  lastTriggerPort: int.parse(_lastTriggerPortController.text),
                  firstForwardedPort:
                      int.parse(_firstForwardedPortController.text),
                  lastForwardedPort:
                      int.parse(_lastForwardedPortController.text),
                  description: _ruleNameController.text);
              _cubit.save(rule).then((value) {
                if (value) {
                  if (_cubit.isEdit()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      AppToastHelp.positiveToast(context,
                          text: getAppLocalizations(context).rule_updated),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      AppToastHelp.positiveToast(context,
                          text: getAppLocalizations(context).rule_added),
                    );
                  }

                  context.pop(true);
                }
              });
            },
          ),
        ],
        child: AppBasicLayout(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.semiBig(),
              if (state is EditPortRangeTriggeringRule)
                ..._buildEditContents(state)
              else
                ..._buildAddContents(state)
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildAddContents(PortRangeTriggeringRuleState state) {
    return buildInputForms();
  }

  List<Widget> _buildEditContents(EditPortRangeTriggeringRule state) {
    return [
      AppPanelWithSwitch(
        value: state.rule.isEnabled,
        title: getAppLocalizations(context).rule_enabled,
        onChangedEvent: (value) {},
      ),
      ...buildInputForms(),
      AppTertiaryButton(
        getAppLocalizations(context).delete_rule,
        onTap: () {
          _cubit.delete().then((value) {
            if (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                AppToastHelp.positiveToast(context,
                    text: getAppLocalizations(context).rule_deleted),
              );
              context.pop(true);
            }
          });
        },
      ),
    ];
  }

  List<Widget> buildInputForms() {
    return [
      AppTextField(
          headerText: getAppLocalizations(context).rule_name,
          hintText: getAppLocalizations(context).rule_name,
          controller: _ruleNameController),
      const AppGap.semiSmall(),
      administrationSection(
        title: getAppLocalizations(context).triggered_range,
        content: Column(
          children: [
            const AppGap.regular(),
            AppTextField(
                headerText: getAppLocalizations(context).start_port,
                hintText: getAppLocalizations(context).end_port,
                inputType: TextInputType.number,
                controller: _firstTriggerPortController),
            const AppGap.regular(),
            AppTextField(
                headerText: getAppLocalizations(context).start_port,
                hintText: getAppLocalizations(context).end_port,
                inputType: TextInputType.number,
                controller: _lastTriggerPortController),
            const AppGap.regular(),
          ],
        ),
      ),
      administrationSection(
        title: getAppLocalizations(context).forwarded_range,
        content: Column(
          children: [
            const AppGap.regular(),
            AppTextField(
                headerText: getAppLocalizations(context).start_port,
                hintText: getAppLocalizations(context).end_port,
                inputType: TextInputType.number,
                controller: _firstForwardedPortController),
            const AppGap.regular(),
            AppTextField(
                headerText: getAppLocalizations(context).start_port,
                hintText: getAppLocalizations(context).end_port,
                inputType: TextInputType.number,
                controller: _lastForwardedPortController),
            const AppGap.regular(),
          ],
        ),
      ),
    ];
  }
}
