import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying master router information.
///
/// Extracted from [InternetConnectionWidget] for Bento Grid atomic usage.
/// Shows: Router image, model, serial number, firmware version, connection type.
class DashboardMasterNodeInfo extends ConsumerWidget {
  const DashboardMasterNodeInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardLoadingWrapper(
      loadingHeight: 150,
      builder: (context, ref) => _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final master = ref.watch(instantTopologyProvider).root.children.first;
    final masterIcon = ref.watch(dashboardHomeProvider).masterIcon;
    final wanPortConnection =
        ref.watch(dashboardHomeProvider).wanPortConnection;
    final isMasterOffline =
        master.data.isOnline == false || wanPortConnection == 'None';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: context.isMobileLayout ? 120 : 90,
            child: SharedWidgets.resolveRouterImage(
              context,
              masterIcon,
              size: 112,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.titleMedium(master.data.location),
                  AppGap.lg(),
                  Table(
                    border: const TableBorder(),
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(children: [
                        AppText.labelLarge('${loc(context).connection}:'),
                        AppText.bodyMedium(isMasterOffline
                            ? '--'
                            : (master.data.isWiredConnection == true)
                                ? loc(context).wired
                                : loc(context).wireless),
                      ]),
                      TableRow(children: [
                        AppText.labelLarge('${loc(context).model}:'),
                        AppText.bodyMedium(master.data.model),
                      ]),
                      TableRow(children: [
                        AppText.labelLarge('${loc(context).serialNo}:'),
                        AppText.bodyMedium(master.data.serialNumber),
                      ]),
                      TableRow(children: [
                        AppText.labelLarge('${loc(context).fwVersion}:'),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AppText.bodyMedium(master.data.fwVersion),
                            if (!isMasterOffline) ...[
                              AppGap.lg(),
                              SharedWidgets.nodeFirmwareStatusWidget(
                                context,
                                master.data.fwUpToDate == false,
                                () {
                                  context.pushNamed(
                                      RouteNamed.firmwareUpdateDetail);
                                },
                              ),
                            ]
                          ],
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
