import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/picker/simple_item_picker.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/mac_filtering/_mac_filtering.dart';
import 'package:linksys_app/route/constants.dart';

import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class MacFilteringView extends ArgumentsConsumerStatelessView {
  const MacFilteringView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MacFilteringContentView(
      args: super.args,
    );
  }
}

class MacFilteringContentView extends ArgumentsConsumerStatefulView {
  const MacFilteringContentView({super.key, super.args});

  @override
  ConsumerState<MacFilteringContentView> createState() =>
      _MacFilteringContentViewState();
}

class _MacFilteringContentViewState
    extends ConsumerState<MacFilteringContentView> {
  late final MacFilteringNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(macFilteringProvider.notifier);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(macFilteringProvider);
    return StyledAppPageView(
      scrollable: true,
      title: getAppLocalizations(context).mac_filtering,
      child: AppBasicLayout(
        content: Column(
          children: [
            const AppGap.semiBig(),
            AppPanelWithSwitch(
              value: state.status != MacFilterStatus.off,
              title: getAppLocalizations(context).wifi_mac_filters,
              onChangedEvent: (value) {
                _notifier.setEnable(value);
              },
            ),
            const AppGap.semiBig(),
            ..._buildEnabledContent(state)
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEnabledContent(MacFilteringState state) {
    return state.status != MacFilterStatus.off
        ? [
            AppPanelWithInfo(
              title: getAppLocalizations(context).access,
              infoText: state.status.name,
              onTap: () async {
                final String? selected = await context.pushNamed(
                  RouteNamed.itemPicker,
                  queryParameters: {
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
                  },
                );
                if (selected != null) {
                  _notifier.setAccess(selected);
                }
              },
            ),
            AppPanelWithTrailWidget(
              title: getAppLocalizations(context).device_ip_address,
              trailing: AppTertiaryButton.noPadding(
                getAppLocalizations(context).select_device,
                onTap: () async {
                  // String? deviceIp = await ref.read(navigationsProvider.notifier)
                  //     .pushAndWait(SelectDevicePtah());
                },
              ),
            ),
            AppSimplePanel(
              title: getAppLocalizations(context).enter_mac_address,
              onTap: () async {
                String? macAddress =
                    await context.pushNamed(RouteNamed.macFilteringInput);
                if (macAddress != null) {
                  // TODO query devices name and save device
                  // showSuccessSnackBar(context, 'message');
                }
              },
            ),
            _buildFilteredDevices(state),
          ]
        : [];
  }

  Widget _buildFilteredDevices(MacFilteringState state) {
    return state.selectedDevices.isEmpty
        ? Expanded(
            child: Center(
              child: AppText.descriptionSub(
                  getAppLocalizations(context).no_filtered_devices_yet),
            ),
          )
        : Column(
            children: [
              AppText.tags(getAppLocalizations(context).filtered_devices),
              // Add filtered devices
            ],
          );
  }
}
