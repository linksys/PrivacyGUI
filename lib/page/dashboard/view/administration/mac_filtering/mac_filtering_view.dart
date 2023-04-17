import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/picker/simple_item_picker.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/util/logger.dart';

import '../common_widget.dart';
import 'bloc/cubit.dart';

class MacFilteringView extends ArgumentsConsumerStatelessView {
  const MacFilteringView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider(
      create: (context) => MacFilteringCubit(context.read<RouterRepository>()),
      child: MacFilteringContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class MacFilteringContentView extends ArgumentsConsumerStatefulView {
  const MacFilteringContentView({super.key, super.next, super.args});

  @override
  ConsumerState<MacFilteringContentView> createState() =>
      _MacFilteringContentViewState();
}

class _MacFilteringContentViewState
    extends ConsumerState<MacFilteringContentView> {
  late final MacFilteringCubit _cubit;

  bool _isBehindRouter = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    _cubit = context.read<MacFilteringCubit>();

    _subscription = context.read<ConnectivityCubit>().stream.listen((state) {
      logger.d('IP detail royterType: ${state.connectivityInfo.routerType}');
      _isBehindRouter =
          state.connectivityInfo.routerType == RouterType.behindManaged;
    });
    _isBehindRouter =
        context.read<ConnectivityCubit>().state.connectivityInfo.routerType ==
            RouterType.behindManaged;

    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MacFilteringCubit, MacFilteringState>(
      builder: (context, state) {
        return BasePageView(
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
          ),
          child: BasicLayout(
            crossAxisAlignment: CrossAxisAlignment.start,
            content: Column(
              children: [
                box24(),
                administrationTile(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  title: title(getAppLocalizations(context).wifi_mac_filters),
                  value: Switch.adaptive(
                    value: state.status != MacFilterStatus.off,
                    onChanged: (value) {
                      _cubit.setEnable(value);
                    },
                  ),
                ),
                box24(),
                ..._buildEnabledContent(state)
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildEnabledContent(MacFilteringState state) {
    return state.status != MacFilterStatus.off
        ? [
            administrationTile(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                title: title(getAppLocalizations(context).access),
                value: subTitle(state.status.name),
                onPress: () async {
                  final String? selected = await ref
                      .read(navigationsProvider.notifier)
                      .pushAndWait(SimpleItemPickerPath()
                        ..args = {
                          'items': [
                            Item(
                              title: getAppLocalizations(context).allow_access,
                              description: getAppLocalizations(context)
                                  .allow_access_description,
                              id: MacFilterStatus.allow.name,
                            ),
                            Item(
                              title: getAppLocalizations(context).deny_access,
                              description: getAppLocalizations(context)
                                  .deny_access_description,
                              id: MacFilterStatus.deny.name,
                            ),
                          ],
                          'selected': state.status.name,
                        });
                  if (selected != null) {
                    _cubit.setAccess(selected);
                  }
                }),
            administrationTwoLineTile(
              tileHeight: null,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              title: Row(
                children: [
                  Expanded(
                      child:
                          Text(getAppLocalizations(context).device_ip_address)),
                  SimpleTextButton(
                    text: getAppLocalizations(context).select_device,
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      // String? deviceIp = await ref.read(navigationsProvider.notifier)
                      //     .pushAndWait(SelectDevicePtah());
                    },
                  ),
                ],
              ),
              value: InkWell(
                onTap: () async {
                  String? macAddress = await ref
                      .read(navigationsProvider.notifier)
                      .pushAndWait(MacFilteringInputPath());
                  if (macAddress != null) {
                    // TODO query devices name and save device
                    // showSuccessSnackBar(context, 'message');
                  }
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(getAppLocalizations(context).enter_mac_address),
                  ),
                ),
              ),
            ),
            _buildFilteredDevices(state),
          ]
        : [];
  }

  Widget _buildFilteredDevices(MacFilteringState state) {
    return state.selectedDevices.isEmpty
        ? Expanded(
            child: Center(
              child: subTitle(
                  getAppLocalizations(context).no_filtered_devices_yet),
            ),
          )
        : administrationSection(
            title: getAppLocalizations(context).filtered_devices,
            content: Column(
              children: [],
            ),
          );
  }
}
