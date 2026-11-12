import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/support/faq_data.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'health/health_dimension.dart';
import 'health/health_dimension_registry.dart';
import 'health/system_health_provider.dart';
import 'widgets/dimension_detail_view.dart';
import 'widgets/health_status_view.dart';
import 'widgets/mascot_toolbar.dart';

/// Dialog provider for the health-based mascot UI.
///
/// Replaces the old fixed-option dialog with:
/// 1. Word cloud showing system health dimensions
/// 2. Toolbar for utility functions (print, FAQ, AI)
/// 3. Dimension expansion for detailed actions
class HealthDialogProvider extends MascotDialogProvider {
  HealthDialogProvider({
    required this.ref,
    required this.controller,
    required this.onPrintReport,
    required this.onOpenThemeStudio,
    required this.onOpenAiAssistant,
    required this.onNavigate,
    required this.getLocale,
    required this.getFaqCategoryTitle,
    required this.getFaqItemTitle,
    required this.isThemeStudioEnabled,
    required this.getRouterTime,
    required this.l10n,
  });

  final WidgetRef ref;
  final MascotController controller;
  final Future<void> Function() onPrintReport;
  final VoidCallback onOpenThemeStudio;
  final VoidCallback onOpenAiAssistant;
  final void Function(String routeName) onNavigate;
  final Locale? Function() getLocale;
  final bool isThemeStudioEnabled;
  final String Function(FaqCategory category) getFaqCategoryTitle;
  final String Function(FaqItem item) getFaqItemTitle;
  final DateTime? Function() getRouterTime;

  /// The strings for every node this builds, in the app's locale (#1312).
  ///
  /// A node's `text` is what a screen reader announces, and the UI Kit expects
  /// it pre-translated, so it is resolved here rather than in a widget.
  final AppLocalizations l10n;

  static final List<FaqCategory> _faqCategories = [
    FaqSetupCategory(),
    FaqConnectivityCategory(),
    FaqSpeedCategory(),
    FaqPasswordCategory(),
    FaqHardwareCategory(),
  ];

  @override
  Future<MascotDialogNode> getInitialDialog() async {
    final greeting = _buildGreeting();
    return MascotDialogNode.custom(
      id: 'health_dashboard',
      text: greeting,
      barrier: MascotDialogBarrier.dismissible,
      contentBuilder: (ctx, textColor) =>
          _buildHealthDashboard(textColor, greeting),
    );
  }

  Widget _buildHealthDashboard(Color textColor, String greeting) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          greeting,
          color: textColor,
        ),
        const SizedBox(height: 12),
        HealthStatusView(
          textColor: textColor,
          onDimensionTap: _handleDimensionTap,
        ),
        const SizedBox(height: 12),
        MascotToolbar(
          iconColor: textColor,
          showThemeStudio: isThemeStudioEnabled,
          onAction: _handleToolbarAction,
        ),
      ],
    );
  }

  String _buildGreeting() {
    final routerTime = getRouterTime();
    if (routerTime == null) {
      return _randomPick(_generalGreetings);
    }

    final hour = routerTime.hour;
    if (hour >= 5 && hour < 12) {
      return _randomPick(_morningGreetings);
    } else if (hour >= 12 && hour < 17) {
      return _randomPick(_afternoonGreetings);
    } else if (hour >= 17 && hour < 21) {
      return _randomPick(_eveningGreetings);
    } else {
      return _randomPick(_nightGreetings);
    }
  }

  String _randomPick(List<String> options) {
    final index = DateTime.now().millisecondsSinceEpoch % options.length;
    return options[index];
  }

  List<String> get _generalGreetings => [
        l10n.mascotGreetingAny1,
        l10n.mascotGreetingAny2,
        l10n.mascotGreetingAny3,
        l10n.mascotGreetingAny4,
      ];

  List<String> get _morningGreetings => [
        l10n.mascotGreetingMorning1,
        l10n.mascotGreetingMorning2,
        l10n.mascotGreetingMorning3,
        l10n.mascotGreetingMorning4,
      ];

  List<String> get _afternoonGreetings => [
        l10n.mascotGreetingAfternoon1,
        l10n.mascotGreetingAfternoon2,
        l10n.mascotGreetingAfternoon3,
        l10n.mascotGreetingAfternoon4,
      ];

  List<String> get _eveningGreetings => [
        l10n.mascotGreetingEvening1,
        l10n.mascotGreetingEvening2,
        l10n.mascotGreetingEvening3,
        l10n.mascotGreetingEvening4,
      ];

  List<String> get _nightGreetings => [
        l10n.mascotGreetingNight1,
        l10n.mascotGreetingNight2,
        l10n.mascotGreetingNight3,
        l10n.mascotGreetingNight4,
      ];

  void _handleDimensionTap(HealthDimensionType dimensionType) {
    final dimension = HealthDimensions.byType(dimensionType);
    if (dimension == null) return;

    final healthState = ref.read(systemHealthProvider).valueOrNull;
    final score = healthState?[dimensionType];

    // Build evaluation context for summary
    final evalContext = ref.read(healthEvaluationContextProvider);
    final summary = dimension.getSummary(evalContext, l10n);

    controller.showDialog(MascotDialogNode.custom(
      id: 'dimension_${dimensionType.name}',
      text: dimension.resolveName(l10n),
      barrier: MascotDialogBarrier.dismissible,
      contentBuilder: (ctx, textColor) => DimensionDetailView(
        dimension: dimension,
        score: score,
        summary: summary,
        textColor: textColor,
        onBack: () async {
          controller.showDialog(await getInitialDialog());
        },
        onAction: (action) => _handleHealthAction(action),
      ),
    ));
  }

  void _handleHealthAction(HealthAction action) {
    if (action.routeName != null) {
      onNavigate(action.routeName!);
      controller.dismissDialog();
    }
  }

  void _handleToolbarAction(MascotToolbarAction action) {
    switch (action) {
      case MascotToolbarAction.print:
        _handlePrint();
        break;
      case MascotToolbarAction.themeStudio:
        onOpenThemeStudio();
        break;
      case MascotToolbarAction.faq:
        controller.showDialog(_faqCategoriesMenu());
        break;
      case MascotToolbarAction.aiAssistant:
        onOpenAiAssistant();
        break;
    }
  }

  @override
  Future<MascotDialogNode?> handleSelection(
    String nodeId,
    String optionId,
  ) async {
    // FAQ categories
    if (nodeId == 'faq_categories') {
      if (optionId == 'back') return getInitialDialog();
      final categoryIndex = int.tryParse(optionId.replaceFirst('cat_', ''));
      if (categoryIndex != null && categoryIndex < _faqCategories.length) {
        return _faqItemsMenu(_faqCategories[categoryIndex]);
      }
    }

    // FAQ items
    if (nodeId.startsWith('faq_items_')) {
      if (optionId == 'back') return _faqCategoriesMenu();
      if (optionId.startsWith('item_')) {
        final parts = optionId.split('_');
        if (parts.length >= 3) {
          final catIndex = int.tryParse(parts[1]);
          final itemIndex = int.tryParse(parts[2]);
          if (catIndex != null && itemIndex != null) {
            final category = _faqCategories[catIndex];
            final item = category.items[itemIndex];
            gotoOfficialWebUrl(item.url, locale: getLocale());
            return null;
          }
        }
      }
    }

    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Print Report
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _handlePrint() async {
    _showLoading(l10n.mascotGeneratingReport);
    await onPrintReport();
    controller.dismissDialog();
  }

  void _showLoading(String message) {
    controller.showDialog(MascotDialogNode(
      id: 'diagnostics_loading',
      text: message,
      type: MascotDialogType.loading,
      suggestedAnimation: MascotAnimationKey.think,
    ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FAQ
  // ══════════════════════════════════════════════════════════════════════════

  MascotDialogNode _faqCategoriesMenu() {
    return MascotDialogNode(
      id: 'faq_categories',
      text: l10n.mascotFaqPrompt,
      barrier: MascotDialogBarrier.dismissible,
      options: [
        ..._faqCategories.asMap().entries.map((entry) => MascotDialogOption(
              id: 'cat_${entry.key}',
              label: getFaqCategoryTitle(entry.value),
              icon: _iconForCategory(entry.value),
            )),
        MascotDialogOption(
          id: 'back',
          label: l10n.back,
          icon: Icons.arrow_back,
        ),
      ],
    );
  }

  MascotDialogNode _faqItemsMenu(FaqCategory category) {
    final catIndex = _faqCategories.indexOf(category);
    return MascotDialogNode(
      id: 'faq_items_$catIndex',
      text: getFaqCategoryTitle(category),
      barrier: MascotDialogBarrier.dismissible,
      options: [
        ...category.items.asMap().entries.map((entry) => MascotDialogOption(
              id: 'item_${catIndex}_${entry.key}',
              label: getFaqItemTitle(entry.value),
              icon: Icons.open_in_new,
            )),
        MascotDialogOption(
          id: 'back',
          label: l10n.back,
          icon: Icons.arrow_back,
        ),
      ],
    );
  }

  IconData _iconForCategory(FaqCategory category) {
    return switch (category) {
      FaqSetupCategory() => Icons.settings_suggest,
      FaqConnectivityCategory() => Icons.wifi,
      FaqSpeedCategory() => Icons.speed,
      FaqPasswordCategory() => Icons.lock,
      FaqHardwareCategory() => Icons.router,
    };
  }
}
