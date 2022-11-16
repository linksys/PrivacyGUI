import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/router/port_range_forwarding_rule.dart';
import 'package:linksys_moab/model/router/single_port_forwarding_rule.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/custom_title_input_field.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/port_range_forwarding/bloc/port_range_forwarding_rule_cubit.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/single_port_forwarding/bloc/single_port_forwarding_rule_cubit.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/administration_path.dart';
import 'package:linksys_moab/util/logger.dart';

class PortRangeForwardingRuleView extends ArgumentsStatelessView {
  const PortRangeForwardingRuleView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PortRangeForwardingRuleCubit(repository: context.read<RouterRepository>()),
      child: PortRangeForwardingRuleContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class PortRangeForwardingRuleContentView extends ArgumentsStatefulView {
  const PortRangeForwardingRuleContentView(
      {super.key, super.next, super.args});

  @override
  State<PortRangeForwardingRuleContentView> createState() =>
      _AddRuleContentViewState();
}

class _AddRuleContentViewState
    extends State<PortRangeForwardingRuleContentView> {
  late final PortRangeForwardingRuleCubit _cubit;

  bool _isBehindRouter = false;
  StreamSubscription? _subscription;

  final TextEditingController _ruleNameController = TextEditingController();
  final TextEditingController _firstExternalPortController = TextEditingController();
  final TextEditingController _lastExternalPortController = TextEditingController();
  final TextEditingController _deviceIpAddressController =
      TextEditingController();
  bool _isDeviceIpValid = true;
  String _protocol = 'Both';
  List<PortRangeForwardingRule> _rules = [];

  @override
  void initState() {
    _cubit = context.read<PortRangeForwardingRuleCubit>();
    _subscription = context.read<ConnectivityCubit>().stream.listen((state) {
      logger.d('IP detail royterType: ${state.connectivityInfo.routerType}');
      _isBehindRouter =
          state.connectivityInfo.routerType == RouterType.managedMoab;
    });
    _isBehindRouter =
        context.read<ConnectivityCubit>().state.connectivityInfo.routerType ==
            RouterType.managedMoab;
    _rules = widget.args['rules'] ?? [];
    final _rule = widget.args['edit'];
    if (_rule != null) {
      _ruleNameController.text = _rule.description;
      _firstExternalPortController.text = '${_rule.externalPort}';
      _lastExternalPortController.text = '${_rule.internalPort}';
      _deviceIpAddressController.text = _rule.internalServerIPAddress;
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
    return BlocBuilder<PortRangeForwardingRuleCubit, PortRangeForwardingRuleState>(builder: (context, state) {
      return BasePageView(
        scrollable: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          // iconTheme:
          // IconThemeData(color: Theme.of(context).colorScheme.primary),
          elevation: 0,
          title: Text(
            getAppLocalizations(context).port_range_forwarding,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            SimpleTextButton(
              text: getAppLocalizations(context).save,
              onPressed: () {
                final rule = PortRangeForwardingRule(
                    isEnabled: true,
                    firstExternalPort: int.parse(_firstExternalPortController.text),
                    protocol: _protocol,
                    internalServerIPAddress: _deviceIpAddressController.text,
                    lastExternalPort: int.parse(_lastExternalPortController.text),
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
      InputField(
          titleText: getAppLocalizations(context).rule_name,
          hintText: getAppLocalizations(context).rule_name,
          customPrimaryColor: Colors.black,
          controller: _ruleNameController),
      box8(),
      InputField(
          titleText: getAppLocalizations(context).start_port,
          hintText: getAppLocalizations(context).start_port,
          customPrimaryColor: Colors.black,
          inputType: TextInputType.number,
          controller: _firstExternalPortController),
      box8(),
      InputField(
          titleText: getAppLocalizations(context).end_port,
          hintText: getAppLocalizations(context).end_port,
          customPrimaryColor: Colors.black,
          inputType: TextInputType.number,
          controller: _lastExternalPortController),
      box8(),
      CustomTitleInputField(
        title: Row(
          children: [
            Expanded(
                child: Text(getAppLocalizations(context).device_ip_address)),
            SimpleTextButton(
              text: getAppLocalizations(context).select_device,
              padding: EdgeInsets.zero,
              onPressed: () async {
                String? deviceIp = await NavigationCubit.of(context)
                    .pushAndWait(SelectDevicePtah());
              },
            ),
          ],
        ),
        inputType: TextInputType.text,
        hintText: getAppLocalizations(context).device_ip_address,
        customPrimaryColor: Colors.black,
        controller: _deviceIpAddressController,
        isError: !_isDeviceIpValid,
        onChanged: (value) {
          _isDeviceIpValid = true;
        },
        onFocusChanged: (focus) {
          setState(() {
            _isDeviceIpValid =
                _cubit.isDeviceIpValidate(_deviceIpAddressController.text);
          });
        },
      ),
      box8(),
      administrationTile(
          title: title(getAppLocalizations(context).protocol),
          value: subTitle(getProtocolTitle(_protocol)),
          onPress: () async {
            String? protocol = await NavigationCubit.of(context).pushAndWait(
                SelectProtocolPath()..args = {'selected': _protocol});
            if (protocol != null) {
              setState(() {
                _protocol = protocol;
              });
            }
          }),
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
