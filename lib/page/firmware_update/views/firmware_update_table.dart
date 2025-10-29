import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

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
        1: IntrinsicColumnWidth(flex: 3),
        2: IntrinsicColumnWidth(flex: 1),
      },
      children: [
        TableRow(
          children: [
            TableCell(child: AppText.labelMedium(loc(context).node)),
            TableCell(child: AppText.labelMedium(loc(context).firmwareVersion)),
            TableCell(child: AppText.labelMedium(loc(context).model)),
          ],
        ),
        ...widget.nodeStatusList.mapIndexed((index, child) {
          return TableRow(
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image(
                        semanticLabel: 'device image',
                        image: CustomTheme.of(context).getRouterImage(
                              routerIconTestByModel(
                                  modelNumber: child.$1.modelNumber ?? ''),
                            ),
                        fit: BoxFit.cover,
                        width: 72,
                        height: 72,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyMedium(child.$1.getDeviceName()),
                          child.$2.availableUpdate != null
                              ? AppText.bodyMedium(
                                  loc(context).updateAvailable,
                                  color: Theme.of(context).colorScheme.error,
                                  maxLines: 5,
                                )
                              : AppText.bodyMedium(
                                  loc(context).upToDate,
                                  color: Colors.green,
                                  maxLines: 5,
                                )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyMedium(child.$1.unit.firmwareVersion ?? ''),
                    if (child.$2.availableUpdate != null) ...[
                      const Icon(Icons.arrow_drop_down),
                      AppText.bodyMedium(
                          child.$2.availableUpdate?.firmwareVersion ?? ''),
                    ],
                  ],
                ),
              ),
              TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: AppText.bodyMedium(child.$1.modelNumber ?? '')),
            ],
          );
        }),
      ],
    );
  }
}
