import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/app_settings/temperature_unit.dart';
import 'package:privacy_gui/providers/app_settings/temperature_unit_provider.dart';
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

    // The router's own MAC, not the master node's ID. On FLWRT 2.0 the master
    // node is identified only through DataElements, which answers after the
    // device list does, so at login, on every refresh and whenever DataElements
    // has no controller row the node's ID is the literal 'GATEWAY' (#1665).
    final macAddress = info.baseMacAddress;

    // The CPU's temperature from the system monitor's latest poll (#1926), so
    // it moves while the page is open. `info` is the session-cached SystemInfo,
    // read at login, and would hold the login-time value.
    final cpuTemperature = ref.watch(uspSystemMonitorProvider
        .select((s) => s.latest?.cpuTemperatureCelsius));
    final temperatureUnit = ref.watch(temperatureUnitProvider);

    // Hostname and the detail link still come from the master node: the link
    // needs a node lookup key, and the synthetic master resolves too.
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final masterNode = devicesData?.nodes.where((n) => n.isMaster).firstOrNull;
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
              // The temperature sits beside the manufacturer, inside the hero,
              // so it is above the fold at the card's default height (#1926).
              // A `Wrap`, so a card too narrow for both moves the tag to a
              // line of its own instead of overflowing.
              Wrap(
                spacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppText.bodySmall(
                    info.manufacturer,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  if (cpuTemperature != null)
                    _temperatureTag(
                        context, ref, cpuTemperature, temperatureUnit),
                ],
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
              if (macAddress != null)
                InfoGridItem(
                  label: 'MAC',
                  value: macAddress,
                  copyable: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// The CPU temperature in [unit], as a tag a tap switches between °C and °F.
  /// The pick is saved with the other app settings, so it outlives the session
  /// and wins over the browser's region from then on (`temperatureUnitProvider`).
  Widget _temperatureTag(
    BuildContext context,
    WidgetRef ref,
    int celsius,
    TemperatureUnit unit,
  ) {
    // Named for screen readers, which would otherwise hear a bare number.
    return Semantics(
      container: true,
      label: loc(context).temperature,
      child: AppTag(
        label: switch (unit) {
          TemperatureUnit.celsius => loc(context).temperatureCelsius(celsius),
          TemperatureUnit.fahrenheit =>
            loc(context).temperatureFahrenheit(fahrenheitOf(celsius)),
        },
        identifier: 'device-info-temperature',
        onTap: () {
          final settings = ref.read(appSettingsProvider);
          ref.read(appSettingsProvider.notifier).update(settings.copyWith(
                temperatureUnit: () => switch (unit) {
                  TemperatureUnit.celsius => TemperatureUnit.fahrenheit,
                  TemperatureUnit.fahrenheit => TemperatureUnit.celsius,
                },
              ));
        },
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
              // Through the shared wrapper, so this hand-rolled footer carries
              // the same boundary and the same handle as the ten rendered by the
              // template — this card only hand-rolls because its route needs a
              // `deviceId` the template cannot pass (#1301, #1450).
              child: cardDetailLink(
                context,
                label: label,
                child: InkWell(
                  // Through the shared helper, so a presented copy of this
                  // footer closes its presentation first (#1453).
                  onTap: () => navigateFromCard(
                    context,
                    (router) => router.pushNamed(
                      RouteNamed.uspNodeDetail,
                      queryParameters: {'deviceId': deviceId},
                    ),
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
