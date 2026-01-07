import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/composed/app_list_card.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/wifi_settings/providers/displayed_mac_filtering_devices_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
    final state = ref.watch(wifiBundleProvider);

    return UiKitPageView.withSliver(
      title: loc(context).filteredDevices,
      menu: UiKitMenuConfig(
        title: '',
        items: [
          UiKitMenuItem(
            label: loc(context).edit,
            icon: AppFontIcons.edit,
            onTap: state.current.privacy.denyMacAddresses.isNotEmpty
                ? () {
                    _toggleEdit();
                  }
                : null,
          ),
        ],
      ),
      menuPosition: MenuPosition.top,
      bottomBar: _isEdit
          ? UiKitBottomBarConfig(
              positiveLabel: loc(context).remove,
              negativeLabel: loc(context).cancel,
              isPositiveEnabled: true,
              isDestructive: true,
              onPositiveTap: () {
                ref
                    .read(wifiBundleProvider.notifier)
                    .removeMacFilterSelection(_selectedMACs);
                _toggleEdit();
              },
              isNegativeEnabled: true,
              onNegativeTap: () {
                _toggleEdit();
              },
            )
          : UiKitBottomBarConfig(
              positiveLabel: loc(context).done,
              isPositiveEnabled: true,
              onPositiveTap: () {
                context.pop();
              },
            ),
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppListCard(
            key: const Key('selectFromMyDeviceList'),
            title: AppText.labelLarge(loc(context).selectFromMyDeviceList),
            trailing: !_isEdit ? const AppIcon.font(AppFontIcons.add) : null,
            onTap: !_isEdit
                ? () {
                    _pickDevices();
                  }
                : null,
          ),
          AppGap.sm(),
          AppListCard(
            key: const Key('manuallyAddDevice'),
            title: AppText.labelLarge(loc(context).manuallyAddDevice),
            trailing: !_isEdit ? const AppIcon.font(AppFontIcons.add) : null,
            onTap: !_isEdit
                ? () {
                    _showManuallyAddModal();
                  }
                : null,
          ),
          AppGap.sm(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: AppText.labelLarge(loc(context).filteredDevices),
          ),
          _buildFilteredDevices(),
        ],
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
      'connection': 'wireless',
      'selected': ref.read(wifiBundleProvider).current.privacy.denyMacAddresses
    });
    final temp = ref.read(wifiBundleProvider).current.privacy.denyMacAddresses;
    if (results != null) {
      final newMacs = results.map((e) => e.macAddress).toList();
      // temp and newMacs do XOR
      final added = newMacs.toSet().difference(temp.toSet());
      final removed = temp.toSet().difference(newMacs.toSet());
      ref.read(wifiBundleProvider.notifier).setMacAddressList(
          [...added, ...temp..removeWhere((e) => removed.contains(e))]);
    }
  }

  Widget _buildFilteredDevices() {
    final state = ref.watch(macFilteringDeviceListProvider);
    return state.isEmpty
        ? SizedBox(
            height: 180,
            child: AppCard(
              child: Center(
                child: AppText.bodyMedium(loc(context).noFilteredDevices),
              ),
            ),
          )
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.length,
            itemBuilder: (context, index) {
              final device = state[index];
              final isSelected = _selectedMACs.contains(device.macAddress);
              return AppCard(
                isSelected: isSelected,
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
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    if (_isEdit) ...[
                      IgnorePointer(
                        child: AppCheckbox(
                          value: _selectedMACs.contains(device.macAddress),
                          onChanged: (value) {},
                        ),
                      ),
                      AppGap.lg(),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppText.labelLarge(device.name),
                          AppGap.xs(),
                          AppText.bodyMedium(device.macAddress),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              if (index != state.length - 1) {
                return AppGap.sm();
              } else {
                return const Center();
              }
            },
          );
  }

  _showManuallyAddModal() async {
    final controller = TextEditingController();
    bool isValid = false;
    bool isDuplicate = false;
    final result = await showSubmitAppDialog<String?>(
      context,
      title: loc(context).macAddress,
      contentBuilder: (context, setState, onSubmit) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppMacAddressTextField(
            key: const Key('macAddressTextField'),
            controller: controller,
            label: loc(context).macAddress,
            onChanged: (text) {
              setState(() {
                isValid = InputValidator([MACAddressRule()])
                    .validate(controller.text);
                isDuplicate = ref
                    .read(macFilteringDeviceListProvider)
                    .any((device) => device.macAddress == controller.text);
              });
            },
            invalidFormatMessage: loc(context).invalidMACAddress,
          ),
          if (!isValid || isDuplicate)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: AppText.bodySmall(
                loc(context).invalidMACAddress,
                color: Theme.of(context).colorScheme.error,
              ),
            )
        ],
      ),
      event: () async {
        return controller.text.toUpperCase();
      },
      checkPositiveEnabled: () => isValid && !isDuplicate,
    );
    if (result != null) {
      ref.read(wifiBundleProvider.notifier).setMacFilterSelection([result]);
    }
  }
}
