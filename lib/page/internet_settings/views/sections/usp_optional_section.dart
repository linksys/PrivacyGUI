import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/usp_info_row.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_section_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Optional settings section: MTU and MAC address clone.
class UspOptionalSection extends ConsumerStatefulWidget {
  final InternetSettingsFeatureState state;
  final bool isEditing;

  const UspOptionalSection({
    super.key,
    required this.state,
    required this.isEditing,
  });

  @override
  ConsumerState<UspOptionalSection> createState() => _UspOptionalSectionState();
}

class _UspOptionalSectionState extends ConsumerState<UspOptionalSection> {
  late TextEditingController _mtuController;
  late TextEditingController _macController;

  @override
  void initState() {
    super.initState();
    final form = widget.state.edited;
    _mtuController =
        TextEditingController(text: form.mtu == 0 ? '' : form.mtu.toString());
    _macController = TextEditingController(text: form.wanMacAddress);
  }

  @override
  void didUpdateWidget(covariant UspOptionalSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.edited != widget.state.edited) {
      final form = widget.state.edited;
      final mtuText = form.mtu == 0 ? '' : form.mtu.toString();
      if (_mtuController.text != mtuText) {
        _mtuController.text = mtuText;
      }
      if (_macController.text != form.wanMacAddress) {
        _macController.text = form.wanMacAddress;
      }
    }
  }

  @override
  void dispose() {
    _mtuController.dispose();
    _macController.dispose();
    super.dispose();
  }

  int get _mtuMin => 576;
  int get _mtuMax {
    final type = widget.state.edited.connectionType;
    // MTU max varies by connection type due to protocol overhead
    return switch (type) {
      UspWanConnectionType.pppoe => 1492, // 1500 - 8 (PPP header)
      // Future: pptp/l2tp => 1460 (tunnel overhead)
      _ => 1500, // Ethernet standard (DHCP, Static, Bridge)
    };
  }

  String? _getMtuError(int mtu) {
    if (mtu < _mtuMin) return 'MTU must be at least $_mtuMin (IPv4 minimum)';
    if (mtu > _mtuMax) return 'MTU must not exceed $_mtuMax';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final form = widget.state.edited;
    final isEditing = widget.isEditing;
    final l = loc(context);

    return UspSectionCard(
      title: l.optionalSettings,
      leadingIcon: Icons.tune,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MTU — manual input only (Auto hidden: TR-181 cannot represent auto state)
          if (!isEditing) ...[
            UspInfoRow(label: l.mtu, value: '${form.mtu}'),
          ] else ...[
            AppTextFormField(
              controller: _mtuController,
              label: '${l.mtu} ($_mtuMin - $_mtuMax)',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > 0) {
                  _updateField((f) => f.copyWith(mtu: parsed));
                }
              },
            ),
            if (_getMtuError(form.mtu) != null) ...[
              AppGap.xs(),
              AppText.bodySmall(
                _getMtuError(form.mtu)!,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ],
          // MAC Address Clone (FW 1.2.1+ supports Ethernet.Link.MACAddress write)
          AppGap.lg(),
          AppDivider(),
          AppGap.lg(),
          AppText.labelLarge(l.macAddressClone),
          AppGap.md(),
          if (!isEditing) ...[
            UspInfoRow(
                label: l.currentMac, value: widget.state.currentMacAddress),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppTextFormField(
                    controller: _macController,
                    label: l.macAddress,
                    onChanged: (v) =>
                        _updateField((f) => f.copyWith(wanMacAddress: v)),
                  ),
                ),
                AppGap.md(),
                AppButton.text(
                  label: 'Clone',
                  onTap: () => _showCloneDialog(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _updateField(
      UspInternetSettingsForm Function(UspInternetSettingsForm) updater) {
    ref.read(uspInternetSettingsProvider.notifier).updateField(updater);
  }

  void _showCloneDialog(BuildContext context) {
    final devicesData = ref.read(devicesDataProvider).valueOrNull;
    final devices = devicesData?.clientDevices
            .where((d) => d.isActive && d.mac.isNotEmpty)
            .toList() ??
        <DeviceUIModel>[];

    if (devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No connected devices found')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clone MAC Address'),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (_, index) {
              final device = devices[index];
              final displayName = device.friendlyName?.isNotEmpty == true
                  ? device.friendlyName!
                  : device.hostName.isNotEmpty
                      ? device.hostName
                      : device.mac;
              return ListTile(
                title: Text(displayName),
                subtitle: Text(device.mac),
                onTap: () {
                  _macController.text = device.mac;
                  _updateField((f) => f.copyWith(wanMacAddress: device.mac));
                  Navigator.of(ctx).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
