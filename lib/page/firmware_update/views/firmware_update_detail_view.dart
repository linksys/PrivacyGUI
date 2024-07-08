import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
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
    return isUpdating
        ? _updatingProgressView(ongoingList)
        : StyledAppPageView(
            title: loc(context).firmwareUpdate,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(loc(context).firmwareUpdateDesc1),
                const AppGap.medium(),
                AppText.bodyLarge(loc(context).firmwareUpdateDesc2),
                const AppGap.large2(),
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: statusRecords.length,
                  itemBuilder: (context, index) {
                    final nodeDevice = statusRecords[index].$1;
                    final currentVersion =
                        nodeDevice.unit.firmwareVersion ?? 'Unknown';
                    final newVersion = statusRecords[index]
                        .$2
                        .availableUpdate
                        ?.firmwareVersion;
                    final modelNumber = nodeDevice.modelNumber ?? '';
                    final routerImage = Image(
                      height: 40,
                      image: CustomTheme.of(context).images.devices.getByName(
                            routerIconTestByModel(
                              modelNumber: modelNumber,
                            ),
                          ),
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
                if (isUpdateAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.large5),
                    child: AppFilledButton(
                      loc(context).updateAll,
                      onTap: () {
                        ref
                            .read(firmwareUpdateProvider.notifier)
                            .updateFirmware();
                      },
                    ),
                  ),
              ],
            ),
          );
  }

  Widget _updatingProgressView(
      List<(LinksysDevice, FirmwareUpdateStatus)> list) {
    if (list.isEmpty) {
      // if updating is ture but there are not items in the ongoing list,
      // it is a temporary blank period before getting the operation data
      return const AppFullScreenSpinner();
    }
    return Center(
      child: list.length == 1
          ? _buildProgressIndicator(list.first)
          : GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisExtent: 240,
                childAspectRatio: 1,
                crossAxisCount: 2,
                mainAxisSpacing: Spacing.large5,
                crossAxisSpacing: Spacing.large5,
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
    final operationType =
        record.$2.pendingOperation?.operation ?? 'In progress';
    final progressPercent = record.$2.pendingOperation?.progressPercent ?? 0;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 240,
          height: 240,
          child: CircularProgressIndicator(
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
