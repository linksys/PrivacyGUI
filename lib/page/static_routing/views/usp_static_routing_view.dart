import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/rule_limit_note.dart';
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
    final ripEnabled = state.settings.current.ripEnabled;
    final isSaving = state.status.isSaving;
    // FW refuses a new route past FWDEV#213's limit; routes past it that an
    // older build saved stay editable.
    final isFull = routes.length >= kMaxStaticRoutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          loc(context).staticRoutingPageDesc,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        AppGap.xl(),
        // 1.0's NAT / Dynamic routing choice, where the router offers it.
        if (ripEnabled != null) ...[
          AppRadioList<bool>(
            selected: ripEnabled,
            itemHeight: 56,
            items: [
              AppRadioListItem(
                identifier: 'static-route-nat',
                title: loc(context).nat,
                value: false,
              ),
              AppRadioListItem(
                identifier: 'static-route-dynamic-routing',
                title: loc(context).dynamicRouting,
                value: true,
              ),
            ],
            onChanged: isSaving
                ? null
                : (_, value) {
                    if (value == null) return;
                    ref
                        .read(uspStaticRoutingProvider.notifier)
                        .setRipEnabled(value);
                  },
          ),
          AppGap.xl(),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.titleMedium(loc(context).staticRoutes),
            AppIconButton(
              identifier: 'static-route-add',
              icon: AppIcon.font(Icons.add, size: 20),
              onTap: isSaving || isFull
                  ? null
                  : () => _showAddDialog(context, ref),
            ),
          ],
        ),
        if (isFull) const RuleLimitNote(),
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
              // Same busy treatment the port-forwarding rule rows carry — see
              // `usp_single_port_tab.dart` for why a null `onChanged` was not one
              // (#1542).
              isLoading: isSaving,
              busySemanticLabel: isSaving ? loc(context).processing : null,
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
              identifier: 'static-route-edit-${route.identifierKey}',
              icon: AppIcon.font(Icons.edit, size: 18),
              onTap: isSaving
                  ? null
                  : () => _showEditDialog(context, ref, index, route),
            ),
            AppIconButton(
              identifier: 'static-route-delete-${route.identifierKey}',
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
    final LanData lanData;
    try {
      lanData = await ref.read(lanDataProvider.future);
    } catch (e) {
      // lanDataProvider can be in AsyncError (router offline, USP timeout,
      // auth failure). Surface it like _onSave instead of letting the throw
      // propagate through the onTap lambda and get swallowed silently.
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
      return;
    }
    if (!context.mounted) return;
    final routes = ref.read(uspStaticRoutingProvider).settings.current.routes;
    final result = await showAppDialog<StaticRouteDialogResult>(
      context: context,
      builder: (_) => StaticRouteDialog(
        lanIp: lanData.model.ipAddress,
        lanSubnetMask: lanData.model.subnetMask,
        otherNames: {for (final r in routes) r.name},
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
    final LanData lanData;
    try {
      lanData = await ref.read(lanDataProvider.future);
    } catch (e) {
      // See _showAddDialog: surface AsyncError instead of swallowing it.
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
      return;
    }
    if (!context.mounted) return;
    final routes = ref.read(uspStaticRoutingProvider).settings.current.routes;
    final result = await showAppDialog<StaticRouteDialogResult>(
      context: context,
      builder: (_) => StaticRouteDialog(
        route: route,
        lanIp: lanData.model.ipAddress,
        lanSubnetMask: lanData.model.subnetMask,
        // By position, not by name: two routes can share one.
        otherNames: {
          for (var i = 0; i < routes.length; i++)
            if (i != index) routes[i].name
        },
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
    } on InvalidInputError catch (e) {
      // A list check before the save, or a refusal FW named (FWDEV#213).
      if (context.mounted) {
        showFailedSnackBar(
          context,
          e.field != null
              ? localizeStaticRoutingError(context, e.field!)
              : localizeServiceError(context, e),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }
}
