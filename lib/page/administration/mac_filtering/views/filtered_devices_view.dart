import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/administration/mac_filtering/providers/mac_filtering_provider.dart';
import 'package:linksys_app/page/administration/mac_filtering/providers/mac_filtering_state.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/card/list_card.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class FilteredDevicesView extends ArgumentsConsumerStatefulView {
  const FilteredDevicesView({super.key, super.args});

  @override
  ConsumerState<FilteredDevicesView> createState() =>
      _FilteredDevicesViewState();
}

class _FilteredDevicesViewState extends ConsumerState<FilteredDevicesView> {
  @override
  void initState() {
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
      title: loc(context).filteredDevices,
      scrollable: true,
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppListCard(
              title: AppText.labelLarge(loc(context).selectFromMyDeviceList),
              trailing: const Icon(LinksysIcons.add),
              onTap: () async {
                final results = await context.pushNamed<List<DeviceListItem>?>(
                    RouteNamed.devicePicker,
                    extra: {'type': 'mac'});
                if (results != null) {
                  ref
                      .read(macFilteringProvider.notifier)
                      .setSelection(results.map((e) => e.macAddress).toList());
                }
              },
            ),
            AppListCard(
              title: AppText.labelLarge(loc(context).manuallyAddDevice),
              trailing: const Icon(LinksysIcons.add),
              onTap: () {},
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: AppText.labelLarge(loc(context).filteredDevices),
            ),
            _buildFilteredDevices(state),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredDevices(MacFilteringState state) {
    return state.macAddresses.isEmpty
        ? SizedBox(
            height: 180,
            child: AppCard(
              child: Center(
                child: AppText.bodyMedium(
                    getAppLocalizations(context).noFilteredDevices),
              ),
            ),
          )
        : SizedBox(
            height: 76.0 * state.macAddresses.length,
            child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.macAddresses.length,
                itemBuilder: (context, index) {
                  final device = state.macAddresses[index];
                  return SizedBox(
                      height: 76,
                      child: AppCard(
                          child: Align(
                        alignment: Alignment.centerLeft,
                        child: AppText.labelLarge(device),
                      )));
                }),
          );
  }
}
