import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspDeviceInfoCard extends ConsumerWidget {
  final SystemInfoUIModel? info;

  const UspDeviceInfoCard({super.key, this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info =
        this.info ?? ref.watch(systemInfoDataProvider).valueOrNull?.model;
    if (info == null) return const CardSkeleton.info(rows: 5);

    // Get MAC and hostname from master node
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final masterNode = devicesData?.nodes.where((n) => n.isMaster).firstOrNull;
    final macAddress = masterNode?.deviceId;
    final hostName = masterNode?.displayName;

    final iconName = routerIconTestByModel(
      modelNumber: info.modelName,
      hardwareVersion: info.hardwareVersion,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final density = CardDensityScope.of(context);

    // The line the hero paints largest, and so the line the degraded forms owe
    // the reader: the node's own name when it has one, the model otherwise.
    final heroValue =
        hostName != null && hostName.isNotEmpty && hostName != info.modelName
            ? hostName
            : info.modelName;

    return DashboardCardTemplate(
      title: loc(context).deviceInformation,
      // Only in the degraded forms, so nothing changes above the threshold
      // (#1288) — compact in practice, since the popup form has no header and no
      // icon. The same router artwork as the hero, at header size — this card
      // identifies a specific product, so a generic glyph would be a downgrade
      // the other two cards do not have to make.
      leading: density == CardDensity.normal
          ? null
          : Image(
              image: DeviceImageHelper.getRouterImage(iconName),
              width: BlockConstants.iconMd,
              height: BlockConstants.iconMd,
            ),
      popupValue: heroValue,
      footer: masterNode != null && masterNode.deviceId.isNotEmpty
          ? _buildNodeDetailFooter(context, masterNode.deviceId)
          : null,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device hero block - model name with icon
          HeroBlock(
            compact: density == CardDensity.compact,
            leading: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Image(
                image: DeviceImageHelper.getRouterImage(iconName),
                width: 72,
                height: 72,
              ),
            ),
            children: [
              // The two-line/one-line split is `heroValue`'s definition read
              // backwards: the model gets a subtitle exactly when it is not
              // already the headline.
              AppText.titleLarge(heroValue),
              if (heroValue != info.modelName) ...[
                AppGap.xxs(),
                AppText.bodyMedium(info.modelName),
              ],
              AppGap.xs(),
              AppText.bodySmall(
                info.manufacturer,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          AppGap.sm(),
          // Firmware & Hardware - 2 columns
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.system_update,
                  label: loc(context).firmware,
                  value: info.softwareVersion,
                  color: colorScheme.primary,
                ),
              ),
              AppGap.sm(),
              Expanded(
                child: MetricTile(
                  icon: Icons.memory,
                  label: loc(context).hardware,
                  value: info.hardwareVersion,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          AppGap.sm(),
          // Serial & MAC - side by side with copy
          InfoGrid(
            items: [
              InfoGridItem(
                label: loc(context).serial,
                value: info.serialNumber,
                copyable: true,
              ),
              if (macAddress != null && macAddress.isNotEmpty)
                InfoGridItem(
                  label: 'MAC',
                  value: macAddress.toUpperCase(),
                  copyable: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNodeDetailFooter(BuildContext context, String deviceId) {
    final label = loc(context).viewDetails;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppDivider(),
        AppGap.md(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Both `Flexible`s are #1227's detail-footer shape, replicated
            // verbatim from `DashboardCardTemplate._buildDetailFooter`. Safe to
            // flex the link here for the reason given there: the row is
            // end-aligned, so a short link's unused share is stranded at the
            // *start* where it is invisible, and a row that already fits lays
            // out exactly as before.
            Flexible(
              child: Semantics(
                // Own boundary, or the grid item absorbs this tap action across
                // the whole card — see DashboardCardTemplate._buildDetailFooter
                // for the full reasoning (#1301).
                container: true,
                button: true,
                label: label,
                // Same derivation as the template's footer (#1450), so this
                // card's entry is addressable even though it needs a
                // `deviceId` the template cannot pass and so hand-rolls the
                // footer.
                identifier: cardDetailIdentifier(context),
                child: InkWell(
                  onTap: () => context.pushNamed(
                    RouteNamed.uspNodeDetail,
                    queryParameters: {'deviceId': deviceId},
                  ),
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The arrow keeps its 14px; the label is what shortens.
                      Flexible(
                        child: AppText.labelMedium(
                          label,
                          color: Theme.of(context).colorScheme.primary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppGap.xs(),
                      Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
