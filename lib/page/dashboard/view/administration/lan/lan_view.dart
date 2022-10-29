import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';

import '../common_widget.dart';
import 'bloc/cubit.dart';
import 'bloc/state.dart';

class LANView extends ArgumentsStatelessView {
  const LANView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LANCubit(context.read<RouterRepository>()),
      child: LANContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class LANContentView extends ArgumentsStatefulView {
  const LANContentView({super.key, super.next, super.args});

  @override
  State<LANContentView> createState() => _LANContentViewState();
}

class _LANContentViewState extends State<LANContentView> {
  late final LANCubit _cubit;

  final TextEditingController _ipAddressController = TextEditingController();
  final TextEditingController _subnetMaskController = TextEditingController();
  final TextEditingController _startIPController = TextEditingController();
  final TextEditingController _maxNumUserController = TextEditingController();
  final TextEditingController _clientLeaseController = TextEditingController();
  final TextEditingController _dns1Controller = TextEditingController();
  final TextEditingController _dns2Controller = TextEditingController();
  final TextEditingController _dns3Controller = TextEditingController();
  final TextEditingController _winsController = TextEditingController();

  bool _isBehindRouter = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    _cubit = context.read<LANCubit>();
    _cubit.fetch();
    _subscription = context.read<ConnectivityCubit>().stream.listen((state) {
      logger.d('IP detail royterType: ${state.connectivityInfo.routerType}');
      _isBehindRouter =
          state.connectivityInfo.routerType == RouterType.managedMoab;
    });
    _isBehindRouter =
        context.read<ConnectivityCubit>().state.connectivityInfo.routerType ==
            RouterType.managedMoab;

    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LANCubit, LANState>(builder: (context, state) {
      return BasePageView(
        scrollable: true,
        padding: EdgeInsets.zero,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          // iconTheme:
          // IconThemeData(color: Theme.of(context).colorScheme.primary),
          elevation: 0,
          title: Text(
            getAppLocalizations(context).ip_details,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            SimpleTextButton(
              text: getAppLocalizations(context).save,
              onPressed: () {},
            ),
          ],
        ),
        child: BasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          content: Column(
            children: [
              administrationSection(
                title: getAppLocalizations(context).router_details,
                contentPadding: EdgeInsets.all(24),
                content: Column(
                  children: [
                    InputField(
                      titleText: getAppLocalizations(context).ip_address,
                      controller: _ipAddressController,
                      customPrimaryColor: Colors.black,
                    ),
                    box24(),
                    InputField(
                      titleText: getAppLocalizations(context).subnet_mask,
                      controller: _subnetMaskController,
                      customPrimaryColor: Colors.black,
                    ),
                  ],
                ),
              ),
              box36(),
              administrationSection(
                title: getAppLocalizations(context).dhcp_server,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    box24(),
                    administrationTile(
                        title: Text(getAppLocalizations(context).dhcp_server),
                        value: Switch.adaptive(
                            value: false, onChanged: (value) {})),
                    InputField(
                      titleText: getAppLocalizations(context).start_ip_address,
                      controller: _startIPController,
                      customPrimaryColor: Colors.black,
                    ),
                    box24(),
                    administrationTwoLineTile(
                      tileHeight: null,
                      title: Text(
                          getAppLocalizations(context).max_number_of_users),
                      value: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            child: InputField(
                              titleText: '',
                              controller: _maxNumUserController,
                              customPrimaryColor: Colors.black,
                            ),
                          ),
                          box24(),
                          Text('1 to 245'),
                        ],
                      ),
                      description: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('192.168.1.10 to 192.168.1.29'),
                      ),
                    ),
                    box24(),
                    administrationTwoLineTile(
                      tileHeight: null,
                      title:
                          Text(getAppLocalizations(context).client_lease_time),
                      value: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            child: InputField(
                              titleText: '',
                              controller: _clientLeaseController,
                              customPrimaryColor: Colors.black,
                            ),
                          ),
                          box24(),
                          Text(getAppLocalizations(context).minutes),
                        ],
                      ),
                    ),
                    box24(),
                  ],
                ),
              ),
              administrationSection(
                title: getAppLocalizations(context).dns_settings,
                content: Column(
                  children: [
                    administrationTile(
                      title: Text(getAppLocalizations(context).dns),
                      value: Text('Auto'),
                      onPress: () {},
                    ),
                    administrationTile(
                      title: Text(getAppLocalizations(context).dns),
                      value: Center(),
                      onPress: () {},
                    ),
                  ],
                ),
              ),
              box48(),
            ],
          ),
        ),
      );
    });
  }
}
