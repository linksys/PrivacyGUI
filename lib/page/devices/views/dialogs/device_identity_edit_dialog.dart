import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The most the firmware keeps for a user device name, in bytes; a longer one
/// is refused with fault 9007 (devidentd, FWDEV#207).
const _maxNameBytes = 64;

final _nameRule = LengthRule(min: 0, max: _maxNameBytes);

/// Whether [name] is longer than the firmware keeps. Counted in UTF-8 bytes,
/// so a CJK character counts three. Empty is allowed: it clears the name.
bool isDeviceNameTooLong(String name) => !_nameRule.validate(name);

/// Names a client and picks its icon (#1691).
///
/// Pops with `(name, category)` on save, or null on cancel. [DeviceCategory.unknown]
/// is the "Auto" choice: it clears the user's icon, so the detected type shows.
/// Reset pops `('', unknown)` at once, which clears both and returns the device
/// to what the firmware detected; it is off when nothing is set.
class DeviceIdentityEditDialog extends StatefulWidget {
  /// The name the user gave, or empty when there is none.
  final String initialName;

  /// The icon the user picked, or [DeviceCategory.unknown] when there is none.
  final DeviceCategory initialCategory;

  /// What an empty name falls back to, shown as the field's hint.
  final String detectedName;

  const DeviceIdentityEditDialog({
    super.key,
    required this.initialName,
    required this.initialCategory,
    required this.detectedName,
  });

  @override
  State<DeviceIdentityEditDialog> createState() =>
      _DeviceIdentityEditDialogState();
}

class _DeviceIdentityEditDialogState extends State<DeviceIdentityEditDialog> {
  // Auto first, then every category the user can pick.
  static final _choices = [
    DeviceCategory.unknown,
    ...DeviceCategory.values.where((c) => c != DeviceCategory.unknown),
  ];

  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialName);
  late DeviceCategory _category = widget.initialCategory;

  bool get _tooLong => isDeviceNameTooLong(_nameController.text.trim());

  /// Whether the user has set anything that Reset would clear.
  bool get _hasUserValues =>
      widget.initialName.isNotEmpty ||
      widget.initialCategory != DeviceCategory.unknown;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      // Thirteen icon chips outgrow a short window; scrolling the content keeps
      // Save on screen.
      scrollable: true,
      title: AppText.titleLarge(loc(context).editDevice),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelLarge(loc(context).name),
          AppGap.sm(),
          AppTextField(
            controller: _nameController,
            identifier: 'device-identity-name',
            hintText: widget.detectedName,
            errorText: _tooLong ? loc(context).deviceNameTooLong : null,
            onChanged: (_) => setState(() {}),
          ),
          AppGap.xs(),
          // Always shown, not a placeholder: a filled-in name hides the
          // placeholder, and that is when the user needs to know it.
          AppText.bodySmall(
            loc(context).deviceNameHint,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppGap.lg(),
          AppText.labelLarge(loc(context).deviceIcon),
          AppGap.sm(),
          AppChipGroup(
            chips: [
              for (final c in _choices)
                ChipItem(
                  label: c == DeviceCategory.unknown
                      ? loc(context).auto
                      : c.displayName,
                  icon: c.icon,
                  identifier: 'device-identity-icon-${c.name}',
                ),
            ],
            selectedIndices: {_choices.indexOf(_category)},
            onSelectionChanged: (selected) {
              if (selected.isEmpty) return;
              setState(() => _category = _choices[selected.first]);
            },
          ),
        ],
      ),
      actions: [
        AppButton.text(
          identifier: 'device-identity-reset',
          label: loc(context).reset,
          onTap: _hasUserValues
              ? () => context.pop((name: '', category: DeviceCategory.unknown))
              : null,
        ),
        AppButton.text(
          identifier: 'device-identity-cancel',
          label: loc(context).cancel,
          onTap: () => context.pop(),
        ),
        AppButton.primary(
          identifier: 'device-identity-save',
          label: loc(context).save,
          onTap: _tooLong
              ? null
              : () => context.pop(
                    (name: _nameController.text.trim(), category: _category),
                  ),
        ),
      ],
    );
  }
}
