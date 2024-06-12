import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/wifi_settings/providers/mac_filtering_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/mac_filtering_state.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/devices/_devices.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/fab/expandable_fab.dart';

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
                    extra: {
                      'type': 'mac',
                      'selected': ref.read(macFilteringProvider).macAddresses
                    });
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
              onTap: () {
                _showManuallyAddModal();
              },
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText.labelLarge(device),
                            // AppIconButton(
                            //   icon: LinksysIcons.delete,
                            //   color: Theme.of(context).colorScheme.error,
                            //   onTap: () {
                            //     ref
                            //         .read(macFilteringProvider.notifier)
                            //         .removeSelection([device]);
                            //   },
                            // ),
                            ExpandableFab(
                              key: ObjectKey(device),
                              distance: 48,
                              icon: LinksysIcons.delete,
                              iconColor: Theme.of(context).colorScheme.error,
                              children: [
                                AppIconButton.filled(
                                  icon: LinksysIcons.check,
                                  onTap: () {
                                    ref
                                        .read(macFilteringProvider.notifier)
                                        .removeSelection([device]);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      )));
                }),
          );
  }

  _showManuallyAddModal() async {
    final controller = TextEditingController();
    bool isValid = false;
    final result = await showSubmitAppDialog<String?>(
      context,
      title: loc(context).macAddress,
      contentBuilder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField.macAddress(
            border: const OutlineInputBorder(),
            controller: controller,
            onChanged: (text) {
              setState(() {
                isValid = InputValidator([MACAddressRule()])
                    .validate(controller.text);
              });
            },
          )
        ],
      ),
      event: () async {
        return controller.text;
      },
      checkPositiveEnabled: () => isValid,
    );
    if (result != null) {
      ref.read(macFilteringProvider.notifier).setSelection([result]);
    }
  }
}
