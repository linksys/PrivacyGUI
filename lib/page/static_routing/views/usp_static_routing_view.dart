import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_feature_state.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/page/static_routing/providers/usp_static_routing_notifier.dart';
import 'package:privacy_gui/page/static_routing/services/usp_static_routing_service.dart';
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
      title: 'Static Routing',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      onBackTap: () => context.canPop()
          ? context.pop()
          : context.goNamed(RouteNamed.uspMenu),
      onRefresh: () =>
          ref.read(uspStaticRoutingProvider.notifier).fetch(forceRemote: true),
      bottomBar: _buildBottomBar(context, ref, state),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (status.isLoading) {
          return const Center(child: AppLoader());
        }
        if (status.errorMessage != null) {
          return _buildError(context, ref);
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
      positiveLabel: 'Save',
      isPositiveEnabled: !state.status.isSaving,
      onPositiveTap: () => _onSave(context, ref),
      onNegativeTap: () => ref.read(uspStaticRoutingProvider.notifier).revert(),
    );
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppGap.xl(),
          AppText.titleMedium('Unable to load static routing'),
          AppGap.md(),
          AppButton(
            label: 'Retry',
            onTap: () => ref
                .read(uspStaticRoutingProvider.notifier)
                .fetch(forceRemote: true),
          ),
        ],
      ),
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
          'Manage static IPv4 routes on your network',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        AppGap.xl(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.titleMedium('Static Routes'),
            AppIconButton(
              icon: AppIcon.font(Icons.add, size: 20),
              onTap: isSaving ? null : () => _showAddDialog(context, ref),
            ),
          ],
        ),
        AppGap.lg(),
        if (routes.isEmpty)
          AppText.bodyMedium('No static routes configured')
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
      child: AppCard(
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
            AppGap.sm(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                    route.name.isNotEmpty ? route.name : '(unnamed)',
                  ),
                  AppText.bodySmall(
                    '${route.destIpAddress} / ${route.destSubnetMask}',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  AppText.bodySmall(
                    'Gateway: ${route.gatewayIpAddress.isNotEmpty ? route.gatewayIpAddress : '-'}  ${route.interfaceName}',
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
    final result = await showDialog<StaticRouteDialogResult>(
      context: context,
      builder: (_) => const StaticRouteDialog(),
    );
    if (result == null || !context.mounted) return;
    final svc = ref.read(uspStaticRoutingServiceProvider);
    ref.read(uspStaticRoutingProvider.notifier).addRoute(
          StaticRouteUIModel(
            enabled: result.enabled,
            name: result.name,
            destIpAddress: result.destIpAddress,
            destSubnetMask: result.destSubnetMask,
            gatewayIpAddress: result.gatewayIpAddress,
            interfaceName: result.interfaceName,
            interfacePath: svc.mapDisplayToInterface(result.interfaceName),
          ),
        );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, int index,
      StaticRouteUIModel route) async {
    final result = await showDialog<StaticRouteDialogResult>(
      context: context,
      builder: (_) => StaticRouteDialog(route: route),
    );
    if (result == null || !context.mounted) return;
    final svc = ref.read(uspStaticRoutingServiceProvider);
    ref.read(uspStaticRoutingProvider.notifier).editRoute(
          index,
          route.copyWith(
            enabled: result.enabled,
            name: result.name,
            destIpAddress: result.destIpAddress,
            destSubnetMask: result.destSubnetMask,
            gatewayIpAddress: result.gatewayIpAddress,
            interfaceName: result.interfaceName,
            interfacePath: svc.mapDisplayToInterface(result.interfaceName),
          ),
        );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(uspStaticRoutingProvider.notifier).save();
      if (context.mounted) {
        showSuccessSnackBar(context, 'Static routes saved');
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, 'Failed to save: $e');
      }
    }
  }
}
