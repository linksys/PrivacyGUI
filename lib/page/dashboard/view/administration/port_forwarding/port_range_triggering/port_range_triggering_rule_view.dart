import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/router/port_range_triggering_rule.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/custom_title_input_field.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/port_range_triggering/bloc/port_range_triggering_rule_cubit.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/administration_path.dart';
import 'package:linksys_moab/util/logger.dart';

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

  bool _isBehindRouter = false;
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
      _isBehindRouter =
          state.connectivityInfo.routerType == RouterType.behindManaged;
    });
    _isBehindRouter =
        context.read<ConnectivityCubit>().state.connectivityInfo.routerType ==
            RouterType.behindManaged;
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
      return BasePageView(
        padding: EdgeInsets.zero,
        scrollable: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          // iconTheme:
          // IconThemeData(color: Theme.of(context).colorScheme.primary),
          elevation: 0,
          title: Text(
            getAppLocalizations(context).single_port_forwarding,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            SimpleTextButton(
              text: getAppLocalizations(context).save,
              onPressed: () {
                final rule = PortRangeTriggeringRule(
                    isEnabled: true,
                    firstTriggerPort:
                        int.parse(_firstTriggerPortController.text),
                    lastTriggerPort: int.parse(_lastTriggerPortController.text),
                    firstForwardedPort:
                        int.parse(_firstForwardedPortController.text),
                    lastForwardedPort:
                        int.parse(_lastForwardedPortController.text),
                    description: _ruleNameController.text);
                _cubit.save(rule).then((value) {
                  if (value) {
                    if (_cubit.isEdit()) {
                      showSuccessSnackBar(
                          context, getAppLocalizations(context).rule_updated);
                    } else {
                      showSuccessSnackBar(
                          context, getAppLocalizations(context).rule_added);
                    }

                    NavigationCubit.of(context).popWithResult(true);
                  }
                });
              },
            ),
          ],
        ),
        child: BasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box24(),
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
      administrationTile(
          title: title(getAppLocalizations(context).rule_enabled),
          value: Switch.adaptive(
              value: state.rule.isEnabled, onChanged: (value) {})),
      ...buildInputForms(),
      SimpleTextButton(
        text: getAppLocalizations(context).delete_rule,
        onPressed: () {
          _cubit.delete().then((value) {
            if (value) {
              showSuccessSnackBar(
                  context, getAppLocalizations(context).rule_deleted);
              NavigationCubit.of(context).popWithResult(true);
            }
          });
        },
      ),
    ];
  }

  List<Widget> buildInputForms() {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: InputField(
            titleText: getAppLocalizations(context).rule_name,
            hintText: getAppLocalizations(context).rule_name,
            customPrimaryColor: Colors.black,
            controller: _ruleNameController),
      ),
      box8(),
      administrationSection(
        title: getAppLocalizations(context).triggered_range,
        content: Column(
          children: [
            box16(),
            InputField(
                titleText: getAppLocalizations(context).start_port,
                hintText: getAppLocalizations(context).end_port,
                customPrimaryColor: Colors.black,
                inputType: TextInputType.number,
                controller: _firstTriggerPortController),
            box16(),
            InputField(
                titleText: getAppLocalizations(context).start_port,
                hintText: getAppLocalizations(context).end_port,
                customPrimaryColor: Colors.black,
                inputType: TextInputType.number,
                controller: _lastTriggerPortController),
            box16(),
          ],
        ),
      ),
      administrationSection(
        title: getAppLocalizations(context).forwarded_range,
        content: Column(
          children: [
            box16(),
            InputField(
                titleText: getAppLocalizations(context).start_port,
                hintText: getAppLocalizations(context).end_port,
                customPrimaryColor: Colors.black,
                inputType: TextInputType.number,
                controller: _firstForwardedPortController),
            box16(),
            InputField(
                titleText: getAppLocalizations(context).start_port,
                hintText: getAppLocalizations(context).end_port,
                customPrimaryColor: Colors.black,
                inputType: TextInputType.number,
                controller: _lastForwardedPortController),
            box16(),
          ],
        ),
      ),
    ];
  }
}
