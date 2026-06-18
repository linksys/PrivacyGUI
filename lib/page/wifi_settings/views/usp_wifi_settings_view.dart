import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/_shared/helpers/recovery_dialog_helper.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/tabs/wifi_advanced_tab.dart';
import 'package:privacy_gui/page/wifi_settings/views/tabs/wifi_list_tab.dart';

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

  static const _tabLabels = ['WiFi', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
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
  /// Checks the **leaving** tab's dirty state independently.
  Future<void> _handleTabChange() async {
    if (!_tabController.indexIsChanging) return;

    final leavingTab = _previousTabIndex;
    final isDirty = switch (leavingTab) {
      0 => ref.read(uspWifiSettingsProvider.notifier).isDirty(),
      1 => ref.read(uspWifiAdvancedProvider.notifier).isDirty(),
      _ => false,
    };

    if (!isDirty) {
      _previousTabIndex = _tabController.index;
      return;
    }

    final confirmed = await showUnsavedAlert(context);
    if (!mounted) return;

    if (confirmed == true) {
      // Discard changes and allow tab switch.
      switch (leavingTab) {
        case 0:
          ref.read(uspWifiSettingsProvider.notifier).revert();
        case 1:
          ref.read(uspWifiAdvancedProvider.notifier).revert();
      }
    } else {
      // Cancel — snap back to previous tab.
      _tabController.index = _previousTabIndex;
      return;
    }
    _previousTabIndex = _tabController.index;
  }

  @override
  Widget build(BuildContext context) {
    // Watch both providers so bottom bar rebuilds on dirty state changes.
    ref.watch(uspWifiSettingsProvider);
    ref.watch(uspWifiAdvancedProvider);

    return UiKitPageView.withSliver(
      title: 'WiFi Settings',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      showAppBarBorder: false,
      showTabBorder: false,
      backFallback: RouteNamed.uspMenu,
      onRefresh: () => _onRefresh(),
      bottomBar: _buildBottomBar(context, ref),
      tabController: _tabController,
      tabs: const [
        Tab(text: 'WiFi'),
        Tab(text: 'Advanced'),
      ],
      tabContentViews: const [
        UspWifiListTab(),
        UspWifiAdvancedTab(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Bar — shows Save + Cancel for the active tab when dirty
  // ---------------------------------------------------------------------------

  UiKitBottomBarConfig? _buildBottomBar(BuildContext context, WidgetRef ref) {
    final activeTab = _tabController.index;

    switch (activeTab) {
      case 0:
        final state = ref.read(uspWifiSettingsProvider);
        if (!state.isDirty) return null;
        return UiKitBottomBarConfig(
          positiveLabel: 'Save',
          isPositiveEnabled: state.canSave && !state.status.isSaving,
          onPositiveTap: () => _onSave(context, ref),
          onNegativeTap: () =>
              ref.read(uspWifiSettingsProvider.notifier).revert(),
        );
      case 1:
        final state = ref.read(uspWifiAdvancedProvider);
        if (!state.isDirty) return null;
        return UiKitBottomBarConfig(
          positiveLabel: 'Save',
          isPositiveEnabled: !state.status.isSaving,
          onPositiveTap: () => _onSave(context, ref),
          onNegativeTap: () =>
              ref.read(uspWifiAdvancedProvider.notifier).revert(),
        );
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh
  // ---------------------------------------------------------------------------

  Future<void> _onRefresh() {
    final activeTab = _tabController.index;
    return switch (activeTab) {
      0 => ref
          .read(uspWifiSettingsProvider.notifier)
          .fetch(forceRemote: true)
          .then((_) {}),
      1 => ref
          .read(uspWifiAdvancedProvider.notifier)
          .fetch(forceRemote: true)
          .then((_) {}),
      _ => Future.value(),
    };
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    final activeTab = _tabController.index;

    try {
      final Future<void> task = switch (activeTab) {
        0 => ref.read(uspWifiSettingsProvider.notifier).save(),
        1 => ref.read(uspWifiAdvancedProvider.notifier).save(),
        _ => Future.value(),
      };
      logger.d('[WiFi][Save] Starting save...');
      await doSomethingWithSpinner(context, task);
      logger.d('[WiFi][Save] Save completed, save spinner dismissed');

      if (!context.mounted) return;

      await showRecoveryDialog(
        context,
        ref,
        trigger: RecoveryTrigger.operationalWifiChange,
        successMessage: 'WiFi settings saved',
      );
    } catch (e) {
      logger.d('[WiFi][Save] Error: $e');
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }
}
