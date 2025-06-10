import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

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
  late final List<String> candicateIDs;

  @override
  void initState() {
    final statusRecords =
        ref.read(firmwareUpdateProvider.notifier).getIDStatusRecords();
    candicateIDs = statusRecords.where((record) {
      return record.$2.availableUpdate != null;
    }).map((record) {
      return record.$1.deviceID;
    }).toList();
    logger.i('[FIRMWARE]: Nodes and firmware maps: ${statusRecords.map((e) {
      return (e.$1.friendlyName, e.$2);
    })}');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(firmwareUpdateProvider);
    // Build records for node deivces and their firmware status
    final statusRecords =
        ref.read(firmwareUpdateProvider.notifier).getIDStatusRecords();
    // Find any ongoing updating operations for candicates
    final ongoingList = statusRecords.where((record) {
      return record.$2.pendingOperation != null &&
          candicateIDs.contains(record.$1.deviceID);
    }).toList();
    final isUpdating = state.isUpdating;
    final isUpdateAvailable =
        ref.read(firmwareUpdateProvider.notifier).getAvailableUpdateNumber() >
            0;
    final isWaitingChildren = state.isWaitingChildrenAfterUpdating;
    logger.i(
        '[FIRMWARE]: Any update available: $isUpdateAvailable, isUpdating: $isUpdating');
    logger.i('[FIRMWARE]: Ongoing process: ${ongoingList.map((e) {
      return (e.$1.friendlyName, e.$2);
    })}');
    // When the client fails to reconnect to the router after updating the firmware
    // the retry requests will reach the max limit and the alert will pop up
    ref.listen(firmwareUpdateProvider, (prev, next) {
      if (prev?.isRetryMaxReached == false && next.isRetryMaxReached == true) {
        showRouterNotFoundAlert(context, ref, onComplete: () async {
          ref.read(firmwareUpdateProvider.notifier).finishFirmwareUpdate();
        });
      }
    });
    return isUpdating
        ? _updatingProgressView(ongoingList)
        : StyledAppPageView(
            title: loc(context).firmwareUpdate,
            child: (context, constraints) => AppBasicLayout(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyLarge(loc(context).firmwareUpdateDesc1),
                  const AppGap.medium(),
                  AppText.bodyLarge(loc(context).firmwareUpdateDesc2),
                  const AppGap.large2(),
                  _buildList(statusRecords, isWaitingChildren),
                ],
              ),
              // There will be a short offline period after firmware updating
              // During this period, the mock nodes displayed should not be able to be updated
              footer: isUpdateAvailable && !isWaitingChildren
                  ? Padding(
                      padding: const EdgeInsets.only(top: Spacing.large5),
                      child: AppFilledButton(
                        loc(context).updateAll,
                        onTap: () {
                          ref
                              .read(firmwareUpdateProvider.notifier)
                              .updateFirmware();
                        },
                      ),
                    )
                  : null,
            ),
          );
  }

  Widget _buildList(
    List<(LinksysDevice, FirmwareUpdateStatus)> statusRecords,
    bool isWaitingChildren,
  ) {
    return Expanded(
      child: ListView.separated(
        shrinkWrap: true,
        physics: ScrollPhysics(),
        itemCount: statusRecords.length,
        itemBuilder: (context, index) {
          final nodeDevice = statusRecords[index].$1;
          final updateStatus = statusRecords[index].$2;
          String currentVersion;
          String? newVersion;
          if (isWaitingChildren) {
            // we are using the cached status list that still contains available fw version and old currentVersion
            // For updated nodes, we mock up the versions for a while to avoid a mismatch in displayed info,
            // For nodes without updates, remain the original versions
            currentVersion = updateStatus.availableUpdate?.firmwareVersion ??
                (nodeDevice.unit.firmwareVersion ?? loc(context).unknown);
            newVersion = null;
          } else {
            currentVersion =
                nodeDevice.unit.firmwareVersion ?? loc(context).unknown;
            newVersion = updateStatus.availableUpdate?.firmwareVersion;
          }
          final modelNumber = nodeDevice.modelNumber ?? '';
          final routerImage = Image(
            height: 40,
            image: CustomTheme.of(context).getRouterImage(modelNumber),
          );

          return FirmwareUpdateNodeCard(
            image: routerImage,
            title: nodeDevice.getDeviceName(),
            model: modelNumber,
            currentVersion: currentVersion,
            newVersion: newVersion,
          );
        },
        separatorBuilder: (BuildContext context, int index) =>
            const AppGap.medium(),
      ),
    );
  }

  Widget _updatingProgressView(
      List<(LinksysDevice, FirmwareUpdateStatus)> list) {
    if (list.isEmpty) {
      // if updating is ture but there are not items in the ongoing list,
      // it is a temporary blank period before getting the operation data
      // Or it is the last FwUpdateStatus request with a successful result
      // and without pending operation before isUpdating is set to false
      return const AppFullScreenSpinner();
    }
    return Center(
      child: list.length == 1
          ? _buildProgressIndicator(list.first)
          : GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisExtent:
                    ResponsiveLayout.isMobileLayout(context) ? 4.col : 3.col,
                childAspectRatio: 1,
                crossAxisCount:
                    ResponsiveLayout.isMobileLayout(context) ? 1 : 2,
                mainAxisSpacing: ResponsiveLayout.columnPadding(context),
                crossAxisSpacing: Spacing.large4,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) {
                return _buildProgressIndicator(list[index]);
              },
            ),
    );
  }

  Widget _buildProgressIndicator((LinksysDevice, FirmwareUpdateStatus) record) {
    final name = record.$1.getDeviceName();
    final operationType = _getOperationType(context, record.$2.pendingOperation?.operation);
    final progressPercent = record.$2.pendingOperation?.progressPercent ?? 0;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 240,
          height: 240,
          child: CircularProgressIndicator(
            semanticsLabel: '$operationType spinner',
            value: progressPercent / 100,
            color: Theme.of(context).colorScheme.primary,
            strokeWidth: 8,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText.headlineSmall(name),
            const AppGap.large2(),
            AppText.bodyLarge(operationType),
            AppText.bodyLarge('$progressPercent %'),
          ],
        )
      ],
    );
  }

    String _getOperationType(BuildContext context, String? operation) {
    final lowerOperation = operation?.toLowerCase() ?? '';
    return switch (lowerOperation) {
      'downloading' || 'checking' => loc(context).firmwareDownloadingTitle,
      'rebooting' => loc(context).firmwareRebootingTitle,
      'installing' => loc(context).firmwareInstallingTitle,
      _ => loc(context).firmwareDownloadingTitle,
    };
  }
}

class FirmwareUpdateNodeCard extends StatelessWidget {
  final Image image;
  final String title;
  final String model;
  final String currentVersion;
  final String? newVersion;

  const FirmwareUpdateNodeCard({
    required this.image,
    required this.title,
    required this.model,
    required this.currentVersion,
    this.newVersion,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: SizedBox(
        height: 76,
        child: Row(
          children: [
            image,
            const AppGap.medium(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge('$title ($model)'),
                const AppGap.small3(),
                AppText.bodyMedium(loc(context).currentVersion(currentVersion)),
                if (newVersion != null)
                  AppText.bodyMedium(loc(context).newVersion(newVersion!))
              ],
            ),
            if (newVersion != null)
              Expanded(
                child: AppText.bodyMedium(
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  loc(context).updateAvailable,
                  color: Theme.of(context).colorScheme.error,
                ),
              )
            else
              Expanded(
                child: AppText.bodyMedium(
                  textAlign: TextAlign.right,
                  loc(context).upToDate,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
