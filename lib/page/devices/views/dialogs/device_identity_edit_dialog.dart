import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/device_category_ui.dart';
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
/// Save calls [onSave] and stays open, with a busy Save button, until it
/// finishes: a save is a Set and two reads, long enough to look like nothing
/// happened if the dialog closed at once. It then pops `true`. A failed save
/// keeps the dialog open and says why. Cancel pops null.
///
/// The saved category is null when the user did not touch the icon, so a type
/// another client wrote is left alone. [DeviceCategory.unknown] is the "Auto"
/// choice: it clears the user's icon, so the detected type shows. Reset saves
/// `('', unknown)` the same way, which clears both and returns the device to
/// what the firmware detected; it is off when nothing is set. The dialog cannot
/// be dismissed while saving.
class DeviceIdentityEditDialog extends StatefulWidget {
  /// The name the user gave, or empty when there is none.
  final String initialName;

  /// The icon the user picked, or [DeviceCategory.unknown] when there is none
  /// or it is not one of the app's codes.
  final DeviceCategory initialCategory;

  /// Whether a user type is stored at all, including one [initialCategory]
  /// cannot show (a devregex string another client wrote). Turns Reset on.
  final bool hasUserType;

  /// What an empty name falls back to, shown as the field's hint.
  final String detectedName;

  /// Whether the icon choice is offered. Off for the router, which is named
  /// but not typed; the saved category is then always null.
  final bool showIcon;

  /// Writes the trimmed name, and the category when the user changed it (null
  /// otherwise). Throws to report a failure.
  final Future<void> Function(String name, DeviceCategory? category) onSave;

  const DeviceIdentityEditDialog({
    super.key,
    required this.initialName,
    required this.initialCategory,
    required this.detectedName,
    required this.onSave,
    this.hasUserType = false,
    this.showIcon = true,
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
  bool _saving = false;
  String? _saveError;

  bool get _tooLong => isDeviceNameTooLong(_nameController.text.trim());

  /// Whether the user has set anything that Reset would clear.
  bool get _hasUserValues =>
      widget.initialName.isNotEmpty || widget.hasUserType;

  /// The category to save: null unless the user changed it, so a stored type
  /// the chips cannot show is not overwritten by "Auto".
  DeviceCategory? get _changedCategory =>
      _category == widget.initialCategory ? null : _category;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save(String name, DeviceCategory? category) async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(name, category);
      if (mounted) context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = localizeServiceError(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Not dismissible mid-save: closing it would drop the save's result and
    // any error. The barrier and Esc both go through this pop.
    return PopScope(
      canPop: !_saving,
      child: _buildDialog(context),
    );
  }

  Widget _buildDialog(BuildContext context) {
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
            enabled: !_saving,
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
          if (widget.showIcon) ...[
            AppGap.lg(),
            AppText.labelLarge(loc(context).deviceIcon),
            AppGap.sm(),
            AppChipGroup(
              chips: [
                for (final c in _choices)
                  ChipItem(
                    label: c == DeviceCategory.unknown
                        ? loc(context).auto
                        : c.resolveLabel(context),
                    icon: c.icon,
                    identifier: 'device-identity-icon-${c.name}',
                  ),
              ],
              selectedIndices: {_choices.indexOf(_category)},
              onSelectionChanged: (selected) {
                if (selected.isEmpty || _saving) return;
                setState(() => _category = _choices[selected.first]);
              },
            ),
          ],
          if (_saveError != null) ...[
            AppGap.md(),
            AppText.bodySmall(
              _saveError!,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ],
      ),
      actions: [
        AppButton.text(
          identifier: 'device-identity-reset',
          label: loc(context).reset,
          onTap: _hasUserValues && !_saving
              ? () => _save('', DeviceCategory.unknown)
              : null,
        ),
        AppButton.text(
          identifier: 'device-identity-cancel',
          label: loc(context).cancel,
          onTap: _saving ? null : () => context.pop(),
        ),
        AppButton.primary(
          identifier: 'device-identity-save',
          label: loc(context).save,
          isLoading: _saving,
          onTap: _tooLong || _saving
              ? null
              : () => _save(_nameController.text.trim(), _changedCategory),
        ),
      ],
    );
  }
}
