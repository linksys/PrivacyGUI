import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
import 'package:privacy_gui/usp_page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/usp_page/wifi_settings/views/tabs/wifi_advanced_tab.dart';
import 'package:privacy_gui/usp_page/wifi_settings/views/tabs/wifi_list_tab.dart';
import 'package:privacy_gui/usp_page/wifi_settings/views/tabs/wifi_mac_filtering_tab.dart';
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

  static const _tabs = ['WiFi', 'Advanced', 'MAC Filtering'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(uspWifiSettingsProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Navigation bar (full width, no margin) ────────────────────
          const UspTopBar(),
          // ── Everything below uses the standard layout margin ──────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.layoutMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Page header: back arrow + title ──────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
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
                    child: asyncState.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xxxl),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon.font(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              AppGap.md(),
                              AppText.bodyMedium(
                                'Failed to load WiFi settings.\nPull to refresh.',
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (_) => TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: const [
                          UspWifiListTab(),
                          UspWifiAdvancedTab(),
                          UspWifiMacFilteringTab(),
                        ],
                      ),
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
