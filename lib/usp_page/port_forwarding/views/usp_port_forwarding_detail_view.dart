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
class UspPortForwardingDetailView extends ConsumerWidget {
  const UspPortForwardingDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backState: UiKitBackState.none,
      onRefresh: () => ref.refresh(uspDashboardProvider.future),
      padding:
          const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(childContext),
            AppGap.xl(),
            const _PortForwardingTabs(),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        AppIconButton(
          icon: AppIcon.font(Icons.arrow_back),
          onTap: () => context.canPop()
              ? context.pop()
              : context.goNamed(RouteNamed.uspMenu),
        ),
        AppGap.md(),
        AppText.headlineSmall('Port Forwarding'),
      ],
    );
  }
}

/// TabBar widget that watches [uspDashboardProvider] internally.
///
/// By owning its own [TabController] as a [ConsumerStatefulWidget], the
/// selected tab index is preserved across provider state changes — the
/// widget tree for the TabBar never gets torn down by parent rebuilds.
class _PortForwardingTabs extends ConsumerStatefulWidget {
  const _PortForwardingTabs();

  @override
  ConsumerState<_PortForwardingTabs> createState() =>
      _PortForwardingTabsState();
}

class _PortForwardingTabsState extends ConsumerState<_PortForwardingTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

    final singlePortRules =
        state?.portForwardingRuleModels.where((r) => r.isSinglePort).toList() ??
            [];
    final portRangeRules =
        state?.portForwardingRuleModels.where((r) => r.isPortRange).toList() ??
            [];
    final triggeringRules = state?.portTriggeringRuleModels ?? [];

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Single Port (${singlePortRules.length})'),
            Tab(text: 'Port Range (${portRangeRules.length})'),
            Tab(text: 'Triggering (${triggeringRules.length})'),
          ],
        ),
        AppGap.xl(),
        if (asyncState.isLoading && state == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxxl),
              child: AppLoader(),
            ),
          )
        else if (asyncState.hasError && state == null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon.font(Icons.error_outline,
                    size: 48, color: Theme.of(context).colorScheme.error),
                AppGap.xl(),
                AppText.titleMedium('Unable to load data'),
                AppGap.md(),
                AppText.bodyMedium(asyncState.error.toString()),
                AppGap.xxl(),
                AppButton(
                  label: 'Retry',
                  onTap: () => ref.invalidate(uspDashboardProvider),
                ),
              ],
            ),
          )
        else
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              switch (_tabController.index) {
                case 0:
                  return UspSinglePortTab(rules: singlePortRules);
                case 1:
                  return UspPortRangeTab(rules: portRangeRules);
                case 2:
                  return UspPortTriggeringTab(rules: triggeringRules);
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
      ],
    );
  }
}
