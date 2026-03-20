import 'package:flutter/material.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shows a dialog for selecting a dashboard preset.
///
/// Returns the chosen [UspDashboardPreset], or null if cancelled.
Future<UspDashboardPreset?> showPresetSelectionDialog(
  BuildContext context, {
  UspDashboardPreset? currentPreset,
}) {
  return showAppDialog<UspDashboardPreset>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _PresetSelectionDialog(
      currentPreset: currentPreset,
    ),
  );
}

class _PresetSelectionDialog extends StatefulWidget {
  const _PresetSelectionDialog({this.currentPreset});

  final UspDashboardPreset? currentPreset;

  @override
  State<_PresetSelectionDialog> createState() => _PresetSelectionDialogState();
}

class _PresetSelectionDialogState extends State<_PresetSelectionDialog> {
  late UspDashboardPreset? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentPreset;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialog(
      titleText: 'Choose Dashboard Style',
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodySmall(
            'Select a layout that suits your needs. '
            'You can customise it further with drag-and-drop editing.',
          ),
          const SizedBox(height: 16),
          ...UspDashboardPreset.values.map((preset) {
            final isSelected = _selected == preset;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PresetCard(
                preset: preset,
                isSelected: isSelected,
                onTap: () => setState(() => _selected = preset),
                colorScheme: colorScheme,
              ),
            );
          }),
        ],
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          onTap: () => Navigator.pop(context),
        ),
        AppButton.primary(
          label: 'Apply',
          onTap: _selected != null
              ? () => Navigator.pop(context, _selected)
              : null,
        ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  final UspDashboardPreset preset;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            color:
                isSelected ? colorScheme.primary.withValues(alpha: 0.08) : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                preset.icon,
                size: 28,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: AppText.titleSmall(
                            preset.displayName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AppText.labelSmall(
                            '${preset.cardIds.length}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AppText.bodySmall(
                      preset.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
