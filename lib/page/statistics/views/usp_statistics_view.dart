import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/statistics/views/sections/_sections.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Statistics / Monitoring page — consolidates all dashboard chart views
/// into 3 scrollable category tabs: Network, Devices, System.
class UspStatisticsView extends ConsumerStatefulWidget {
  final int initialTab;

  const UspStatisticsView({super.key, this.initialTab = 0});

  @override
  ConsumerState<UspStatisticsView> createState() => _UspStatisticsViewState();
}

class _UspStatisticsViewState extends ConsumerState<UspStatisticsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Follow WiFi page pattern: .withSliver + built-in tabs/tabContentViews.
    // AppPageView uses SliverFillRemaining for tab content (bounded height),
    // and SliverAppBar scrolls away with the content.
    return LayoutBuilder(builder: (context, constraints) {
      return UiKitPageView.withSliver(
        identifier: 'statistics-page',
        title: loc(context).statistics,
        topbar: const PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: UspTopBar(),
        ),
        useMainPadding: false,
        showAppBarBorder: false,
        showTabBorder: false,
        backFallback: RouteNamed.uspMenu,
        tabs: [
          Tab(
            child: Semantics(
              identifier: 'statistics-tab-network',
              child: Text(loc(context).network),
            ),
          ),
          Tab(
            child: Semantics(
              identifier: 'statistics-tab-devices',
              child: Text(loc(context).devices),
            ),
          ),
          Tab(
            child: Semantics(
              identifier: 'statistics-tab-system',
              child: Text(loc(context).system),
            ),
          ),
        ],
        tabContentViews: const [
          _NetworkTab(),
          _DevicesTab(),
          _SystemTab(),
        ],
        tabController: _tabController,
        unboundedFallbackHeight: constraints.maxHeight,
      );
    });
  }
}

// =============================================================================
// Network Tab — 9 chart sections
// =============================================================================

class _NetworkTab extends StatelessWidget {
  const _NetworkTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.layoutMargin),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const StatsTrafficMonitorSection(),
              AppGap.lg(),
              const StatsTrafficComparisonSection(),
              AppGap.lg(),
              const StatsTrafficDistributionSection(),
              AppGap.lg(),
              const StatsTrafficTrendsSection(),
              AppGap.lg(),
              const StatsHealthScoreSection(),
              AppGap.lg(),
              const StatsErrorRatesSection(),
              AppGap.lg(),
              const StatsPacketLossSection(),
              AppGap.lg(),
              const StatsFirewallRulesSection(),
              AppGap.lg(),
              const StatsPortMappingSection(),
              AppGap.lg(),
            ]),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Devices Tab — 7 chart sections
// =============================================================================

class _DevicesTab extends StatelessWidget {
  const _DevicesTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const StatsDeviceDistributionSection(),
              AppGap.lg(),
              const StatsConnectionTrendsSection(),
              AppGap.lg(),
              const StatsActivityHeatmapSection(),
              AppGap.lg(),
              const StatsSignalQualitySection(),
              AppGap.lg(),
              const StatsWifiSignalSection(),
              AppGap.lg(),
              const StatsWifiSpeedSection(),
              AppGap.lg(),
              const StatsWifiChannelsSection(),
              AppGap.lg(),
            ]),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// System Tab — 4 chart sections
// =============================================================================

class _SystemTab extends StatelessWidget {
  const _SystemTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const StatsSystemGaugesSection(),
              AppGap.lg(),
              const StatsResourceTrendsSection(),
              AppGap.lg(),
              const StatsCpuDistributionSection(),
              AppGap.lg(),
              const StatsCorrelationSection(),
              AppGap.lg(),
            ]),
          ),
        ),
      ],
    );
  }
}
