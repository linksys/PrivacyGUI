import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/router/port_range_triggering_rule.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/port_range_triggering/bloc/port_range_triggering_rule_cubit.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PortRangeTriggeringRuleView extends ArgumentsStatelessView {
  const PortRangeTriggeringRuleView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PortRangeTriggeringRuleCubit(
          repository: context.read<RouterRepository>()),
      child: PortRangeTriggeringRuleContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class PortRangeTriggeringRuleContentView extends ArgumentsStatefulView {
  const PortRangeTriggeringRuleContentView({super.key, super.next, super.args});

  @override
  State<PortRangeTriggeringRuleContentView> createState() =>
      _AddRuleContentViewState();
}

class _AddRuleContentViewState
    extends State<PortRangeTriggeringRuleContentView> {
  late final PortRangeTriggeringRuleCubit _cubit;

  StreamSubscription? _subscription;

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
    _subscription = context.read<ConnectivityCubit>().stream.listen((state) {
      logger.d('IP detail royterType: ${state.connectivityInfo.routerType}');
    });
    _rules = widget.args['rules'] ?? [];
    final PortRangeTriggeringRule? _rule = widget.args['edit'];
    if (_rule != null) {
      _ruleNameController.text = _rule.description;
      _firstTriggerPortController.text = '${_rule.firstTriggerPort}';
      _lastTriggerPortController.text = '${_rule.lastTriggerPort}';
      _firstForwardedPortController.text = '${_rule.firstForwardedPort}';
      _lastForwardedPortController.text = '${_rule.lastForwardedPort}';
      _cubit.goEdit(_rules, _rule);
    } else {
      _cubit.goAdd(_rules);
    }
    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortRangeTriggeringRuleCubit,
        PortRangeTriggeringRuleState>(builder: (context, state) {
      return StyledLinksysPageView(
        scrollable: true,
        title: getAppLocalizations(context).single_port_forwarding,
        actions: [
          LinksysTertiaryButton(
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

                  NavigationCubit.of(context).popWithResult(true);
                }
              });
            },
          ),
        ],
        child: LinksysBasicLayout(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LinksysGap.semiBig(),
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
      LinksysTertiaryButton(
        getAppLocalizations(context).delete_rule,
        onTap: () {
          _cubit.delete().then((value) {
            if (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                AppToastHelp.positiveToast(context,
                    text: getAppLocalizations(context).rule_deleted),
              );
              NavigationCubit.of(context).popWithResult(true);
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
      const LinksysGap.semiSmall(),
      administrationSection(
        title: getAppLocalizations(context).triggered_range,
        content: Column(
          children: [
            const LinksysGap.regular(),
            AppTextField(
                headerText: getAppLocalizations(context).start_port,
                hintText: getAppLocalizations(context).end_port,
                inputType: TextInputType.number,
                controller: _firstTriggerPortController),
            const LinksysGap.regular(),
            AppTextField(
                headerText: getAppLocalizations(context).start_port,
                hintText: getAppLocalizations(context).end_port,
                inputType: TextInputType.number,
                controller: _lastTriggerPortController),
            const LinksysGap.regular(),
          ],
        ),
      ),
      administrationSection(
        title: getAppLocalizations(context).forwarded_range,
        content: Column(
          children: [
            const LinksysGap.regular(),
            AppTextField(
                headerText: getAppLocalizations(context).start_port,
                hintText: getAppLocalizations(context).end_port,
                inputType: TextInputType.number,
                controller: _firstForwardedPortController),
            const LinksysGap.regular(),
            AppTextField(
                headerText: getAppLocalizations(context).start_port,
                hintText: getAppLocalizations(context).end_port,
                inputType: TextInputType.number,
                controller: _lastForwardedPortController),
            const LinksysGap.regular(),
          ],
        ),
      ),
    ];
  }
}
