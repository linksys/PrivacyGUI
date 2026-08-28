import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/card_grid_geometry.dart';
import 'package:privacy_gui/page/dashboard/views/components/card_form_toolbar.dart';
import 'package:privacy_gui/page/dashboard/views/components/dashboard_header_bar.dart';
import 'package:privacy_gui/page/dashboard/views/components/effects/edit_mode_affordance.dart';
import 'package:privacy_gui/page/dashboard/views/components/package_widget_tile.dart';
import 'package:privacy_gui/page/dashboard/factories/usp_widget_factory.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_edit_mode_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_loader.dart';
import 'package:privacy_gui/page/dashboard/orchestrator/dashboard_orchestrator.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/_shared/providers/usp_device_analytics_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/_shared/providers/usp_traffic_analysis_notifier.dart';
import 'package:privacy_gui/page/_shared/services/usp_pdf_service.dart';
import 'package:privacy_gui/page/dashboard/providers/pdf_report_data_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/settings/usp_layout_settings_panel.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/preset_selection_dialog.dart';
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';

/// USP Dashboard view using SliverDashboard grid layout.
///
/// Supports drag-drop/resize in edit mode.
class UspSliverDashboardView extends ConsumerStatefulWidget {
  /// Fixed slot height of the dashboard grid, in logical pixels.
  ///
  /// On the widget rather than in the [State] because the overflow gate derives
  /// card heights from it (`dashboard_card_probe.dart`), and the copy it used to
  /// keep could drift from this one without anything noticing (#1248 review W-4).
  /// The value itself moved to [kDashboardSlotHeight] once code that must not
  /// import this view needed it too; this stays as the name everything already
  /// reads.
  static const double slotHeight = kDashboardSlotHeight;

  /// How long a card must hover the trash zone before the drop deletes it.
  ///
  /// Named for the same reason as [slotHeight]: a test that drives the deletion
  /// has to wait this out, and a copy of the number in the test would keep
  /// passing if this one were raised — it would simply stop reaching the
  /// deletion, and a drag that deletes nothing is exactly what the test is there
  /// to catch. Shorter than the package's 800ms default because the zone only
  /// slides in once the drag is already under way.
  static const Duration trashHoverDelay = Duration(milliseconds: 600);

  const UspSliverDashboardView({super.key});

  @override
  ConsumerState<UspSliverDashboardView> createState() =>
      _UspSliverDashboardViewState();
}

class _UspSliverDashboardViewState
    extends ConsumerState<UspSliverDashboardView> {
  bool _presetDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPresetDialogIfNeeded();
    });
  }

  Future<void> _showPresetDialogIfNeeded() async {
    if (_presetDialogShown) return;
    _presetDialogShown = true;

    // E2E mock build: suppress the first-run preset (onboarding) dialog
    // auto-popup so the dashboard loads deterministically. Tests that need it
    // open the dialog explicitly. (P0-2)
    if (BuildConfig.e2eMock) return;

    // Skip preset dialog in remote mode — uses fixed remote preset
    if (!GlobalConfig.remote.showPresetDialog) return;

    final sharedPrefs = await SharedPreferences.getInstance();
    if (sharedPrefs.getBool(pUspPresetDialogSeen) == true) return;

    if (!mounted) return;

    final result = await showPresetSelectionDialog(context);
    if (!mounted) return;

    // Persist the flag BEFORE calling selectPreset — even if applyPreset
    // throws, the user won't be asked again on next navigation.
    await sharedPrefs.setBool(pUspPresetDialogSeen, true);

    if (result != null) {
      await ref
          .read(uspLayoutPreferencesProvider.notifier)
          .selectPreset(result);
    } else {
      // User cancelled — apply standard preset as default and don't ask again.
      await ref
          .read(uspLayoutPreferencesProvider.notifier)
          .selectPreset(UspDashboardPreset.standard);
    }
  }

  /// Ensures polling providers have completed at least one fetch cycle.
  /// Called before PDF generation as a safety net for very early clicks.
  Future<void> _ensurePollingData() async {
    final futures = <Future<void>>[];

    // System monitor — one fetch produces a snapshot.
    if (ref.read(uspSystemMonitorProvider).history.isEmpty) {
      futures.add(ref.read(uspSystemMonitorProvider.notifier).fetchNow());
    }

    // Traffic analysis — needs 2 fetches (1st = baseline, 2nd = rates).
    final traffic = ref.read(uspTrafficAnalysisProvider);
    if (traffic.history.isEmpty) {
      final notifier = ref.read(uspTrafficAnalysisProvider.notifier);
      if (traffic.lastBaselines == null) {
        await notifier.fetchNow(); // sets baseline
      }
      futures.add(notifier.fetchNow()); // computes rates
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  void _enterEditMode() async {
    await ref.read(dashboardEditModeProvider.notifier).enterEditMode();
  }

  void _commitEditMode() async {
    await ref.read(dashboardEditModeProvider.notifier).commitEditMode();
  }

  void _cancelEditMode() async {
    await ref.read(dashboardEditModeProvider.notifier).cancelEditMode();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize and watch polling/analytics providers for reactive rebuilds.
    // Polling timers are gated by dashboardDomainReadyProvider — they won't
    // start fetching until domain providers have completed their first load.
    ref.watch(uspTrafficAnalysisProvider);
    ref.watch(uspDeviceAnalyticsProvider);
    ref.watch(uspSystemMonitorProvider);

    // Kept for the load it starts, not for the rebuild it causes: opening the
    // dashboard is what fetches the templates, and the settings panel's list of
    // cards available to add is derived from them. The rebuild used to be how
    // `pkg_` cards stopped reading "unknown widget" — that no longer works and
    // is no longer needed, because 2.3.1 caches tile content and each card now
    // resolves its own template inside [PackageWidgetTile] (#1395).
    ref.watch(packageWidgetLoaderProvider);

    final isOnline = ref.watch(wanIsUpProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed Header (title + action buttons)
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.pageMargin,
            vertical: AppSpacing.md,
          ),
          child: _buildHeader(context),
        ),

        // Offline banner (when WAN is down)
        if (!isOnline)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.pageMargin,
            ),
            child: _buildOfflineBanner(context),
          ),

        // SliverDashboard grid
        Expanded(
          child: _buildSliverDashboard(context),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    // Layout and the responsive narrow form live in [DashboardHeaderBar]; this
    // stays the wiring — what the actions do, and the two pieces of state that
    // decide which set of them applies (#1314).
    return DashboardHeaderBar(
      isEditMode: ref.watch(dashboardEditModeProvider).isEditing,
      isRemoteMode: GlobalConfig.remote.isActive,
      onOptimizeLayout: () {
        // No save: `optimizeLayout` is a controller mutation, so the grid stores
        // it through the auto-persist hook (#1393). Saving here too would walk
        // every breakpoint a second time to write what is already in the pref.
        ref.read(uspSliverDashboardControllerProvider).optimizeLayout();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc(context).layoutOptimized),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      onLayoutSettings: () => _openLayoutSettings(context),
      onCancelEdit: _cancelEditMode,
      onCommitEdit: _commitEditMode,
      onPrint: () async {
        final orchState = ref.read(dashboardOrchestratorProvider).valueOrNull;
        if (orchState == null) return;

        // Ensure polling providers have data before generating PDF.
        await _ensurePollingData();

        if (!context.mounted) return;

        final reportData = ref.read(pdfReportDataProvider);
        if (reportData == null) return;
        doSomethingWithSpinner(
          context,
          UspPdfService.generatePdf(reportData),
        );
      },
      onRefresh: () =>
          ref.read(dashboardOrchestratorProvider.notifier).refreshAll(),
      onEdit: _enterEditMode,
    );
  }

  // ---------------------------------------------------------------------------
  // Offline Banner
  // ---------------------------------------------------------------------------

  Widget _buildOfflineBanner(BuildContext context) {
    return AppCard(
      identifier: 'dashboard-offline-banner',
      child: InkWell(
        onTap: () {
          context.goNamed(RouteNamed.uspUnifiedDiagnostics);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              AppIcon.font(
                Icons.wifi_off,
                color: Theme.of(context).colorScheme.error,
              ),
              AppGap.md(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleSmall(loc(context).pnpErrorForStaticIpAndDhcp),
                    AppGap.xs(),
                    AppText.bodySmall(
                      loc(context).pnpNoInternetConnectionRestartModemDesc,
                    ),
                  ],
                ),
              ),
              AppIcon.font(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SliverDashboard Layout (Edit Mode) — fixed grid cells, drag-drop
  // ---------------------------------------------------------------------------

  Widget _buildSliverDashboard(BuildContext context) {
    final controller = ref.watch(uspSliverDashboardControllerProvider);
    final factory = ref.watch(uspWidgetFactoryProvider);
    final isEditMode = ref.watch(dashboardEditModeProvider).isEditing;
    final uiKitColumns = context.currentMaxColumns;
    // Whether the controller has caught up with the breakpoint this frame is
    // being built at (#1395).
    //
    // `breakpoints` does not take effect in the frame that observes the change:
    // `SliverDashboard` compares the width it was given against
    // `controller.slotCount` and, when they differ, schedules `setSlotCount` in a
    // post-frame callback. Until 2.0.0 it also returned an empty sliver for that
    // one frame — "skip frame optimization" — and 2.x dropped the early return
    // while keeping the callback, so the outgoing grid's geometry is now laid out
    // at the incoming grid's width instead of being withheld: at 320px every
    // half-width desktop card is drawn 6 columns wide in a 4-column viewport, and
    // the overflow gate reports the whole page overflowing at all four widths
    // below desktop.
    //
    // So the skip is done here instead. What it covers is every frame that
    // observes a breakpoint the controller has not been moved to yet — the first
    // frame of a boot into anything narrower than desktop (a fresh controller
    // starts on the desktop grid), and the frame a window resize crosses a
    // boundary in. The controller swaps do *not* need it: since #1395 they carry
    // the live breakpoint across the swap themselves (`_seedBreakpoints(live:)`),
    // which is the right place for it — the notifier knows the grid it is
    // replacing, and this build only knows the one it is rendering.
    //
    // Post-frame rather than during this build, because `setSlotCount` writes the
    // controller's layout beacon and half the grid is watching it — which is also
    // why the slot count is *watched* here and not read: the callback below changes
    // it without changing the controller instance, so nothing Riverpod publishes
    // would bring this build back to notice, and the empty sliver would be
    // permanent. The watch also fires on every save, because the persistence
    // walk visits each breakpoint in turn and returns.
    //
    // One frame with no grid also means one frame with no scroll extent, so a
    // resize that crosses a boundary while scrolled down lands back at the top.
    // 0.9.1's own skip did exactly that, so it is not new, and the alternative is
    // a frame of visibly wrong layout.
    final slotsAreCurrent = controller.slotCount.watch(context) == uiKitColumns;
    if (!slotsAreCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) controller.setSlotCount(uiKitColumns);
      });
    }

    // Per build, and it has to be. Hoisting it into the [State] — the obvious
    // fix for what looks like a leak — crashes on entering edit mode: the
    // toolbar layer below wraps the grid in a `Stack`/`NotificationListener`,
    // which changes the tree *shape* above the `Scrollable` and so remounts it.
    // The new `ScrollPosition` attaches before the old element is unmounted at
    // the end of the frame, and `DashboardOverlay` reads `scrollController.offset`
    // during layout, between the two: `ScrollController.position` throws on two
    // attached positions — the assertion in debug, `Iterable.single` in release.
    //
    // A fresh instance is close to free. `ScrollableState.didUpdateWidget`
    // re-attaches the *same* position to the new controller rather than making
    // one, so the offset and any in-flight fling survive; the previous instance
    // is left with no positions and collected. What it costs is that nothing may
    // hold one across a build — see the same note on [CardFormToolbarLayer],
    // which is why the toolbar reads the offset from scroll notifications.
    final scrollController = ScrollController();

    final editModeGridStyle = GridStyle(
      lineColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
      lineWidth: 1,
      fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
    );

    return LayoutBuilder(builder: (context, constraints) {
      // slotAspectRatio = width / height, compute from fixed height
      final pageMargin = context.pageMargin;
      final availableWidth = constraints.maxWidth - pageMargin * 2;
      final slotWidth =
          (availableWidth - (uiKitColumns - 1) * AppSpacing.lg) / uiKitColumns;
      final ratio = slotWidth / UspSliverDashboardView.slotHeight;

      final grid = DashboardOverlay(
        controller: controller,
        scrollController: scrollController,
        itemBuilder: (context, item) {
          return _buildItemWidget(context, item, factory);
        },
        slotAspectRatio: ratio,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        padding: EdgeInsets.symmetric(horizontal: pageMargin),
        gridStyle: isEditMode ? editModeGridStyle : null,
        onItemResizeEnd: (item) {
          _handleResizeEnd(context, item);
        },
        // Drag-to-trash for widget removal in edit mode.
        trashBuilder: !isEditMode
            ? null
            : (context, isHovered, isActive, activeItemId) {
                return _buildTrashZone(context, isHovered, isActive);
              },
        trashHoverDelay: UspSliverDashboardView.trashHoverDelay,
        // No onItemsDeleted: the overlay calls `controller.removeItems` before it
        // notifies, so the deletion is already on its way to the pref through the
        // auto-persist hook (#1393).
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: pageMargin),
              // Empty for the one frame the controller is a breakpoint behind —
              // see [slotsAreCurrent]. `breakpoints` stays, but not as a second
              // safety net: a single entry at 0 resolves to `uiKitColumns` at
              // every width, which pins the package's own width-to-columns map to
              // ui_kit's. That is what makes the two catch-ups agree — the
              // package's post-frame call can never ask for a slot count this
              // build did not already ask for.
              sliver: !slotsAreCurrent
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : SliverDashboard(
                      itemBuilder: (context, item) {
                        return _buildItemWidget(context, item, factory);
                      },
                      slotAspectRatio: ratio,
                      mainAxisSpacing: AppSpacing.lg,
                      crossAxisSpacing: AppSpacing.lg,
                      breakpoints: {0: uiKitColumns},
                      gridStyle: isEditMode ? editModeGridStyle : null,
                    ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.md),
            ),
          ],
        ),
      );

      // The form toolbar for the selected card (#1299). Edit mode only — that is
      // AC 4, and it costs no guard inside the toolbar because the layer is not
      // built at all outside edit mode. It wraps the grid rather than sitting
      // beside it in the page column: the toolbar is anchored to the card, so it
      // has to be a sibling above the same box the grid was laid out in.
      if (!isEditMode) return grid;

      return CardFormToolbarLayer(
        geometry: CardGridGeometry(
          slotWidth: slotWidth,
          slotHeight: UspSliverDashboardView.slotHeight,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          padding: EdgeInsets.symmetric(horizontal: pageMargin),
        ),
        child: grid,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Trash Zone (drag-to-delete)
  // ---------------------------------------------------------------------------

  Widget _buildTrashZone(
    BuildContext context,
    bool isHovered,
    bool isActive,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        // Minimums rather than fixed sizes, plus padding: the label is
        // localized, and 180px does not hold "Drag Here to Remove" at
        // `bodyMedium` in English — let alone in a locale that needs more. The
        // pill still reads as one shape at rest, and the drop target is
        // whatever it grew to. Found by #1395's edit-mode test; the overflow
        // gate cannot see this surface, because it never enters edit mode.
        //
        // Both axes, because `TextOverflow.ellipsis` only covers one of them: at
        // a large system text scale a `maxLines: 1` `bodyMedium` needs more than
        // 56px, and a fixed `height` would clip the glyphs instead.
        constraints: const BoxConstraints(minWidth: 180, minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.error
              : (isHovered
                  ? colorScheme.error.withValues(alpha: 0.8)
                  : colorScheme.errorContainer),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
          border: isHovered
              ? Border.all(color: colorScheme.onError, width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.delete_forever : Icons.delete_outline,
              color: isActive || isHovered
                  ? colorScheme.onError
                  : colorScheme.onErrorContainer,
              size: isActive ? 28 : 24,
            ),
            AppGap.sm(),
            // Flexible, not bare: the pill grows to its label, but a viewport
            // narrower than the label still has to clip rather than overflow.
            Flexible(
              child: AppText.bodyMedium(
                isActive
                    ? loc(context).releaseToRemove
                    : loc(context).dragHereToRemove,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // The same pair the icon above takes. Without it the label keeps
                // the text theme's on-surface colour over a saturated `error`
                // fill — near-black on red in the light theme, on the one string
                // that confirms a destructive action.
                color: isActive || isHovered
                    ? colorScheme.onError
                    : colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Edit Mode — resize, settings, item builder
  // ---------------------------------------------------------------------------

  void _handleResizeEnd(BuildContext context, LayoutItem item) {
    final factory = ref.read(uspWidgetFactoryProvider);
    final spec = factory.getSpec(item.id) ??
        ref
            .read(packageWidgetLoaderProvider)
            .valueOrNull?[item.id]
            ?.toWidgetSpec();
    if (spec == null) return;

    final constraints = spec.constraints[DisplayMode.normal];
    if (constraints == null) return;

    // Which grid the card is on decides what its spec's column figures mean —
    // see [UspWidgetSpecs.correctedSize].
    final notifier = ref.read(uspSliverDashboardControllerProvider.notifier);
    final corrected = UspWidgetSpecs.correctedSize(
      constraints,
      w: item.w,
      h: item.h,
      slotCount: ref.read(uspSliverDashboardControllerProvider).slotCount.value,
    );

    // A size the spec allows needs nothing done to it: the resize itself is what
    // the hook stores (#1393).
    if (corrected == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc(context).widgetResized(item.id)),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    // Saves as part of correcting the size — a second saveLayout here would walk
    // every breakpoint again for nothing.
    notifier.updateItemSize(item.id, corrected.w, corrected.h);
  }

  Future<void> _openLayoutSettings(BuildContext context) async {
    final result = await showAppDialog<String>(
      context: context,
      builder: (context) => AppDialog(
        title: AppText.titleMedium(loc(context).dashboardSettings),
        content: const UspLayoutSettingsPanel(),
        actions: [
          AppButton(
            label: loc(context).close,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    if ((result == 'reset' || result == 'preset_changed') && mounted) {
      // Commit (keep) the change — the settings panel already applied the
      // reset/preset directly to the controller and prefs, so exiting must
      // preserve it, not revert to the pre-edit snapshot.
      await ref.read(dashboardEditModeProvider.notifier).commitEditMode();
    }
  }

  /// Builds one card's content.
  ///
  /// Reads nothing that can change while the tile lives: 2.3.1 caches what this
  /// returns and invalidates the cache only on a content-signature or dimension
  /// change, so anything reactive has to be read one level down, inside the
  /// widget — see [EditModeAffordance] for the edit-mode flag and
  /// [PackageWidgetTile] for the templates (#1395).
  Widget _buildItemWidget(
    BuildContext context,
    LayoutItem item,
    UspWidgetFactory factory,
  ) {
    // The factory's cards are the built-in ones and it answers synchronously;
    // anything it does not know is either a package card or gone with its
    // package, which is [PackageWidgetTile]'s question, not this one's.
    final resolvedWidget =
        factory.buildWidget(item.id) ?? PackageWidgetTile(itemId: item.id);

    // SizedBox.expand ensures cards fill their grid cell.
    // Note: ClipRect was removed because it clips shadows/borders causing
    // visual truncation. Cards handle their own overflow via internal clipping.
    final displayedWidget = SizedBox.expand(child: resolvedWidget);

    return EditModeAffordance(child: displayedWidget);
  }
}
