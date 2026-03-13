import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/usp_page/static_routing/providers/usp_static_routing_notifier.dart';
import 'package:privacy_gui/usp_page/static_routing/services/usp_static_routing_service.dart';
import 'package:privacy_gui/usp_page/static_routing/views/dialogs/static_route_dialog.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspStaticRoutingView extends ConsumerWidget {
  const UspStaticRoutingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspStaticRoutingProvider);

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
      onRefresh: () => ref.refresh(uspStaticRoutingProvider.future),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, _) => _buildError(context, ref),
          data: (state) => _buildContent(context, ref, state),
        );
      },
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
            onTap: () => ref.invalidate(uspStaticRoutingProvider),
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
    UspStaticRoutingState state,
  ) {
    final isMutating = state.isMutating;
    final routes = state.routes;

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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMutating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  AppIconButton(
                    icon: AppIcon.font(Icons.refresh, size: 20),
                    onTap: () => ref.invalidate(uspStaticRoutingProvider),
                  ),
                AppIconButton(
                  icon: AppIcon.font(Icons.add, size: 20),
                  onTap: isMutating ? null : () => _showAddDialog(context, ref),
                ),
              ],
            ),
          ],
        ),
        AppGap.lg(),
        if (routes.isEmpty)
          AppText.bodyMedium('No static routes configured')
        else
          ...routes.map((r) => _buildRouteCard(context, ref, r, isMutating)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Route Card
  // ---------------------------------------------------------------------------

  Widget _buildRouteCard(
    BuildContext context,
    WidgetRef ref,
    StaticRouteUIModel route,
    bool isMutating,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            AppSwitch(
              value: route.enabled,
              scale: 0.8,
              onChanged: isMutating
                  ? null
                  : (value) => _toggleRoute(context, ref, route, value),
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
              onTap: isMutating
                  ? null
                  : () => _showEditDialog(context, ref, route),
            ),
            AppIconButton(
              icon: AppIcon.font(Icons.delete_outline, size: 18),
              onTap:
                  isMutating ? null : () => _confirmDelete(context, ref, route),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _toggleRoute(BuildContext context, WidgetRef ref,
      StaticRouteUIModel route, bool value) async {
    try {
      await ref
          .read(uspStaticRoutingProvider.notifier)
          .toggleRoute(route.instancePath, value);
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    }
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<StaticRouteDialogResult>(
      context: context,
      builder: (_) => const StaticRouteDialog(),
    );
    if (result == null || !context.mounted) return;
    final svc = ref.read(uspStaticRoutingServiceProvider);
    try {
      await ref.read(uspStaticRoutingProvider.notifier).addRoute(
            name: result.name,
            destIpAddress: result.destIpAddress,
            destSubnetMask: result.destSubnetMask,
            gatewayIpAddress: result.gatewayIpAddress,
            interfacePath: svc.mapDisplayToInterface(result.interfaceName),
            enabled: result.enabled,
          );
      if (context.mounted) showSuccessSnackBar(context, 'Route added');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    }
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, StaticRouteUIModel route) async {
    final result = await showDialog<StaticRouteDialogResult>(
      context: context,
      builder: (_) => StaticRouteDialog(route: route),
    );
    if (result == null || !context.mounted) return;
    final svc = ref.read(uspStaticRoutingServiceProvider);
    try {
      await ref.read(uspStaticRoutingProvider.notifier).updateRoute(
            instancePath: route.instancePath,
            name: result.name,
            destIpAddress: result.destIpAddress,
            destSubnetMask: result.destSubnetMask,
            gatewayIpAddress: result.gatewayIpAddress,
            interfacePath: svc.mapDisplayToInterface(result.interfaceName),
            enabled: result.enabled,
          );
      if (context.mounted) showSuccessSnackBar(context, 'Route updated');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, StaticRouteUIModel route) async {
    final confirmed = await showSimpleAppDialog<bool>(
      context,
      title: 'Delete Route',
      content: AppText.bodyMedium(
          'Delete "${route.name.isNotEmpty ? route.name : 'this route'}"?'),
      actions: [
        AppButton.text(
          label: 'Cancel',
          onTap: () => context.pop(),
        ),
        AppButton.dangerText(
          label: 'Delete',
          onTap: () => context.pop(true),
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(uspStaticRoutingProvider.notifier)
          .deleteRoute(route.instancePath);
      if (context.mounted) showSuccessSnackBar(context, 'Route deleted');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    }
  }
}
