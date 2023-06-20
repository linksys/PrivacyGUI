import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/port_range_forwarding/bloc/port_range_forwarding_rule_cubit.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';
import 'package:linksys_moab/route/model/administration_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PortRangeForwardingRuleView extends ArgumentsConsumerStatelessView {
  const PortRangeForwardingRuleView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider(
      create: (context) => PortRangeForwardingRuleCubit(
          repository: context.read<RouterRepository>()),
      child: PortRangeForwardingRuleContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class PortRangeForwardingRuleContentView extends ArgumentsConsumerStatefulView {
  const PortRangeForwardingRuleContentView({super.key, super.next, super.args});

  @override
  ConsumerState<PortRangeForwardingRuleContentView> createState() =>
      _AddRuleContentViewState();
}

class _AddRuleContentViewState
    extends ConsumerState<PortRangeForwardingRuleContentView> {
  late final PortRangeForwardingRuleCubit _cubit;

  final TextEditingController _ruleNameController = TextEditingController();
  final TextEditingController _firstExternalPortController =
      TextEditingController();
  final TextEditingController _lastExternalPortController =
      TextEditingController();
  final TextEditingController _deviceIpAddressController =
      TextEditingController();
  String _protocol = 'Both';
  List<PortRangeForwardingRule> _rules = [];

  @override
  void initState() {
    _cubit = context.read<PortRangeForwardingRuleCubit>();
    _rules = widget.args['rules'] ?? [];
    final rule = widget.args['edit'];
    if (rule != null) {
      _ruleNameController.text = rule.description;
      _firstExternalPortController.text = '${rule.externalPort}';
      _lastExternalPortController.text = '${rule.internalPort}';
      _deviceIpAddressController.text = rule.internalServerIPAddress;
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
    return BlocBuilder<PortRangeForwardingRuleCubit,
        PortRangeForwardingRuleState>(builder: (context, state) {
      return StyledAppPageView(
        scrollable: true,
        title: getAppLocalizations(context).port_range_forwarding,
        actions: [
          AppTertiaryButton(
            getAppLocalizations(context).save,
            onTap: () {
              final rule = PortRangeForwardingRule(
                  isEnabled: true,
                  firstExternalPort:
                      int.parse(_firstExternalPortController.text),
                  protocol: _protocol,
                  internalServerIPAddress: _deviceIpAddressController.text,
                  lastExternalPort: int.parse(_lastExternalPortController.text),
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

                  ref.read(navigationsProvider.notifier).popWithResult(true);
                }
              });
            },
          )
        ],
        child: AppBasicLayout(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppGap.semiBig(),
              if (state is EditPortRangeForwardingRule)
                ..._buildEditContents(state)
              else
                ..._buildAddContents(state)
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildAddContents(PortRangeForwardingRuleState state) {
    return buildInputForms();
  }

  List<Widget> _buildEditContents(EditPortRangeForwardingRule state) {
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
              ref.read(navigationsProvider.notifier).popWithResult(true);
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
      AppTextField(
          headerText: getAppLocalizations(context).start_port,
          hintText: getAppLocalizations(context).start_port,
          inputType: TextInputType.number,
          controller: _firstExternalPortController),
      const AppGap.semiSmall(),
      AppTextField(
          headerText: getAppLocalizations(context).end_port,
          hintText: getAppLocalizations(context).end_port,
          inputType: TextInputType.number,
          controller: _lastExternalPortController),
      const AppGap.semiSmall(),
      AppTextField(
        controller: _deviceIpAddressController,
        hintText: getAppLocalizations(context).device_ip_address,
        headerText: getAppLocalizations(context).device_ip_address,
        ctaText: getAppLocalizations(context).select_device,
        // TODO: need to fix
        textValidator: () =>
            _cubit.isDeviceIpValidate(_deviceIpAddressController.text),
        onCtaTap: () async {
          String? deviceIp = await ref
              .read(navigationsProvider.notifier)
              .pushAndWait(SelectDevicePtah());
        },
      ),
      const AppGap.semiSmall(),
      AppPanelWithInfo(
        title: getAppLocalizations(context).protocol,
        infoText: getProtocolTitle(_protocol),
        onTap: () async {
          String? protocol = await ref
              .read(navigationsProvider.notifier)
              .pushAndWait(
                  SelectProtocolPath()..args = {'selected': _protocol});
          if (protocol != null) {
            setState(() {
              _protocol = protocol;
            });
          }
        },
      ),
    ];
  }

  String getProtocolTitle(String key) {
    if (key == 'UDP') {
      return getAppLocalizations(context).udp;
    } else if (key == 'TCP') {
      return getAppLocalizations(context).tcp;
    } else {
      return getAppLocalizations(context).udp_and_tcp;
    }
  }
}
