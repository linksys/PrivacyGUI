import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_feature_state.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/page/static_routing/providers/usp_static_routing_notifier.dart';
import 'package:privacy_gui/page/static_routing/views/dialogs/static_route_dialog.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspStaticRoutingView extends ConsumerWidget {
  const UspStaticRoutingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspStaticRoutingProvider);
    final status = state.status;

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).staticRouting,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspAdvancedSettings,
      onRefresh: () =>
          ref.read(uspStaticRoutingProvider.notifier).fetch(forceRemote: true),
      bottomBar: _buildBottomBar(context, ref, state),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (status.isLoading) {
          return const Center(child: AppLoader());
        }
        if (status.error != null) {
          return ServiceErrorView(
            error: status.error,
            title: loc(context).failedToLoadSettings,
            onRetry: () => ref
                .read(uspStaticRoutingProvider.notifier)
                .fetch(forceRemote: true),
          );
        }
        return _buildContent(context, ref, state);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Bar
  // ---------------------------------------------------------------------------

  UiKitBottomBarConfig? _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    StaticRoutingFeatureState state,
  ) {
    if (!state.isDirty) return null;
    return UiKitBottomBarConfig(
      positiveLabel: loc(context).save,
      isPositiveEnabled: !state.status.isSaving,
      onPositiveTap: () => _onSave(context, ref),
      onNegativeTap: () => ref.read(uspStaticRoutingProvider.notifier).revert(),
    );
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    StaticRoutingFeatureState state,
  ) {
    final routes = state.settings.current.routes;
    final isSaving = state.status.isSaving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          loc(context).staticRoutingPageDesc,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        AppGap.xl(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.titleMedium(loc(context).staticRoutes),
            AppIconButton(
              icon: AppIcon.font(Icons.add, size: 20),
              onTap: isSaving ? null : () => _showAddDialog(context, ref),
            ),
          ],
        ),
        AppGap.lg(),
        if (routes.isEmpty)
          DetailEmptyBlock(
            icon: Icons.alt_route,
            message: loc(context).noStaticRoutes,
          )
        else
          ...routes.asMap().entries.map((entry) =>
              _buildRouteCard(context, ref, entry.key, entry.value, isSaving)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Route Card
  // ---------------------------------------------------------------------------

  Widget _buildRouteCard(
    BuildContext context,
    WidgetRef ref,
    int index,
    StaticRouteUIModel route,
    bool isSaving,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LayoutBlock(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            AppSwitch(
              value: route.enabled,
              scale: 0.8,
              onChanged: isSaving
                  ? null
                  : (value) => ref
                      .read(uspStaticRoutingProvider.notifier)
                      .toggleRoute(index, value),
            ),
            AppGap.md(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                    route.name.isNotEmpty ? route.name : loc(context).unnamed,
                  ),
                  AppText.bodySmall(
                    '${route.destIpAddress} / ${route.destSubnetMask}',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  AppText.bodySmall(
                    loc(context).gatewayLabel(
                      route.gatewayIpAddress.isNotEmpty
                          ? route.gatewayIpAddress
                          : '-',
                      route.interfaceName,
                    ),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            AppIconButton(
              icon: AppIcon.font(Icons.edit, size: 18),
              onTap: isSaving
                  ? null
                  : () => _showEditDialog(context, ref, index, route),
            ),
            AppIconButton(
              icon: AppIcon.font(Icons.delete_outline, size: 18),
              onTap: isSaving
                  ? null
                  : () => ref
                      .read(uspStaticRoutingProvider.notifier)
                      .deleteRoute(index),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    // Await the LAN data so subnet validation is never bypassed by a fast tap
    // while lanDataProvider is still AsyncLoading (cold start / network reset).
    // valueOrNull would return null there and silently skip validateRoute's
    // gateway-subnet block — the core #1082 fix.
    final lanData = await ref.read(lanDataProvider.future);
    if (!context.mounted) return;
    final result = await showAppDialog<StaticRouteDialogResult>(
      context: context,
      builder: (_) => StaticRouteDialog(
        lanIp: lanData.model.ipAddress,
        lanSubnetMask: lanData.model.subnetMask,
      ),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspStaticRoutingProvider.notifier).addRoute(
          StaticRouteUIModel(
            enabled: result.enabled,
            name: result.name,
            destIpAddress: result.destIpAddress,
            destSubnetMask: result.destSubnetMask,
            gatewayIpAddress: result.gatewayIpAddress,
            interfaceName: result.interfaceName,
          ),
        );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, int index,
      StaticRouteUIModel route) async {
    // Await LAN data (see _showAddDialog) so edit-mode subnet validation is not
    // bypassed while lanDataProvider is still loading.
    final lanData = await ref.read(lanDataProvider.future);
    if (!context.mounted) return;
    final result = await showAppDialog<StaticRouteDialogResult>(
      context: context,
      builder: (_) => StaticRouteDialog(
        route: route,
        lanIp: lanData.model.ipAddress,
        lanSubnetMask: lanData.model.subnetMask,
      ),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspStaticRoutingProvider.notifier).editRoute(
          index,
          route.copyWith(
            enabled: result.enabled,
            name: result.name,
            destIpAddress: result.destIpAddress,
            destSubnetMask: result.destSubnetMask,
            gatewayIpAddress: result.gatewayIpAddress,
            interfaceName: result.interfaceName,
          ),
        );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    try {
      await doSomethingWithSpinner(
        context,
        ref.read(uspStaticRoutingProvider.notifier).save(),
      );
      if (context.mounted) {
        showSuccessSnackBar(context, loc(context).staticRoutesSaved);
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }
}
