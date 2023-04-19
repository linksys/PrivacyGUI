
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/router/single_port_forwarding_rule.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/single_port_forwarding/bloc/single_port_forwarding_rule_cubit.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/administration_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class SinglePortForwardingRuleView extends ArgumentsConsumerStatelessView {
  const SinglePortForwardingRuleView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider(
      create: (context) => SinglePortForwardingRuleCubit(
          repository: context.read<RouterRepository>()),
      child: SinglePortForwardingRuleContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class SinglePortForwardingRuleContentView
    extends ArgumentsConsumerStatefulView {
  const SinglePortForwardingRuleContentView(
      {super.key, super.next, super.args});

  @override
  ConsumerState<SinglePortForwardingRuleContentView> createState() =>
      _AddRuleContentViewState();
}

class _AddRuleContentViewState
    extends ConsumerState<SinglePortForwardingRuleContentView> {
  late final SinglePortForwardingRuleCubit _cubit;

  final TextEditingController _ruleNameController = TextEditingController();
  final TextEditingController _externalPortController = TextEditingController();
  final TextEditingController _internalPortController = TextEditingController();
  final TextEditingController _deviceIpAddressController =
      TextEditingController();
  String _protocol = 'Both';
  List<SinglePortForwardingRule> _rules = [];

  @override
  void initState() {
    _cubit = context.read<SinglePortForwardingRuleCubit>();
    _rules = widget.args['rules'] ?? [];
    final _rule = widget.args['edit'];
    if (_rule != null) {
      _ruleNameController.text = _rule.description;
      _externalPortController.text = '${_rule.externalPort}';
      _internalPortController.text = '${_rule.internalPort}';
      _deviceIpAddressController.text = _rule.internalServerIPAddress;
      _cubit.goEdit(_rules, _rule);
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
    return BlocBuilder<SinglePortForwardingRuleCubit,
        SinglePortForwardingRuleState>(builder: (context, state) {
      return StyledLinksysPageView(
        title: getAppLocalizations(context).single_port_forwarding,
        actions: [
          LinksysTertiaryButton(
            getAppLocalizations(context).save,
            onTap: () {
              final rule = SinglePortForwardingRule(
                  isEnabled: true,
                  externalPort: int.parse(_externalPortController.text),
                  protocol: _protocol,
                  internalServerIPAddress: _deviceIpAddressController.text,
                  internalPort: int.parse(_internalPortController.text),
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
        scrollable: true,
        child: LinksysBasicLayout(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LinksysGap.semiBig(),
              if (state is EditSinglePortForwardingRule)
                ..._buildEditContents(state)
              else
                ..._buildAddContents(state)
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildAddContents(SinglePortForwardingRuleState state) {
    return buildInputForms();
  }

  List<Widget> _buildEditContents(EditSinglePortForwardingRule state) {
    return [
      AppPanelWithSwitch(
          value: state.rule.isEnabled,
          title: getAppLocalizations(context).rule_enabled),
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
      const LinksysGap.semiSmall(),
      AppTextField(
          headerText: getAppLocalizations(context).external_port,
          hintText: getAppLocalizations(context).external_port,
          inputType: TextInputType.number,
          controller: _externalPortController),
      const LinksysGap.semiSmall(),
      AppTextField(
          headerText: getAppLocalizations(context).internal_port,
          hintText: getAppLocalizations(context).internal_port,
          inputType: TextInputType.number,
          controller: _internalPortController),
      const LinksysGap.semiSmall(),
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
      const LinksysGap.semiSmall(),
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
