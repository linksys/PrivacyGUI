import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying master router information.
///
/// For custom layout (Bento Grid) only.
/// - Compact: Router image + Location name
/// - Normal: Standard list of details (Model, SN, FW)
/// - Expanded: Detailed view with larger typography/spacing
class CustomMasterNodeInfo extends DisplayModeConsumerWidget {
  const CustomMasterNodeInfo({
    super.key,
    super.displayMode,
  });

  @override
  double getLoadingHeight(DisplayMode mode) => switch (mode) {
        DisplayMode.compact => 80,
        DisplayMode.normal => 150,
        DisplayMode.expanded => 200,
      };

  @override
  Widget buildCompactView(BuildContext context, WidgetRef ref) {
    // Compact: Just image and location/name centered
    final master = ref.watch(instantTopologyProvider).root.children.first;
    final masterIcon = ref.watch(dashboardHomeProvider).masterIcon;

    return AppInkWell(
      customColor: Colors.transparent,
      customBorderWidth: 0,
      onTap: () => _navigateToNodeDetail(context, ref, master.data.deviceId),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 48,
                child: SharedWidgets.resolveRouterImage(
                  context,
                  masterIcon,
                  size: 48,
                ),
              ),
              AppGap.md(),
              Flexible(
                child: AppText.labelMedium(
                  master.data.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildNormalView(BuildContext context, WidgetRef ref) {
    return _buildDetailView(context, ref, isExpanded: false);
  }

  @override
  Widget buildExpandedView(BuildContext context, WidgetRef ref) {
    return _buildDetailView(context, ref, isExpanded: true);
  }

  Widget _buildDetailView(
    BuildContext context,
    WidgetRef ref, {
    required bool isExpanded,
  }) {
    final master = ref.watch(instantTopologyProvider).root.children.first;
    final masterIcon = ref.watch(dashboardHomeProvider).masterIcon;
    final wanPortConnection =
        ref.watch(dashboardHomeProvider).wanPortConnection;
    final isMasterOffline =
        master.data.isOnline == false || wanPortConnection == 'None';

    final content = Row(
      children: [
        // Router Image
        SizedBox(
          width: isExpanded ? 120 : 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SharedWidgets.resolveRouterImage(
                context,
                masterIcon,
                size: isExpanded ? 112 : 80,
              ),
              if (isExpanded) ...[
                AppGap.md(),
                AppText.labelMedium(
                  master.data.location,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        // Details Table
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isExpanded ? AppSpacing.xl : AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isExpanded) ...[
                  AppText.titleSmall(master.data.location),
                  AppGap.md(),
                ],
                Table(
                  border: const TableBorder(),
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    _buildRow(
                      context,
                      loc(context).connection,
                      isMasterOffline
                          ? '--'
                          : (master.data.isWiredConnection == true)
                              ? loc(context).wired
                              : loc(context).wireless,
                    ),
                    _buildRow(
                      context,
                      loc(context).model,
                      master.data.model,
                    ),
                    _buildRow(
                      context,
                      loc(context).serialNo,
                      master.data.serialNumber,
                    ),
                    if (master.data.ipAddress.isNotEmpty)
                      _buildRow(
                        context,
                        'IP Address', // TODO: Use loc(context).ipAddress if available
                        master.data.ipAddress,
                      ),
                    if (master.data.macAddress.isNotEmpty)
                      _buildRow(
                        context,
                        'MAC Address', // TODO: Use loc(context).macAddress if available
                        master.data.macAddress,
                      ),
                    _buildFirmwareRow(
                      context,
                      master.data.fwVersion,
                      !isMasterOffline && master.data.fwUpToDate == false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (isExpanded) {
      return AppInkWell(
        customColor: Colors.transparent,
        customBorderWidth: 0,
        onTap: () => _navigateToNodeDetail(context, ref, master.data.deviceId),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
          ],
        ),
      );
    }

    return AppInkWell(
      customColor: Colors.transparent,
      customBorderWidth: 0,
      onTap: () => _navigateToNodeDetail(context, ref, master.data.deviceId),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: content,
    );
  }

  TableRow _buildRow(BuildContext context, String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md, bottom: 4),
          child: AppText.labelMedium('$label:'),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AppText.bodyMedium(value),
        ),
      ],
    );
  }

  TableRow _buildFirmwareRow(
      BuildContext context, String version, bool hasUpdate) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md, bottom: 4),
          child: AppText.labelMedium('${loc(context).fwVersion}:'),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          children: [
            AppText.bodyMedium(version),
            if (hasUpdate)
              SharedWidgets.nodeFirmwareStatusWidget(
                context,
                true,
                () {
                  context.pushNamed(RouteNamed.firmwareUpdateDetail);
                },
              ),
          ],
        ),
      ],
    );
  }

  void _navigateToNodeDetail(
      BuildContext context, WidgetRef ref, String deviceId) {
    ref.read(nodeDetailIdProvider.notifier).state = deviceId;
    context.pushNamed(RouteNamed.nodeDetails);
  }
}

// Keep old name as alias for backward compatibility
@Deprecated('Use CustomMasterNodeInfo instead')
typedef DashboardMasterNodeInfo = CustomMasterNodeInfo;
