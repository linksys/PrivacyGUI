import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_state.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class FirmwareUpdateTableView extends ConsumerStatefulWidget {
  final List<(LinksysDevice, FirmwareUpdateStatus)> nodeStatusList;

  const FirmwareUpdateTableView({super.key, required this.nodeStatusList});

  @override
  ConsumerState<FirmwareUpdateTableView> createState() =>
      _FirmwareUpdateTableViewState();
}

class _FirmwareUpdateTableViewState
    extends ConsumerState<FirmwareUpdateTableView> {
  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(flex: 3),
        1: IntrinsicColumnWidth(flex: 2),
        2: IntrinsicColumnWidth(flex: 2),
        3: IntrinsicColumnWidth(flex: 1),
      },
      children: [
        TableRow(
          children: [
            TableCell(child: AppText.labelMedium('Node')),
            TableCell(child: AppText.labelMedium('Current Version')),
            TableCell(child: AppText.labelMedium('Discoverd Version')),
            TableCell(child: AppText.labelMedium('Model')),
          ],
        ),
        ...widget.nodeStatusList.mapIndexed((index, child) {
          return TableRow(
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Image(
                          image:
                              CustomTheme.of(context).images.devices.getByName(
                                    routerIconTest(
                                        modelNumber:
                                            child.$1.model.modelNumber ?? ''),
                                  ),
                          fit: BoxFit.cover,
                          width: 72,
                          height: 72,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.bodyLarge(child.$1.getDeviceName()),
                        child.$2.availableUpdate != null
                            ? AppText.bodyMedium(
                                'Update available',
                                color: Theme.of(context).colorScheme.error,
                              )
                            : const AppText.bodyMedium(
                                'Up to date',
                                color: Colors.green,
                              )
                      ],
                    ),
                  ],
                ),
              ),
              TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child:
                      AppText.bodyLarge(child.$1.unit.firmwareVersion ?? '')),
              TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: AppText.bodyLarge(
                      child.$2.availableUpdate?.firmwareVersion ?? '')),
              TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: AppText.bodyLarge(child.$1.modelNumber ?? '')),
            ],
          );
        }),
      ],
    );
  }
}
