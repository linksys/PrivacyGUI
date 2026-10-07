import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/helpers/recovery_dialog_helper.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_notifier.dart';
import 'package:privacy_gui/page/mac_filter/views/mac_filter_tab.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/tabs/wifi_advanced_tab.dart';
import 'package:privacy_gui/page/wifi_settings/views/tabs/wifi_list_tab.dart';

class UspWifiSettingsView extends ConsumerStatefulWidget {
  /// How many tabs this page has. Shared with the `clamp` below so the two
  /// cannot drift: adding a tab without widening the clamp would pin `?tab=3`
  /// to tab 2 silently, and `initialTab` is an `int` behind that clamp, so
  /// every wrong value is a legal one.
  ///
  /// The most this page can have. MAC Filtering (#1636) is shown only on firmware
  /// that serves the filter (#1635), so the tabs actually built are
  /// [tabCount] or one fewer; `?tab=2` on a device without it clamps to the last
  /// tab it does have.
  static const tabCount = 3;

  /// The MAC Filtering tab's index, for `?tab=` deep links.
  static const macFilterTab = 2;

  /// Which tab this page opens on: 0 = WiFi list, 1 = Advanced,
  /// 2 = MAC Filtering.
  ///
  /// Supplied by the route from `?tab=N` and clamped in [initState], so an
  /// out-of-range deep link opens the WiFi tab rather than throwing.
  ///
  /// Read **once, at mount**. A second navigation to this route with a different
  /// `?tab=` reuses this `State`, so `initState` does not run again and the tab
  /// does not move — the URL says one tab and the page shows another. Every
  /// caller today arrives from outside the page, so it has not bitten; a card
  /// deep-linking to a tab of the page the user is already on would need a
  /// `didUpdateWidget`. `usp_statistics_view` has the same shape.
  final int initialTab;

  const UspWifiSettingsView({super.key, this.initialTab = 0});

  @override
  ConsumerState<UspWifiSettingsView> createState() =>
      _UspWifiSettingsViewState();
}

class _UspWifiSettingsViewState extends ConsumerState<UspWifiSettingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _previousTabIndex;

  /// Whether the MAC Filtering tab is built. Read once at mount: capabilities are
  /// resolved at login and fixed for the session, so the tab set cannot change
  /// under a mounted page.
  late final bool _hasMacFilter;

  int get _tabs => _hasMacFilter
      ? UspWifiSettingsView.tabCount
      : UspWifiSettingsView.tabCount - 1;

  // Tab labels are now localized in the build method

  @override
  void initState() {
    super.initState();
    _hasMacFilter = ref
        .read(deviceCapabilitiesProvider)
        .has(DeviceCapability.wifiMacFilter);
    _tabController = TabController(
      length: _tabs,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, _tabs - 1),
    );
    // Read the index back off the controller rather than from `initialTab`:
    // the dirty guard below compares against the tab being *left*, so seeding
    // this with 0 while the controller opened on 1 would check the WiFi tab's
    // dirty state on the way out of Advanced.
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
      UspWifiSettingsView.macFilterTab =>
        ref.read(uspMacFilterProvider.notifier).isDirty(),
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
        case UspWifiSettingsView.macFilterTab:
          ref.read(uspMacFilterProvider.notifier).revert();
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
    if (_hasMacFilter) ref.watch(uspMacFilterProvider);

    return UiKitPageView.withSliver(
      title: loc(context).menuWifiSettings,
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
      tabs: [
        Tab(text: loc(context).wifi),
        Tab(text: loc(context).advanced),
        if (_hasMacFilter) Tab(text: loc(context).macFilter),
      ],
      tabContentViews: [
        const UspWifiListTab(),
        const UspWifiAdvancedTab(),
        if (_hasMacFilter) const MacFilterTab(),
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
          positiveLabel: loc(context).save,
          isPositiveEnabled: state.canSave && !state.status.isSaving,
          onPositiveTap: () => _onSave(context, ref),
          onNegativeTap: () =>
              ref.read(uspWifiSettingsProvider.notifier).revert(),
        );
      case 1:
        final state = ref.read(uspWifiAdvancedProvider);
        if (!state.isDirty) return null;
        return UiKitBottomBarConfig(
          positiveLabel: loc(context).save,
          isPositiveEnabled: !state.status.isSaving,
          onPositiveTap: () => _onSave(context, ref),
          onNegativeTap: () =>
              ref.read(uspWifiAdvancedProvider.notifier).revert(),
        );
      case UspWifiSettingsView.macFilterTab:
        return macFilterBottomBar(context, ref);
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
      UspWifiSettingsView.macFilterTab => ref
          .read(uspMacFilterProvider.notifier)
          .fetch(forceRemote: true)
          .then((_) {}),
      _ => Future.value(),
    };
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  /// One recovery for the whole save, entered when the save starts.
  ///
  /// Every WiFi write reloads the radios, so the save enters recovery before
  /// it sends anything: the app is then already waiting when the reload drops
  /// the event stream, and the shell — which only enters its natural recovery
  /// from `authenticated` — puts up nothing of its own. Before this the save
  /// showed "Processing", then the shell's "Connection lost" mid-save, then a
  /// second recovery of its own once the save came back (bench 2026-10-07).
  ///
  /// The probe is held off while the write is in flight. FW 2.0.2 keeps
  /// answering for the first ~38 s of the reload, so a probe then would end the
  /// recovery before anything had restarted; the save starts it once its write
  /// has settled, whatever the outcome, and the recovery ends through the probe
  /// as it does for every trigger. Then the page reports the save.
  ///
  /// Remote Assistance enters no recovery for a WiFi change (#1323 — the
  /// agent's path never breaks), so there the spinner covers the save.
  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    final activeTab = _tabController.index;
    // MAC Filtering saves through its own flow (`macFilterBottomBar`), which
    // confirms overriding Instant Privacy and has no Wi-Fi reconnect step.
    if (activeTab != 0 && activeTab != 1) return;

    final connection = ref.read(appConnectionStateProvider.notifier);
    final recovering = connection.enterWaiting(
      context: const RecoveryContext(
        trigger: RecoveryTrigger.operationalWifiChange,
        // Held off until the write settles — see `startProbingNow` below. Long
        // enough to outlast any save (`wifiSaveHardLimitProvider`).
        cooldown: Duration(minutes: 3),
      ),
    );
    if (recovering) {
      // Not awaited: it closes itself when the recovery ends.
      unawaited(showRecoveryDialog(
        context,
        ref,
        trigger: RecoveryTrigger.operationalWifiChange,
        skipEnterWaiting: true,
      ));
    }

    Object? failure;
    try {
      final Future<void> task = activeTab == 0
          ? ref.read(uspWifiSettingsProvider.notifier).save()
          : ref.read(uspWifiAdvancedProvider.notifier).save();
      logger.d('[WiFi][Save] Starting save (recovery: $recovering)...');
      await (recovering ? task : doSomethingWithSpinner(context, task));
      logger.d('[WiFi][Save] Save settled');
    } catch (e) {
      logger.d('[WiFi][Save] Error: $e');
      failure = e;
    }

    final wifi = ref.read(uspWifiSettingsProvider.notifier);
    final routerAway =
        failure == null && activeTab == 0 && wifi.awaitsRouterRecovery;
    if (recovering) {
      connection.startProbingNow();
    } else if (routerAway) {
      // Remote Assistance: the router still has to rejoin the cloud before it
      // can be read. The natural recovery is the wait both modes run.
      connection.enterWaiting(context: RecoveryContext.natural);
    }
    if (recovering || routerAway) {
      if (!await awaitRecovery(ref)) return; // signed out: nothing to report
    }

    if (failure == null && routerAway) {
      try {
        await wifi.confirmAfterRecovery();
      } catch (e) {
        failure = e;
      }
    }
    if (!context.mounted) return;
    if (failure != null) {
      showFailedSnackBar(context, localizeServiceError(context, failure));
    } else {
      showSuccessSnackBar(context, loc(context).wifiSettingsSaved);
    }
  }
}
