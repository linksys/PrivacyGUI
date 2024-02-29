import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/firmware_update_provider.dart';
import 'package:linksys_app/page/firmware_update/_firmware_update.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/panel/general_section.dart';
import 'package:material_symbols_icons/symbols.dart';

class FirmwareUpdateDetailView extends ConsumerStatefulWidget {
  const FirmwareUpdateDetailView({
    super.key,
  });

  @override
  ConsumerState<FirmwareUpdateDetailView> createState() =>
      _FirmwareUpdateDetailViewState();
}

class _FirmwareUpdateDetailViewState
    extends ConsumerState<FirmwareUpdateDetailView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final nodeStatusList =
        (ref.watch(firmwareUpdateProvider).nodesStatus ?? []).map((nodeStatus) {
      final nodes = ref.read(deviceManagerProvider).nodeDevices;

      return (
        nodeStatus is NodesFirmwareUpdateStatus
            ? nodes.firstWhere((node) => node.deviceID == nodeStatus.deviceUUID)
            : ref.read(deviceManagerProvider).masterDevice,
        nodeStatus
      );
    }).toList();
    final current = nodeStatusList.firstWhereOrNull((e) {
      return e.$2.pendingOperation != null;
    });
    final isUpdating = ref.watch(firmwareUpdateProvider).isUpdating;
    final isFirmwareUpdateAvailable = ref
            .watch(firmwareUpdateProvider)
            .nodesStatus
            ?.any((e) => e.availableUpdate != null) ??
        false;

    return Center(
      child: Container(
        padding: EdgeInsets.all(120),
        color: Theme.of(context).colorScheme.background,
        child: isUpdating
            ? FirmwareUpdateProcessView(
                current: current,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleMedium('Firmware Update'),
                  const AppGap.big(),
                  AppText.bodyMedium('Get the latest feature and fixed.'),
                  const AppGap.regular(),
                  AppText.bodyMedium(
                      'Your router will restart once the update is complete. Devices will reconnect on their own.'),
                  const AppGap.regular(),
                  AppText.bodyMedium(
                      'The Linksys app might restart once your system is ready again.'),
                  const AppGap.extraBig(),
                  // ..._nodeStatusList.map((e) {
                  //   return AppText.bodyLarge(
                  //       '${e.$1.getDeviceName()} - ${e.$1.unit.firmwareVersion} - ${e.$2.availableUpdate?.firmwareVersion}');
                  // }).toList(),
                  AppSection.withLabel(
                    title: 'Details',
                    content: FirmwareUpdateTableView(
                      nodeStatusList: nodeStatusList,
                    ),
                    headerAction: AppIconButton.noPadding(
                      icon: Symbols.refresh,
                      onTap: () {
                        ref
                            .read(firmwareUpdateProvider.notifier)
                            .checkFirmwareUpdateStream();
                      },
                    ),
                  ),
                  const Spacer(),
                  AppFilledButton.fillWidth(
                    'Update',
                    onTap: isUpdating || !isFirmwareUpdateAvailable
                        ? null
                        : () {
                            ref
                                .read(firmwareUpdateProvider.notifier)
                                .updateFirmware();
                          },
                  ),
                  const AppGap.regular(),
                  AppFilledButton.fillWidth(
                    'Cancel',
                    onTap: () {
                      context.pop();
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
