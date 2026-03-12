import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/port_forwarding/views/components/usp_single_port_tab.dart';
import 'package:privacy_gui/usp_page/port_forwarding/views/components/usp_port_range_tab.dart';
import 'package:privacy_gui/usp_page/port_forwarding/views/components/usp_port_triggering_tab.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Port Forwarding detail page — three-tab layout:
///   Tab 1: Single Port Forwarding (filter isSinglePort)
///   Tab 2: Port Range Forwarding (filter isPortRange)
///   Tab 3: Port Triggering (independent data source)
///
/// Reads from [uspDashboardProvider] (shared state). All mutations delegate
/// to [UspDashboardNotifier] to keep state in sync with the dashboard.
class UspPortForwardingDetailView extends ConsumerStatefulWidget {
  const UspPortForwardingDetailView({super.key});

  @override
  ConsumerState<UspPortForwardingDetailView> createState() =>
      _UspPortForwardingDetailViewState();
}

class _UspPortForwardingDetailViewState
    extends ConsumerState<UspPortForwardingDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(uspDashboardProvider);
    final state = asyncState.valueOrNull;

    final singlePortRules = state?.portForwardingRuleModels
            .where((r) => r.isSinglePort)
            .toList() ??
        [];
    final portRangeRules = state?.portForwardingRuleModels
            .where((r) => r.isPortRange)
            .toList() ??
        [];
    final triggeringRules = state?.portTriggeringRuleModels ?? [];

    return LayoutBuilder(builder: (context, constraints) {
      return UiKitPageView.withSliver(
        title: 'Port Forwarding',
        topbar: const PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: UspTopBar(),
        ),
        useMainPadding: false,
        showAppBarBorder: false,
        showTabBorder: false,
        onBackTap: () => context.canPop()
            ? context.pop()
            : context.goNamed(RouteNamed.uspMenu),
        onRefresh: () => ref.refresh(uspDashboardProvider.future),
        tabs: [
          Tab(text: 'Single Port (${singlePortRules.length})'),
          Tab(text: 'Port Range (${portRangeRules.length})'),
          Tab(text: 'Triggering (${triggeringRules.length})'),
        ],
        tabContentViews: [
          _buildTabContent(
              asyncState, UspSinglePortTab(rules: singlePortRules)),
          _buildTabContent(asyncState, UspPortRangeTab(rules: portRangeRules)),
          _buildTabContent(
              asyncState, UspPortTriggeringTab(rules: triggeringRules)),
        ],
        tabController: _tabController,
        unboundedFallbackHeight: constraints.maxHeight,
      );
    });
  }

  Widget _buildTabContent(AsyncValue asyncState, Widget tabContent) {
    if (asyncState.isLoading && asyncState.valueOrNull == null) {
      return const Center(child: AppLoader());
    }
    if (asyncState.hasError && asyncState.valueOrNull == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.font(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            AppGap.xl(),
            AppText.titleMedium('Unable to load data'),
            AppGap.md(),
            AppButton(
              label: 'Retry',
              onTap: () => ref.invalidate(uspDashboardProvider),
            ),
          ],
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: context.layoutMargin),
          sliver: SliverList(
            delegate: SliverChildListDelegate([tabContent, AppGap.md()]),
          ),
        ),
      ],
    );
  }
}
