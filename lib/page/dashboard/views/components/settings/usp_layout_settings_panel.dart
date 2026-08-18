import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/providers/all_widget_specs_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/card_forms_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_preferences_provider.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/preset_selection_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Settings panel for customizing USP dashboard layout.
///
/// Allows users to:
/// - Pick the form each card on the dashboard renders in (#1299).
/// - View and re-add available widgets (built-in and app widgets).
/// - Reset layout to defaults.
class UspLayoutSettingsPanel extends ConsumerWidget {
  const UspLayoutSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppCard(
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary),
                AppGap.md(),
                Expanded(
                  child: AppText.bodySmall(
                    loc(context).layoutSettingsDescription,
                  ),
                ),
              ],
            ),
          ),
          AppGap.xl(),

          _buildPresetSection(context, ref),

          _buildCardFormSection(context, ref),

          _buildAvailableWidgets(context, ref),

          // Reset Button
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.text(
              label: loc(context).resetLayout,
              onTap: () async {
                await ref
                    .read(uspLayoutPreferencesProvider.notifier)
                    .resetToDefaults();

                if (context.mounted) {
                  Navigator.pop(context, 'reset');

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc(context).layoutResetToDefaults),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSection(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(uspLayoutPreferencesProvider);
    final currentPreset = prefs.selectedPreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge(loc(context).dashboardStyle),
        AppGap.sm(),
        AppCard(
          child: Row(
            children: [
              if (currentPreset != null) ...[
                Icon(currentPreset.icon, size: 20),
                AppGap.sm(),
                Expanded(
                  child: AppText.bodyMedium(currentPreset.displayName),
                ),
              ] else
                Expanded(
                  child: AppText.bodyMedium(loc(context).noPresetSelected),
                ),
              AppButton.text(
                label: loc(context).change,
                onTap: () async {
                  final result = await showPresetSelectionDialog(
                    context,
                    currentPreset: currentPreset,
                  );
                  if (result != null && context.mounted) {
                    await ref
                        .read(uspLayoutPreferencesProvider.notifier)
                        .selectPreset(result);
                    if (context.mounted) {
                      Navigator.pop(context, 'preset_changed');
                    }
                  }
                },
              ),
            ],
          ),
        ),
        AppGap.xl(),
      ],
    );
  }

  /// Lets the user pick the form each card renders in, which in turn decides how
  /// far that card can be resized (#1299).
  ///
  /// ## Why it lives in this panel and not on the card
  ///
  /// A finding, not a preference. The spike in
  /// `test/page/dashboard/views/density_control_gesture_spike_test.dart` showed
  /// that edit mode's `AbsorbPointer` swallows anything drawn inside a card, and
  /// that hoisting a control above it arms a drag on desktop which
  /// `cancelInteraction()` does not stop — the overlay's pointer-up still commits
  /// the move. So an on-card control would either not receive the tap or would
  /// nudge the card while receiving it.
  ///
  /// This panel is reached from the tune button that only exists while editing,
  /// so "edit mode only" (AC 4) costs no extra guard here.
  ///
  /// ## Which cards appear
  ///
  /// Only cards that are on the dashboard *and* have more than one form to offer.
  /// [UspWidgetSpecs.selectableForms] returns empty for a card whose only form is
  /// normal, so on a dashboard of such cards the whole section disappears rather
  /// than showing a column of one-option dropdowns.
  Widget _buildCardFormSection(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(uspSliverDashboardControllerProvider);
    final currentIds = controller
        .exportLayout()
        .map((e) => (e as Map)['id'] as String)
        .toSet();

    // The breakpoint the pick belongs to, read from the grid rather than from
    // this dialog's context: it is the same number `setCardForm` writes under, so
    // the dropdown cannot show a pick from a grid the user is not on.
    final slots = controller.slotCount.value;
    final forms = ref.watch(cardFormsProvider);

    final entries = ref
        .watch(allWidgetSpecsProvider)
        .where((spec) => currentIds.contains(spec.id))
        .map((spec) => (
              spec: spec,
              options: UspWidgetSpecs.selectableForms(spec.id),
            ))
        .where((entry) => entry.options.isNotEmpty)
        .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge(loc(context).cardForm),
        AppGap.sm(),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AppText.bodySmall(loc(context).cardFormDescription),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: entries.map((entry) {
              // A card with no stored pick shows normal: normal is the absence of
              // a pick, not a stored value, so the two have to read the same.
              final selected =
                  forms.densityFor(slots, entry.spec.id) ?? CardDensity.normal;

              return ListTile(
                title: AppText.bodyMedium(entry.spec.displayName),
                trailing: SizedBox(
                  width: 160,
                  child: AppDropdown<CardDensity>(
                    identifier: 'card-form-${entry.spec.id}',
                    semanticLabel:
                        loc(context).cardFormForNamed(entry.spec.displayName),
                    items: entry.options,
                    value: selected,
                    itemAsString: (density) => _cardFormLabel(context, density),
                    itemIdentifier: (density) =>
                        'card-form-${entry.spec.id}-${density.name}',
                    onChanged: (density) {
                      if (density == null || density == selected) return;
                      ref
                          .read(uspSliverDashboardControllerProvider.notifier)
                          .setCardForm(entry.spec.id, density);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        AppGap.xl(),
      ],
    );
  }

  String _cardFormLabel(BuildContext context, CardDensity density) =>
      switch (density) {
        CardDensity.popup => loc(context).cardFormPopup,
        CardDensity.compact => loc(context).cardFormCompact,
        CardDensity.normal => loc(context).cardFormNormal,
      };

  Widget _buildAvailableWidgets(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(uspSliverDashboardControllerProvider);
    final currentLayout = controller.exportLayout();
    final currentIds =
        currentLayout.map((e) => (e as Map)['id'] as String).toSet();

    final allSpecs = ref.watch(allWidgetSpecsProvider);

    // Separate built-in and app widgets
    final availableSpecs = allSpecs.where((spec) {
      return !currentIds.contains(spec.id);
    }).toList();

    final builtInSpecs = availableSpecs.where((spec) {
      return UspWidgetSpecs.all.any((builtIn) => builtIn.id == spec.id);
    }).toList();

    final appWidgetSpecs = availableSpecs.where((spec) {
      return !UspWidgetSpecs.all.any((builtIn) => builtIn.id == spec.id);
    }).toList();

    if (availableSpecs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge(loc(context).availableWidgets),
        AppGap.sm(),

        // Built-in Widgets Section
        if (builtInSpecs.isNotEmpty) ...[
          _buildWidgetSection(
            context,
            ref,
            title: loc(context).builtInWidgets,
            specs: builtInSpecs,
          ),
          AppGap.md(),
        ],

        // App Widget Cards Section
        if (appWidgetSpecs.isNotEmpty) ...[
          _buildWidgetSection(
            context,
            ref,
            title: loc(context).appWidgetCards,
            specs: appWidgetSpecs,
            isAppWidgetCard: true,
          ),
        ],

        AppGap.xl(),
      ],
    );
  }

  Widget _buildWidgetSection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<WidgetSpec> specs,
    bool isAppWidgetCard = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: AppText.bodySmall(title),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: specs.map((spec) {
              if (isAppWidgetCard) {
                // Enhanced display for App Widget Cards
                return ListTile(
                  title: AppText.bodyMedium(spec.displayName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (spec.description != null) ...[
                        Tooltip(
                          message: spec.description!,
                          child: Icon(
                            Icons.info_outline,
                            size: 20,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      AppIconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onTap: () async {
                          await ref
                              .read(
                                  uspSliverDashboardControllerProvider.notifier)
                              .addWidget(spec.id, spec: spec);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc(context)
                                    .addedWidgetNamed(spec.displayName)),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              } else {
                // Standard display for Built-in Widgets
                return ListTile(
                  title: AppText.bodyMedium(spec.displayName),
                  trailing: AppIconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onTap: () async {
                      await ref
                          .read(uspSliverDashboardControllerProvider.notifier)
                          .addWidget(spec.id, spec: spec);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc(context)
                                .addedWidgetNamed(spec.displayName)),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  ),
                );
              }
            }).toList(),
          ),
        ),
      ],
    );
  }
}
