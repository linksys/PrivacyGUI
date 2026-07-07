import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/apps/models/app_info_ui_model.dart';
import 'package:privacy_gui/page/apps/providers/usp_apps_notifier.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/util/url_helper/url_helper.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspAppsView extends ConsumerWidget {
  const UspAppsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspAppsProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).apps,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      onRefresh: () => ref.refresh(uspAppsProvider.future),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, stack) => _buildError(context, ref),
          data: (appsState) => _buildContent(context, ref, appsState),
        );
      },
    );
  }

  // Apps are served as static lighttpd JSON (NOT USP/TR-181), so failures are
  // plain `Exception`s, not `ServiceError`s — this page keeps its own error
  // widget rather than the ServiceError-based `ServiceErrorView`. We show a
  // localized message instead of the raw exception text.
  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppGap.xl(),
          AppText.titleMedium(loc(context).unableToLoadApps),
          AppGap.xxl(),
          AppButton(
            label: loc(context).retry,
            onTap: () => ref.invalidate(uspAppsProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, UspAppsState appsState) {
    final apps = appsState.apps;
    if (apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.font(Icons.apps,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            AppGap.xl(),
            AppText.bodyMedium(loc(context).noAppsInstalled),
          ],
        ),
      );
    }

    final isDesktop = !context.isMobileLayout;
    final crossAxisCount = isDesktop ? 3 : 1;
    final mainAxisExtent = isDesktop ? 152.0 : 112.0;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.headlineSmall(loc(context).apps),
              AppButton(
                label: loc(context).store,
                icon: AppIcon.font(Icons.storefront),
                onTap: () {
                  final token = ref.read(uspClientProvider)?.sessionToken ?? '';
                  openUrl('${Uri.base.origin}/app-store/?token=$token');
                },
              ),
            ],
          ),
          AppGap.xl(),
          SizedBox(
            height: (apps.length / crossAxisCount).ceil() * mainAxisExtent +
                kDefaultToolbarHeight,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: isDesktop ? AppSpacing.md : AppSpacing.sm,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: (205 / 152),
                mainAxisExtent: mainAxisExtent,
              ),
              clipBehavior: Clip.none,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return _AppGridCard(
                  app: app,
                  isNew: appsState.isNew(app.name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App Grid Card
// ---------------------------------------------------------------------------

class _AppGridCard extends ConsumerWidget {
  final AppInfoUIModel app;
  final bool isNew;

  const _AppGridCard({required this.app, this.isNew = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      onTap: app.link.isNotEmpty
          ? () {
              final token = ref.read(uspClientProvider)?.sessionToken ?? '';
              final separator = app.link.contains('?') ? '&' : '?';
              openUrl('${app.link}${separator}token=$token');
            }
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: app.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: AppIcon.font(app.iconData, size: 20),
                ),
              ),
              if (isNew)
                AppBadge(
                  label: loc(context).badgeNew,
                  color: Theme.of(context)
                          .extension<AppColorScheme>()
                          ?.semanticSuccess ??
                      Colors.green,
                ),
              if (app.category == AppCategory.user && !isNew)
                AppBadge(
                  label: loc(context).badgeUser,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: AppText.titleSmall(
              app.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: AppText.bodySmall(
              app.description,
              overflow: TextOverflow.ellipsis,
              maxLines: !context.isMobileLayout ? 3 : 1,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
