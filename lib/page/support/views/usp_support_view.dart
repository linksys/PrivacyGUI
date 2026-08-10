import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/device_credentials_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_dialog.dart';
import 'package:privacy_gui/page/support/faq_data.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Support page — Accordion-based FAQ with expandable categories.
class UspSupportView extends ConsumerWidget {
  const UspSupportView({super.key});

  static final List<FaqCategory> _categories = [
    FaqSetupCategory(),
    FaqConnectivityCategory(),
    FaqSpeedCategory(),
    FaqPasswordCategory(),
    FaqHardwareCategory(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = !context.isMobileLayout;

    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backState: UiKitBackState.none,
      title: loc(context).faqs,
      child: (childContext, constraints) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            width: isDesktop ? childContext.colWidth(8) : double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                AppText.headlineSmall(loc(context).faqs),
                AppGap.lg(),
                // Accordion categories
                ..._categories.map((category) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _FaqCategoryAccordion(category: category),
                    )),
                AppGap.lg(),
                // Remote Assistance (only in local mode, not CA mode)
                if (!GlobalConfig.remote.isActive) _RemoteAssistanceCard(),
                AppGap.lg(),
                // Quick Link footer
                _QuickLinkFooter(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// FAQ Category Accordion
// =============================================================================

class _FaqCategoryAccordion extends ConsumerWidget {
  final FaqCategory category;

  const _FaqCategoryAccordion({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppExpansionPanel.single(
      headerTitle: category.displayString(context),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            category.items.map((item) => _FaqItemRow(item: item)).toList(),
      ),
    );
  }
}

class _FaqItemRow extends ConsumerWidget {
  final FaqItem item;

  const _FaqItemRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => gotoOfficialWebUrl(
        item.url,
        locale: ref.read(appSettingsProvider).locale,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: AppText.bodyMedium(
                item.displayString(context),
                color: colorScheme.primary,
              ),
            ),
            AppIcon.font(
              Icons.open_in_new,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Quick Link Footer
// =============================================================================

class _QuickLinkFooter extends ConsumerWidget {
  const _QuickLinkFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBlock(
      identifier: 'support-visit-linksys',
      onTap: () => gotoOfficialWebUrl(
        linkSupport,
        locale: ref.read(appSettingsProvider).locale,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          AppIcon.font(
            Icons.support_agent,
            size: 24,
            color: colorScheme.primary,
          ),
          AppGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).faqLookingFor),
                AppText.bodySmall(
                  loc(context).faqVisitLinksysSupport,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          AppIcon.font(
            Icons.open_in_new,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Remote Assistance Card
// =============================================================================

class _RemoteAssistanceCard extends ConsumerWidget {
  const _RemoteAssistanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final credentials = ref.watch(deviceCredentialsProvider);

    return LayoutBlock(
      identifier: 'support-remote-assistance',
      onTap: credentials != null
          ? () =>
              showRemoteAssistanceDialog(context, ref, credentials: credentials)
          : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppIcon.font(
              Icons.support_agent,
              size: 24,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          AppGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).remoteAssistance),
                AppText.bodySmall(
                  'Get help from Linksys support',
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          AppIcon.font(
            Icons.chevron_right,
            size: 24,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
