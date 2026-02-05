import 'package:flutter/material.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/page/support/shared_widgets/faq_agent/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Creates and configures the component registry for FAQ Agent UI
ComponentRegistry createFaqComponentRegistry({
  required VoidCallback onRetry,
}) {
  final registry = ComponentRegistry();

  // FAQ search result item
  registry.register('FAQResult', (context, props, {onAction, children}) {
    return AppListTile(
      leading: AppIcon.font(
        props['type'] == 'article'
            ? Icons.article_outlined
            : Icons.forum_outlined,
        size: 20,
      ),
      title: AppText.bodyMedium(props['title'] ?? ''),
      trailing: const AppIcon.font(Icons.open_in_new, size: 16),
      onTap: () {
        final id = props['id'];
        final url = '$kLinksysArticleUrlBase$id';
        gotoOfficialWebUrl(url);
      },
    );
  });

  // No results prompt
  registry.register('NoResults', (context, props, {onAction, children}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.search_off, size: 48, color: Colors.grey),
          AppGap.md(),
          AppText.bodyMedium(
            props['message'] ?? 'No results found',
            textAlign: TextAlign.center,
          ),
          AppGap.md(),
          AppButton.text(
            label: 'Visit Linksys Support',
            onTap: () => gotoOfficialWebUrl(kLinksysSearchApiBase),
          ),
        ],
      ),
    );
  });

  // Network error prompt
  registry.register('NetworkError', (context, props, {onAction, children}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.wifi_off, size: 48, color: Colors.red.shade400),
          AppGap.md(),
          AppText.bodyMedium(
            props['message'] ??
                'Unable to connect. Please check your network.',
            textAlign: TextAlign.center,
          ),
          AppGap.md(),
          AppButton.text(
            label: 'Try Again',
            onTap: onRetry,
          ),
        ],
      ),
    );
  });

  return registry;
}
