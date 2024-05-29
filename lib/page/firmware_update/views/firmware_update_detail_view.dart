import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/firmware_update/_firmware_update.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/panel/general_section.dart';

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
        padding: ResponsiveLayout.isMobileLayout(context)
            ? const EdgeInsets.all(80)
            : const EdgeInsets.all(120),
        color: Theme.of(context).colorScheme.background,
        child: isUpdating
            ? SizedBox(
                width: double.infinity,
                child: FirmwareUpdateProcessView(
                  current: current,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleMedium(loc(context).firmware),
                  const AppGap.big(),
                  AppText.bodyMedium(loc(context).firmwareUpdateDesc1),
                  const AppGap.regular(),
                  AppText.bodyMedium(loc(context).firmwareUpdateDesc2),
                  const AppGap.regular(),
                  AppText.bodyMedium(loc(context).firmwareUpdateDesc3),
                  const AppGap.extraBig(),
                  AppSection.withLabel(
                    title: loc(context).details,
                    content: FirmwareUpdateTableView(
                      nodeStatusList: nodeStatusList,
                    ),
                  ),
                  const Spacer(),
                  ResponsiveLayout(
                      desktop: Row(
                        children: [
                          Expanded(
                            child: _updateButton(isUpdating ||
                                    !isFirmwareUpdateAvailable
                                ? null
                                : () {
                                    ref
                                        .read(firmwareUpdateProvider.notifier)
                                        .updateFirmware();
                                  }),
                          ),
                          const AppGap.regular(),
                          Expanded(
                            child: _cancelButton(),
                          ),
                        ],
                      ),
                      mobile: Column(
                        children: [
                          _updateButton(isUpdating || !isFirmwareUpdateAvailable
                              ? null
                              : () {
                                  ref
                                      .read(firmwareUpdateProvider.notifier)
                                      .updateFirmware();
                                }),
                          const AppGap.regular(),
                          _cancelButton(),
                        ],
                      )),
                ],
              ),
      ),
    );
  }

  Widget _updateButton(VoidCallback? onTap) => AppFilledButton.fillWidth(
        loc(context).update,
        onTap: onTap,
      );
  Widget _cancelButton() => AppFilledButton.fillWidth(
        loc(context).cancel,
        onTap: () {
          context.pop();
        },
      );
}
