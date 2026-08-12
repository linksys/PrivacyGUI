import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'base_blocks.dart';
import 'block_constants.dart';

// =============================================================================
// SwitchBlock - Toggle setting with label and optional description
// =============================================================================

/// Block with a toggle switch for on/off settings.
///
/// Common pattern in Firewall, Local Network, WiFi Settings.
class SwitchBlock extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final IconData? icon;
  final String? semanticLabel;

  /// Stable, screen-reader-silent test hook (→ `flt-semantics-identifier`).
  /// Prefer this over positional selectors in E2E; see PrivacyGUI#1172.
  final String? identifier;

  const SwitchBlock({
    super.key,
    required this.label,
    this.description,
    required this.value,
    this.onChanged,
    this.icon,
    this.semanticLabel,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBlock(
      padding: BlockConstants.paddingMd,
      child: Semantics(
        identifier: identifier,
        label: semanticLabel,
        child: Row(
          children: [
            if (icon != null) ...[
              AppIcon.font(
                icon!,
                size: BlockConstants.iconMd,
                color: colorScheme.onSurfaceVariant,
              ),
              AppGap.sm(),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(label),
                  if (description != null) ...[
                    AppGap.xxs(),
                    AppText.bodySmall(
                      description!,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
            AppGap.md(),
            AppSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SettingBlock - Editable setting row with title, value, and action
// =============================================================================

/// Block for displaying and editing a setting value.
///
/// Common pattern in WiFi Network Card, DHCP, Port Forwarding.
/// Shows title + current value, with optional trailing widget (edit icon, switch).
class SettingBlock extends StatelessWidget {
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Stable, screen-reader-silent test hook (→ `flt-semantics-identifier`).
  final String? identifier;

  const SettingBlock({
    super.key,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: LayoutBlock(
        onTap: onTap,
        padding: BlockConstants.paddingListItem,
        child: Semantics(
          identifier: identifier,
          label: semanticLabel,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyMedium(title),
                    if (value != null) ...[
                      AppGap.xs(),
                      AppText.labelLarge(value!),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                AppGap.md(),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// NavLinkBlock - Navigation link to another page
// =============================================================================

/// Block that navigates to another page when tapped.
///
/// Common pattern for section links (Firewall → IPv6 Port Service, etc.)
class NavLinkBlock extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final VoidCallback onTap;

  /// Stable, screen-reader-silent test hook (→ `flt-semantics-identifier`).
  final String? identifier;

  const NavLinkBlock({
    super.key,
    required this.title,
    this.description,
    this.icon,
    required this.onTap,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      identifier: identifier,
      button: true,
      child: LayoutBlock(
        onTap: onTap,
        padding: BlockConstants.paddingMd,
        child: Row(
          children: [
            if (icon != null) ...[
              AppIcon.font(
                icon!,
                size: BlockConstants.iconLg,
                color: colorScheme.onSurfaceVariant,
              ),
              AppGap.md(),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleSmall(title),
                  if (description != null) ...[
                    AppGap.xs(),
                    AppText.bodySmall(
                      description!,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
            AppIcon.font(
              Icons.chevron_right,
              size: BlockConstants.iconMd,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// FormFieldBlock - Block wrapper for form fields
// =============================================================================

/// Block containing a form input field.
///
/// Common pattern in DMZ, Local Network settings.
class FormFieldBlock extends StatelessWidget {
  final String? label;
  final Widget child;

  const FormFieldBlock({
    super.key,
    this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBlock(
      padding: BlockConstants.paddingMd,
      child: label != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelMedium(label!),
                AppGap.sm(),
                child,
              ],
            )
          : child,
    );
  }
}
