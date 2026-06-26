import 'package:flutter/material.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/page/support/faq_data.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Dialog provider for the dashboard mascot.
///
/// Handles conversation flows:
/// - Main menu with FAQ categories, diagnostics, feedback options
/// - FAQ categories from [FaqCategory] with items linking to support articles
/// - Network diagnostics with full or individual flow options
class DashboardDialogProvider extends MascotDialogProvider {
  DashboardDialogProvider({
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

    return MascotDialogNode(
      id: 'main',
      text: '$greeting\nHow can I help you today?',
      options: [
        const MascotDialogOption(
          id: 'ai_assistant',
          label: 'AI Assistant',
          icon: Icons.auto_awesome,
        ),
        const MascotDialogOption(
          id: 'faq',
          label: 'FAQ',
          icon: Icons.help_outline,
        ),
        const MascotDialogOption(
          id: 'diagnostics',
          label: 'Run diagnostics',
          icon: Icons.network_check,
        ),
        const MascotDialogOption(
          id: 'print',
          label: 'Print report',
          icon: Icons.print,
        ),
        if (isThemeStudioEnabled)
          const MascotDialogOption(
            id: 'theme_studio',
            label: 'Theme Studio',
            icon: Icons.palette,
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
    'Hi there!',
    'Hello!',
    'Hey!',
    'Welcome back!',
  ];

  static const _morningGreetings = [
    'Good morning!',
    'Rise and shine!',
    'Morning! Ready to check your network?',
    'Good morning! Hope you slept well.',
  ];

  static const _afternoonGreetings = [
    'Good afternoon!',
    'Hey there!',
    'Afternoon! Everything running smoothly?',
    'Good afternoon! Need any help?',
  ];

  static const _eveningGreetings = [
    'Good evening!',
    'Evening! Winding down?',
    'Good evening! How was your day?',
    'Hey! Checking in before bed?',
  ];

  static const _nightGreetings = [
    'Hello, night owl!',
    'Burning the midnight oil?',
    'Late night check-in?',
    'Can\'t sleep? Let\'s check the network!',
  ];

  @override
  Future<MascotDialogNode?> handleSelection(
    String nodeId,
    String optionId,
  ) async {
    // Main menu
    if (nodeId == 'main') {
      switch (optionId) {
        case 'ai_assistant':
          return _handleAiAssistant();
        case 'faq':
          return _faqCategoriesMenu();
        case 'diagnostics':
          return _diagnosticsMenu();
        case 'print':
          return _handlePrint();
        case 'theme_studio':
          return _handleThemeStudio();
        default:
          return null;
      }
    }

    // Diagnostics menu -> select type
    if (nodeId == 'diagnostics_menu') {
      if (optionId == 'back') return getInitialDialog();
      if (optionId == 'full') return _runFullDiagnostics();
      // Individual flows
      final flow = _flowFromOptionId(optionId);
      if (flow != null) return _runFlowDiagnostics(flow);
    }

    // FAQ category menu -> show items
    if (nodeId == 'faq_categories') {
      if (optionId == 'back') return getInitialDialog();
      final categoryIndex = int.tryParse(optionId.replaceFirst('cat_', ''));
      if (categoryIndex != null && categoryIndex < _faqCategories.length) {
        return _faqItemsMenu(_faqCategories[categoryIndex]);
      }
    }

    // FAQ items menu -> open URL
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
          id: 'mesh',
          label: 'Mesh backhaul',
          icon: Icons.hub,
        ),
        MascotDialogOption(
          id: 'devices',
          label: 'Device issues',
          icon: Icons.devices,
        ),
        MascotDialogOption(
          id: 'intermittent',
          label: 'Intermittent issues',
          icon: Icons.sync_problem,
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
      'mesh' => DiagnosticFlow.meshBackhaul,
      'devices' => DiagnosticFlow.deviceIssues,
      'intermittent' => DiagnosticFlow.intermittent,
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

  // ══════════════════════════════════════════════════════════════════════════
  // Print Report
  // ══════════════════════════════════════════════════════════════════════════

  Future<MascotDialogNode?> _handlePrint() async {
    _showLoading('Generating report...');
    await onPrintReport();
    return null; // Close dialog after print
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Theme Studio
  // ══════════════════════════════════════════════════════════════════════════

  MascotDialogNode? _handleThemeStudio() {
    onOpenThemeStudio();
    return null; // Close dialog after opening theme studio
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AI Assistant
  // ══════════════════════════════════════════════════════════════════════════

  MascotDialogNode? _handleAiAssistant() {
    onOpenAiAssistant();
    return null; // Close dialog, navigation handled by callback
  }
}

/// Result of network diagnostics.
class DiagnosticsResult {
  const DiagnosticsResult({
    required this.message,
    required this.hasIssues,
  });

  final String message;
  final bool hasIssues;
}
