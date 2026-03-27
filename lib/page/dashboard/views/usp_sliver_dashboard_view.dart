import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/views/components/effects/jiggle_shake.dart';
import 'package:privacy_gui/page/dashboard/factories/usp_widget_factory.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/models/usp_layout_preferences.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_loader.dart';
import 'package:privacy_gui/page/dashboard/widgets/package_widget_renderer.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliver_dashboard/sliver_dashboard.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Dashboard view using SliverDashboard grid layout.
///
/// Supports drag-drop/resize in edit mode.
class UspSliverDashboardView extends ConsumerStatefulWidget {
  const UspSliverDashboardView({super.key});

  @override
  ConsumerState<UspSliverDashboardView> createState() =>
      _UspSliverDashboardViewState();
}

class _UspSliverDashboardViewState
    extends ConsumerState<UspSliverDashboardView> {
  bool _isEditMode = false;
  List<dynamic>? _initialLayoutSnapshot;
  UspLayoutPreferences? _initialPrefsSnapshot;
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
    // Ensure preferences have been loaded from SharedPreferences before
    // capturing the snapshot. Without this, the snapshot may capture the
    // default state (preset = null) if _loadFromPrefs hasn't completed yet.
    await ref.read(uspLayoutPreferencesProvider.notifier).initialized;

    final controller = ref.read(uspSliverDashboardControllerProvider);
    _initialLayoutSnapshot = controller.exportLayout();
    _initialPrefsSnapshot = ref.read(uspLayoutPreferencesProvider);

    if (!mounted) return;
    setState(() {
      _isEditMode = true;
    });
    controller.setEditMode(true);
  }

  void _exitEditMode({bool save = true}) async {
    final controller = ref.read(uspSliverDashboardControllerProvider);

    if (!save) {
      if (_initialLayoutSnapshot != null) {
        controller.importLayout(_initialLayoutSnapshot!);
        await ref
            .read(uspSliverDashboardControllerProvider.notifier)
            .saveLayout();
      }
      if (_initialPrefsSnapshot != null) {
        await ref
            .read(uspLayoutPreferencesProvider.notifier)
            .restoreSnapshot(_initialPrefsSnapshot!);
      }
    }

    setState(() {
      _isEditMode = false;
      _initialLayoutSnapshot = null;
      _initialPrefsSnapshot = null;
    });
    controller.setEditMode(false);
  }

  @override
  Widget build(BuildContext context) {
    // Eager-init polling providers so they start fetching immediately,
    // regardless of whether their dashboard cards are visible in the viewport.
    ref.watch(uspTrafficAnalysisProvider);
    ref.watch(uspDeviceAnalyticsProvider);
    ref.watch(uspSystemMonitorProvider);

    // Watch package widget loader so the view rebuilds when templates
    // finish loading — without this, pkg_ cards show "Unknown widget"
    // after page refresh because itemBuilder uses ref.read.
    ref.watch(packageWidgetLoaderProvider);

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.headlineSmall('USP Dashboard'),
        Row(
          children: [
            if (_isEditMode) ...[
              AppIconButton(
                icon: AppIcon.font(Icons.auto_fix_high),
                onTap: () {
                  final controller =
                      ref.read(uspSliverDashboardControllerProvider);
                  controller.optimizeLayout();
                  ref
                      .read(uspSliverDashboardControllerProvider.notifier)
                      .saveLayout();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Layout optimized'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              AppGap.sm(),
              AppIconButton(
                icon: AppIcon.font(Icons.tune),
                onTap: () => _openLayoutSettings(context),
              ),
              AppGap.sm(),
              AppIconButton(
                icon: AppIcon.font(Icons.close),
                onTap: () => _exitEditMode(save: false),
              ),
              AppGap.sm(),
              AppIconButton(
                icon: AppIcon.font(Icons.check),
                onTap: () => _exitEditMode(save: true),
              ),
            ] else ...[
              AppIconButton(
                icon: AppIcon.font(Icons.print),
                onTap: () async {
                  final orchState =
                      ref.read(dashboardOrchestratorProvider).valueOrNull;
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
              ),
              AppGap.sm(),
              AppIconButton(
                icon: AppIcon.font(Icons.refresh),
                onTap: () => ref
                    .read(dashboardOrchestratorProvider.notifier)
                    .refreshAll(),
              ),
              AppGap.sm(),
              AppIconButton(
                icon: AppIcon.font(Icons.edit),
                onTap: _enterEditMode,
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SliverDashboard Layout (Edit Mode) — fixed grid cells, drag-drop
  // ---------------------------------------------------------------------------

  /// Fixed slot height in logical pixels.
  static const _slotHeight = 120.0;

  Widget _buildSliverDashboard(BuildContext context) {
    final controller = ref.watch(uspSliverDashboardControllerProvider);
    final factory = ref.watch(uspWidgetFactoryProvider);
    final uiKitColumns = context.currentMaxColumns;
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
      final ratio = slotWidth / _slotHeight;

      return DashboardOverlay(
        controller: controller,
        scrollController: scrollController,
        itemBuilder: (context, item) {
          return _buildItemWidget(context, item, _isEditMode, factory);
        },
        slotAspectRatio: ratio,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        padding: EdgeInsets.symmetric(horizontal: pageMargin),
        gridStyle: _isEditMode ? editModeGridStyle : null,
        onItemResizeEnd: (item) {
          _handleResizeEnd(context, item);
        },
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: pageMargin),
              sliver: SliverDashboard(
                itemBuilder: (context, item) {
                  return _buildItemWidget(context, item, _isEditMode, factory);
                },
                slotAspectRatio: ratio,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                breakpoints: {0: uiKitColumns},
                gridStyle: _isEditMode ? editModeGridStyle : null,
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.md),
            ),
          ],
        ),
      );
    });
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

    bool violated = false;
    int newW = item.w;
    int newH = item.h;

    if (item.w < constraints.minColumns) {
      newW = constraints.minColumns;
      violated = true;
    }
    if (item.w > constraints.maxColumns) {
      newW = constraints.maxColumns;
      violated = true;
    }
    if (item.h < constraints.minHeightRows) {
      newH = constraints.minHeightRows;
      violated = true;
    }
    if (item.h > constraints.maxHeightRows) {
      newH = constraints.maxHeightRows;
      violated = true;
    }

    if (violated && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Widget "${item.id}" resized to fit constraints'),
          duration: const Duration(seconds: 2),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    if (violated) {
      ref
          .read(uspSliverDashboardControllerProvider.notifier)
          .updateItemSize(item.id, newW, newH);
    }
    ref.read(uspSliverDashboardControllerProvider.notifier).saveLayout();
  }

  Future<void> _openLayoutSettings(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AppDialog(
        title: AppText.titleMedium('Dashboard Settings'),
        content: const UspLayoutSettingsPanel(),
        actions: [
          AppButton(
            label: 'Close',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    if ((result == 'reset' ||
            result == 'toggle_off' ||
            result == 'preset_changed') &&
        mounted) {
      setState(() {
        _isEditMode = false;
        _initialLayoutSnapshot = null;
        _initialPrefsSnapshot = null;
      });
    }
  }

  Widget _buildItemWidget(
    BuildContext context,
    LayoutItem item,
    bool isEditMode,
    UspWidgetFactory factory,
  ) {
    final widget = factory.buildWidget(item.id);

    if (widget == null) {
      // Try package widget
      final templates = ref.read(packageWidgetLoaderProvider).valueOrNull;
      final template = templates?[item.id];
      if (template != null) {
        return SizedBox.expand(
          child: ClipRect(
            child: PackageWidgetRenderer(template: template),
          ),
        );
      }

      return AppCard(
        child: Center(
          child: AppText.bodyMedium('Unknown widget: ${item.id}'),
        ),
      );
    }

    // SizedBox.expand ensures cards fill their grid cell.
    // ClipRect prevents content from visually overflowing the cell boundary.
    final displayedWidget = SizedBox.expand(child: ClipRect(child: widget));

    if (isEditMode) {
      final spec = UspWidgetSpecs.getById(item.id);
      final canHide = spec?.canHide ?? true;

      return JiggleShake(
        active: true,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              ignoring: true,
              child: displayedWidget,
            ),
            if (canHide)
              Positioned(
                left: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () async {
                    await ref
                        .read(uspSliverDashboardControllerProvider.notifier)
                        .removeWidget(item.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed ${item.id}'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return displayedWidget;
  }
}
