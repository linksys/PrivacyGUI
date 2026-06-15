import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/page/support/faq_data.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'dashboard_dialog_provider.dart' show DiagnosticsResult;

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
    required this.context,
    required this.controller,
    required this.onRunFullDiagnostics,
    required this.onRunFlowDiagnostics,
    required this.onPrintReport,
    required this.onOpenThemeStudio,
    required this.onOpenAiAssistant,
    required this.getLocale,
    required this.getFaqCategoryTitle,
    required this.getFaqItemTitle,
    required this.isThemeStudioEnabled,
    required this.getRouterTime,
  });

  final WidgetRef ref;
  final BuildContext context;
  final MascotController controller;
  final Future<DiagnosticsResult> Function() onRunFullDiagnostics;
  final Future<DiagnosticsResult> Function(DiagnosticFlow flow)
      onRunFlowDiagnostics;
  final Future<void> Function() onPrintReport;
  final VoidCallback onOpenThemeStudio;
  final VoidCallback onOpenAiAssistant;
  final Locale? Function() getLocale;
  final bool isThemeStudioEnabled;
  final String Function(FaqCategory category) getFaqCategoryTitle;
  final String Function(FaqItem item) getFaqItemTitle;
  final DateTime? Function() getRouterTime;

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
      contentBuilder: (ctx, textColor) =>
          _buildHealthDashboard(textColor, greeting),
    );
  }

  Widget _buildHealthDashboard(Color textColor, String greeting) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
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

  static const _generalGreetings = [
    'Hi there! How can I help?',
    'Hello! Everything running smoothly?',
    'Hey! Need any help?',
    'Welcome back!',
  ];

  static const _morningGreetings = [
    'Good morning! Ready to check your network?',
    'Rise and shine! How\'s the network?',
    'Morning! Everything connected?',
    'Good morning! Need any help?',
  ];

  static const _afternoonGreetings = [
    'Good afternoon! Everything running smoothly?',
    'Hey there! How\'s your day?',
    'Afternoon! Need any help?',
    'Good afternoon! Network check?',
  ];

  static const _eveningGreetings = [
    'Good evening! Winding down?',
    'Evening! Quick network check?',
    'Good evening! How was your day?',
    'Hey! Checking in before bed?',
  ];

  static const _nightGreetings = [
    'Hello, night owl!',
    'Burning the midnight oil?',
    'Late night check-in?',
    'Can\'t sleep? Let\'s check the network!',
  ];

  void _handleDimensionTap(HealthDimensionType dimensionType) {
    final registry = ref.read(healthDimensionRegistryProvider);
    final dimension = registry.getDimension(dimensionType);
    if (dimension == null) return;

    final healthState = ref.read(systemHealthProvider).valueOrNull;
    final score = healthState?[dimensionType];

    // Build evaluation context for summary
    final evalContext = ref.read(healthEvaluationContextProvider);
    final summary = dimension.getSummary(evalContext);

    controller.showDialog(MascotDialogNode.custom(
      id: 'dimension_${dimensionType.name}',
      text: dimension.displayName,
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
      context.push(action.routeName!);
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

    // Diagnostics result
    if (nodeId == 'diagnostics_result') {
      if (optionId == 'back') return _diagnosticsMenu();
      if (optionId == 'main') return getInitialDialog();
    }

    // Diagnostics menu
    if (nodeId == 'diagnostics_menu') {
      if (optionId == 'back') return getInitialDialog();
      if (optionId == 'full') return _runFullDiagnostics();
      final flow = _flowFromOptionId(optionId);
      if (flow != null) return _runFlowDiagnostics(flow);
    }

    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Diagnostics
  // ══════════════════════════════════════════════════════════════════════════

  MascotDialogNode _diagnosticsMenu() {
    return const MascotDialogNode(
      id: 'diagnostics_menu',
      text: 'What would you like to check?',
      options: [
        MascotDialogOption(
          id: 'full',
          label: 'Full diagnostic',
          icon: Icons.checklist,
        ),
        MascotDialogOption(
          id: 'internet',
          label: 'Internet connection',
          icon: Icons.public,
        ),
        MascotDialogOption(
          id: 'wifi',
          label: 'WiFi coverage',
          icon: Icons.wifi,
        ),
        MascotDialogOption(
          id: 'back',
          label: 'Back',
          icon: Icons.arrow_back,
        ),
      ],
    );
  }

  DiagnosticFlow? _flowFromOptionId(String optionId) {
    return switch (optionId) {
      'internet' => DiagnosticFlow.internet,
      'wifi' => DiagnosticFlow.wifiCoverage,
      _ => null,
    };
  }

  Future<MascotDialogNode> _runFullDiagnostics() async {
    _showLoading('Running full diagnostic...');
    final result = await onRunFullDiagnostics();
    return _buildDiagnosticsResult(result);
  }

  Future<MascotDialogNode> _runFlowDiagnostics(DiagnosticFlow flow) async {
    final flowName = _flowDisplayName(flow);
    _showLoading('Checking $flowName...');
    final result = await onRunFlowDiagnostics(flow);
    return _buildDiagnosticsResult(result);
  }

  void _showLoading(String message) {
    controller.showDialog(MascotDialogNode(
      id: 'diagnostics_loading',
      text: message,
      type: MascotDialogType.loading,
      suggestedAnimation: MascotAnimationKey.think,
    ));
  }

  String _flowDisplayName(DiagnosticFlow flow) {
    return switch (flow) {
      DiagnosticFlow.internet => 'internet connection',
      DiagnosticFlow.wifiCoverage => 'WiFi coverage',
      DiagnosticFlow.meshBackhaul => 'mesh backhaul',
      DiagnosticFlow.deviceIssues => 'device issues',
      DiagnosticFlow.intermittent => 'intermittent issues',
    };
  }

  MascotDialogNode _buildDiagnosticsResult(DiagnosticsResult result) {
    final type =
        result.hasIssues ? MascotDialogType.error : MascotDialogType.success;
    final animation = result.hasIssues
        ? MascotAnimationKey.sad
        : MascotAnimationKey.celebrate;

    return MascotDialogNode(
      id: 'diagnostics_result',
      text: result.message,
      type: type,
      suggestedAnimation: animation,
      options: const [
        MascotDialogOption(
          id: 'back',
          label: 'Run another test',
          icon: Icons.refresh,
        ),
        MascotDialogOption(
          id: 'main',
          label: 'Main menu',
          icon: Icons.home,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Print Report
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _handlePrint() async {
    _showLoading('Generating report...');
    await onPrintReport();
    controller.dismissDialog();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FAQ
  // ══════════════════════════════════════════════════════════════════════════

  MascotDialogNode _faqCategoriesMenu() {
    return MascotDialogNode(
      id: 'faq_categories',
      text: 'What do you need help with?',
      options: [
        ..._faqCategories.asMap().entries.map((entry) => MascotDialogOption(
              id: 'cat_${entry.key}',
              label: getFaqCategoryTitle(entry.value),
              icon: _iconForCategory(entry.value),
            )),
        const MascotDialogOption(
          id: 'back',
          label: 'Back',
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
      options: [
        ...category.items.asMap().entries.map((entry) => MascotDialogOption(
              id: 'item_${catIndex}_${entry.key}',
              label: getFaqItemTitle(entry.value),
              icon: Icons.open_in_new,
            )),
        const MascotDialogOption(
          id: 'back',
          label: 'Back',
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
