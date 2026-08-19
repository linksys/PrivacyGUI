import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
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
        title: loc(context).portForwarding,
        topbar: const PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: UspTopBar(),
        ),
        useMainPadding: false,
        showAppBarBorder: false,
        showTabBorder: false,
        backFallback: RouteNamed.uspAdvancedSettings,
        onRefresh: () => ref
            .read(uspPortForwardingPageProvider.notifier)
            .fetch(forceRemote: true),
        bottomBar: _buildBottomBar(context, ref, pageState),
        tabs: [
          // Stable, screen-reader-silent E2E hooks (→ `flt-semantics-identifier`)
          // for the three Port Forwarding tabs. Follow-on to #1172, which added
          // identifiers to the controls *inside* the tabs but not the tab strip
          // itself; the E2E suite (PrivacyGUI-USP-E2E#44) still clicks these tabs
          // by their localized label. `Tab(text:)` exposes no identifier, so we
          // move to `Tab(child:)` and wrap the label in a Semantics node.
          //
          // The Text below intentionally mirrors what `Tab(text:)` renders
          // internally (`Text(text, softWrap: false, overflow: TextOverflow.fade)`)
          // so this is a zero-visual-change swap — the Semantics node adds only
          // an invisible test hook.
          Tab(
            child: Semantics(
              identifier: 'port-forwarding-tab-single',
              child: Text(
                loc(context).singlePortForwarding,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
          Tab(
            child: Semantics(
              identifier: 'port-forwarding-tab-range',
              child: Text(
                loc(context).portRangeForwarding,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
          Tab(
            child: Semantics(
              identifier: 'port-forwarding-tab-triggering',
              child: Text(
                loc(context).portTriggering,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ),
          ),
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
      positiveLabel: loc(context).save,
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
    if (status.error != null) {
      return ServiceErrorView(
        error: status.error,
        title: loc(context).failedToLoadSettings,
        onRetry: () => ref
            .read(uspPortForwardingPageProvider.notifier)
            .fetch(forceRemote: true),
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
      await doSomethingWithSpinner(
        context,
        ref.read(uspPortForwardingPageProvider.notifier).save(),
      );
      if (context.mounted) {
        showSuccessSnackBar(context, loc(context).portForwardingSettingsSaved);
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }
}
