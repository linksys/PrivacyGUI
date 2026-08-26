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

    // Three bands, not two. The tablet band — `AppLayoutConfig`'s
    // `600 < w <= 905` — used to take the desktop arm's three columns, and three
    // columns of a 601px screen are 152.3px each: *narrower* than the 240px one
    // column of a 320px phone gives the same card. That is where #1380's sweep
    // found this page's worst card overflow (`el` and 10 others, up to +29px in
    // the header row below), and no card can be made to fit a box that is
    // narrower than the phone's. Two columns at 601px is ~236px, and the header
    // row is clean there.
    final isMobile = context.isMobileLayout;
    final crossAxisCount = isMobile
        ? 1
        : context.isTabletLayout
            ? 2
            : 3;
    // The extent is the card's content height, and 120 is that sum plus 2px
    // rather than a round number: AppCard's own padding (`AppSpacing.lg ×
    // spacingFactor`, 19px top and bottom) + the 36px icon tile + two
    // `AppSpacing.xs` gaps + one 20px `titleSmall` line + one 16px `bodySmall`
    // line = 118. It was 112, which is 6px short of its own content in all 26
    // locales — the shortfall is locale-independent because both text rows are
    // capped at one line here. The 2px is the same shaping margin the non-mobile
    // arm has always carried: it keeps 152 over a sum of 150, its description
    // being allowed three lines (48px) rather than one.
    // `page_surface_overflow_test.dart` guards both sums against a theme whose
    // `spacingFactor` moves the 19px.
    final mainAxisExtent = isMobile ? 120.0 : 152.0;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A `Wrap`, not a `Row` — and not a `Row` with an `Expanded` heading
          // either. It was `spaceBetween` with two inflexible children, so the
          // icon-bearing `Store` button took the width it asked for and left the
          // heading the remainder: over by up to +49px at 320px in 16 locales
          // (#1380). Expanding the heading moves the overflow rather than
          // removing it, because the heading is a *single word* in every locale
          // ("Applications", "Εφαρμογές", "Приложения"), so 7 locales then broke
          // mid-word inside an 85–113px box asking for 124–150px. A box that
          // cannot hold one word of a heading is the row being wrong for the
          // screen, so the button drops below the heading when the two do not
          // fit and nothing shrinks. `WrapAlignment.spaceBetween` keeps the wide
          // widths pixel-identical to what the `Row` gave them; both directions
          // are guarded in test/page/_shared/page_surface_overflow_test.dart.
          //
          // The `SizedBox` is what makes that "pixel-identical" true. A `Wrap`
          // sizes itself to its widest *run*, not to its constraint, so on a
          // 1441px page an unconstrained one would be ~300px wide and
          // `spaceBetween` would have no free space left to distribute — the
          // button would sit beside the heading instead of at the far edge. A
          // tight width restores the `Row`'s geometry.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                AppText.headlineSmall(loc(context).apps),
                AppButton(
                  label: loc(context).store,
                  icon: AppIcon.font(Icons.storefront),
                  onTap: () {
                    final token =
                        ref.read(uspClientProvider)?.sessionToken ?? '';
                    openUrl('${Uri.base.origin}/app-store/?token=$token');
                  },
                ),
              ],
            ),
          ),
          AppGap.xl(),
          SizedBox(
            height: (apps.length / crossAxisCount).ceil() * mainAxisExtent +
                kDefaultToolbarHeight,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: isMobile ? AppSpacing.sm : AppSpacing.md,
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
