import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/tabs/wifi_advanced_tab.dart';
import 'package:privacy_gui/page/wifi_settings/views/tabs/wifi_list_tab.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspWifiSettingsView extends ConsumerStatefulWidget {
  const UspWifiSettingsView({super.key});

  @override
  ConsumerState<UspWifiSettingsView> createState() =>
      _UspWifiSettingsViewState();
}

class _UspWifiSettingsViewState extends ConsumerState<UspWifiSettingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _previousTabIndex;

  static const _tabs = ['WiFi', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _previousTabIndex = _tabController.index;
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// Guards against switching tabs with unsaved changes.
  Future<void> _handleTabChange() async {
    if (!_tabController.indexIsChanging) return;

    final notifier = ref.read(uspWifiSettingsProvider.notifier);
    if (!notifier.isDirty()) {
      _previousTabIndex = _tabController.index;
      return;
    }

    final confirmed = await showUnsavedAlert(context);
    if (!mounted) return;

    if (confirmed == true) {
      // Discard changes and allow tab switch.
      notifier.revert();
    } else {
      // Cancel — snap back to previous tab.
      _tabController.index = _previousTabIndex;
      return;
    }
    _previousTabIndex = _tabController.index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Navigation bar (full width, no margin) ────────────────────
          const UspTopBar(),
          // ── Everything below uses the standard layout margin ──────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.layoutMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Page header: back arrow + title ──────────────────
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: _buildPageHeader(context),
                  ),
                  // ── Tab bar ───────────────────────────────────────────
                  TabBar(
                    controller: _tabController,
                    tabs: _tabs
                        .map((label) => Tab(child: AppText.titleSmall(label)))
                        .toList(),
                  ),
                  // ── Tab content ───────────────────────────────────────
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        UspWifiListTab(),
                        UspWifiAdvancedTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Row(
      children: [
        AppIconButton(
          icon: const AppIcon.font(Icons.arrow_back),
          onTap: () => context.canPop()
              ? context.pop()
              : context.goNamed(RouteNamed.uspMenu),
        ),
        AppGap.md(),
        Expanded(
          child: AppText.headlineSmall('WiFi Settings'),
        ),
      ],
    );
  }
}
