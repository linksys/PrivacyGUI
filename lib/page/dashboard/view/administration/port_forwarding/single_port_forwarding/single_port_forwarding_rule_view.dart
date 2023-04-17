import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/router/single_port_forwarding_rule.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/input_fields/input_field_with_action.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/single_port_forwarding/bloc/single_port_forwarding_rule_cubit.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/administration_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/util/logger.dart';

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

  bool _isBehindRouter = false;
  StreamSubscription? _subscription;

  final TextEditingController _ruleNameController = TextEditingController();
  final TextEditingController _externalPortController = TextEditingController();
  final TextEditingController _internalPortController = TextEditingController();
  final TextEditingController _deviceIpAddressController =
      TextEditingController();
  bool _isDeviceIpValid = true;
  String _protocol = 'Both';
  List<SinglePortForwardingRule> _rules = [];

  @override
  void initState() {
    _cubit = context.read<SinglePortForwardingRuleCubit>();
    _subscription = context.read<ConnectivityCubit>().stream.listen((state) {
      logger.d('IP detail royterType: ${state.connectivityInfo.routerType}');
      _isBehindRouter =
          state.connectivityInfo.routerType == RouterType.behindManaged;
    });
    _isBehindRouter =
        context.read<ConnectivityCubit>().state.connectivityInfo.routerType ==
            RouterType.behindManaged;
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
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SinglePortForwardingRuleCubit,
        SinglePortForwardingRuleState>(builder: (context, state) {
      return BasePageView(
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
                      showSuccessSnackBar(
                          context, getAppLocalizations(context).rule_updated);
                    } else {
                      showSuccessSnackBar(
                          context, getAppLocalizations(context).rule_added);
                    }

                    ref.read(navigationsProvider.notifier).popWithResult(true);
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
              ref.read(navigationsProvider.notifier).popWithResult(true);
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
          titleText: getAppLocalizations(context).external_port,
          hintText: getAppLocalizations(context).external_port,
          customPrimaryColor: Colors.black,
          inputType: TextInputType.number,
          controller: _externalPortController),
      box8(),
      InputField(
          titleText: getAppLocalizations(context).internal_port,
          hintText: getAppLocalizations(context).internal_port,
          customPrimaryColor: Colors.black,
          inputType: TextInputType.number,
          controller: _internalPortController),
      box8(),
      InputFieldWithAction(
        controller: _deviceIpAddressController,
        titleText: getAppLocalizations(context).device_ip_address,
        rightTitleText: getAppLocalizations(context).select_device,
        hintText: getAppLocalizations(context).device_ip_address,
        customPrimaryColor: Colors.black,
        isError: !_isDeviceIpValid,
        rightAction: () async {
          String? deviceIp = await ref
              .read(navigationsProvider.notifier)
              .pushAndWait(SelectDevicePtah());
        },
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
            String? protocol = await ref
                .read(navigationsProvider.notifier)
                .pushAndWait(
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
