import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_feature_state.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_status.dart';
import 'package:privacy_gui/page/port_forwarding/providers/usp_port_forwarding_page_notifier.dart';
import 'package:privacy_gui/page/port_forwarding/views/components/usp_single_port_tab.dart';
import 'package:privacy_gui/page/port_forwarding/views/components/usp_port_range_tab.dart';
import 'package:privacy_gui/page/port_forwarding/views/components/usp_port_triggering_tab.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Port Forwarding detail page — three-tab layout:
///   Tab 1: Single Port Forwarding (filter isSinglePort)
///   Tab 2: Port Range Forwarding (filter isPortRange)
///   Tab 3: Port Triggering
///
/// Reads from [uspPortForwardingPageProvider] (combined page notifier).
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
    final pageState = ref.watch(uspPortForwardingPageProvider);
    final status = pageState.status;
    final settings = pageState.settings.current;

    final singlePortRules =
        settings.forwardingRules.where((r) => r.isSinglePort).toList();
    final portRangeRules =
        settings.forwardingRules.where((r) => r.isPortRange).toList();
    final triggeringRules = settings.triggeringRules;

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
        onRefresh: () => ref
            .read(uspPortForwardingPageProvider.notifier)
            .fetch(forceRemote: true),
        bottomBar: _buildBottomBar(context, ref, pageState),
        tabs: [
          Tab(text: 'Single Port (${singlePortRules.length})'),
          Tab(text: 'Port Range (${portRangeRules.length})'),
          Tab(text: 'Triggering (${triggeringRules.length})'),
        ],
        tabContentViews: [
          _buildTabContent(
              status,
              UspSinglePortTab(
                  rules: singlePortRules, isSaving: status.isSaving)),
          _buildTabContent(
              status,
              UspPortRangeTab(
                  rules: portRangeRules, isSaving: status.isSaving)),
          _buildTabContent(
              status,
              UspPortTriggeringTab(
                  rules: triggeringRules, isSaving: status.isSaving)),
        ],
        tabController: _tabController,
        unboundedFallbackHeight: constraints.maxHeight,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Bottom Bar
  // ---------------------------------------------------------------------------

  UiKitBottomBarConfig? _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    PortForwardingPageFeatureState pageState,
  ) {
    if (!pageState.isDirty) return null;
    return UiKitBottomBarConfig(
      positiveLabel: 'Save',
      isPositiveEnabled: !pageState.status.isSaving,
      onPositiveTap: () => _onSave(context, ref),
      onNegativeTap: () =>
          ref.read(uspPortForwardingPageProvider.notifier).revert(),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab Content
  // ---------------------------------------------------------------------------

  Widget _buildTabContent(PortForwardingPageStatus status, Widget tabContent) {
    if (status.isLoading) {
      return const Center(child: AppLoader());
    }
    if (status.errorMessage != null) {
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
              onTap: () => ref
                  .read(uspPortForwardingPageProvider.notifier)
                  .fetch(forceRemote: true),
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

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(uspPortForwardingPageProvider.notifier).save();
      if (context.mounted) {
        showSuccessSnackBar(context, 'Port forwarding settings saved');
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, 'Failed to save: $e');
      }
    }
  }
}
