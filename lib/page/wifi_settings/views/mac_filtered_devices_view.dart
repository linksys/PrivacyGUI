import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/wifi_settings/providers/displayed_mac_filtering_devices_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class FilteredDevicesView extends ArgumentsConsumerStatefulView {
  const FilteredDevicesView({super.key, super.args});

  @override
  ConsumerState<FilteredDevicesView> createState() =>
      _FilteredDevicesViewState();
}

class _FilteredDevicesViewState extends ConsumerState<FilteredDevicesView> {
  bool _isEdit = false;
  final List<String> _selectedMACs = [];

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
    final state = ref.watch(instantPrivacyProvider);

    return StyledAppPageView(
      title: loc(context).filteredDevices,
      scrollable: true,
      actions: [
        AppTextButton(
          loc(context).edit,
          icon: LinksysIcons.edit,
          onTap: state.denyMacAddresses.isNotEmpty
              ? () {
                  _toggleEdit();
                }
              : null,
        )
      ],
      bottomBar: _isEdit
          ? InversePageBottomBar(
              isPositiveEnabled: true,
              onPositiveTap: () {
                ref
                    .read(instantPrivacyProvider.notifier)
                    .removeSelection(_selectedMACs, true);
                _toggleEdit();
              },
              positiveLabel: loc(context).remove,
              isNegitiveEnabled: true,
              onNegitiveTap: () {
                _toggleEdit();
              },
            )
          : PageBottomBar(
              isPositiveEnabled: true,
              onPositiveTap: () {
                context.pop();
              },
              positiveLabel: loc(context).done),
      child: AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppListCard(
              title: AppText.labelLarge(loc(context).selectFromMyDeviceList),
              trailing: !_isEdit ? const Icon(LinksysIcons.add) : null,
              onTap: !_isEdit
                  ? () {
                      _pickDevices();
                    }
                  : null,
            ),
            const AppGap.small2(),
            AppListCard(
              title: AppText.labelLarge(loc(context).manuallyAddDevice),
              trailing: !_isEdit ? const Icon(LinksysIcons.add) : null,
              onTap: !_isEdit
                  ? () {
                      _showManuallyAddModal();
                    }
                  : null,
            ),
            const AppGap.small2(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.medium),
              child: AppText.labelLarge(loc(context).filteredDevices),
            ),
            _buildFilteredDevices(),
          ],
        ),
      ),
    );
  }

  void _toggleEdit() {
    setState(() {
      _isEdit = !_isEdit;
      _selectedMACs.clear();
    });
  }

  void _pickDevices() async {
    final results = await context
        .pushNamed<List<DeviceListItem>?>(RouteNamed.devicePicker, extra: {
      'type': 'mac',
      'selected': ref.read(instantPrivacyProvider).denyMacAddresses
    });
    final temp = ref.read(instantPrivacyProvider).denyMacAddresses;
    if (results != null) {
      final newMacs = results.map((e) => e.macAddress).toList();
      // temp and newMacs do XOR
      final added = newMacs.toSet().difference(temp.toSet());
      final removed = temp.toSet().difference(newMacs.toSet());
      ref.read(instantPrivacyProvider.notifier).setSelection(
          [...added, ...temp..removeWhere((e) => removed.contains(e))], true);
    }
  }

  Widget _buildFilteredDevices() {
    final state = ref.watch(macFilteringDeviceListProvider);
    return state.isEmpty
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
            height: 76.0 * state.length + Spacing.small2 * state.length,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.length,
              itemBuilder: (context, index) {
                final device = state[index];
                return SizedBox(
                  height: 76,
                  child: AppSettingCard(
                    color: _selectedMACs.contains(device.macAddress)
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    borderColor: _selectedMACs.contains(device.macAddress)
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    onTap: _isEdit
                        ? () {
                            setState(() {
                              if (_selectedMACs.contains(device.macAddress)) {
                                _selectedMACs.remove(device.macAddress);
                              } else {
                                _selectedMACs.add(device.macAddress);
                              }
                            });
                          }
                        : null,
                    leading: _isEdit
                        ? IgnorePointer(
                            child: AppCheckbox(
                              value: _selectedMACs.contains(device.macAddress),
                              onChanged: (value) {},
                            ),
                          )
                        : null,
                    title: device.name,
                    description: device.macAddress,
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                if (index != state.length - 1) {
                  return const AppGap.small2();
                } else {
                  return const Center();
                }
              },
            ),
          );
  }

  _showManuallyAddModal() async {
    final controller = TextEditingController();
    bool isValid = false;
    final result = await showSubmitAppDialog<String?>(
      context,
      title: loc(context).macAddress,
      contentBuilder: (context, setState, onSubmit) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField.macAddress(
            semanticLabel: 'mac address',
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
        return controller.text.toUpperCase();
      },
      checkPositiveEnabled: () => isValid,
    );
    if (result != null) {
      ref.read(instantPrivacyProvider.notifier).setSelection([result], true);
    }
  }
}
