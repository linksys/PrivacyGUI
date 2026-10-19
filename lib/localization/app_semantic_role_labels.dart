import 'package:flutter/widgets.dart' show Locale;
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:ui_kit_library/ui_kit.dart'
    show SemanticRoleLabel, SemanticRoleLabels;

/// Translates the role word ui_kit announces for a control no caller named —
/// `AppSwitch`'s "Switch", `AppIconButton`'s "Icon button" (#1315).
///
/// The kit ends each component's label chain in [SemanticRoleLabels.of], which
/// is English unless the host installs a resolver. This is a fallback, not a
/// name: a call site's own `semanticLabel` or `label` is read first and never
/// reaches here.
///
/// The resolver is handed a [Locale], not a `BuildContext`, so it reads strings
/// through [lookupAppLocalizations] rather than `loc(context)`. It runs during
/// `build`, so it stays pure.
class AppSemanticRoleLabels {
  AppSemanticRoleLabels._();

  /// Injects [resolve] into ui_kit. Call once at startup.
  static void install() {
    SemanticRoleLabels.resolver = resolve;
  }

  /// The localized role word, or null to keep the kit's English default.
  ///
  /// Null for a null locale (no `Localizations` ancestor), for a locale this app
  /// does not ship — [lookupAppLocalizations] throws on one — and for the roles
  /// nothing in `lib/` reaches.
  static String? resolve(
    Locale? locale,
    SemanticRoleLabel role,
    String? target,
  ) {
    if (locale == null || !AppLocalizations.delegate.isSupported(locale)) {
      return null;
    }
    final l10n = lookupAppLocalizations(locale);
    // Exhaustive on purpose: a role added in a kit bump is a compile error
    // here, so someone decides whether it needs a string.
    return switch (role) {
      SemanticRoleLabel.bottomSheet => l10n.semanticRoleBottomSheet,
      // The string the app already hands `AppSwitch.busySemanticLabel`, so a
      // busy button and a busy switch are announced alike.
      SemanticRoleLabel.busy => l10n.processing,
      SemanticRoleLabel.checkbox => l10n.semanticRoleCheckbox,
      SemanticRoleLabel.dropdown => l10n.semanticRoleDropdown,
      SemanticRoleLabel.iconButton => l10n.semanticRoleIconButton,
      SemanticRoleLabel.ipAddress => l10n.ipAddress,
      SemanticRoleLabel.listTile => l10n.semanticRoleListTile,
      SemanticRoleLabel.mascot => l10n.semanticRoleMascot,
      SemanticRoleLabel.menu => l10n.menu,
      SemanticRoleLabel.pinInput => l10n.semanticRolePinInput,
      SemanticRoleLabel.radio => l10n.semanticRoleRadio,
      SemanticRoleLabel.toggle => l10n.semanticRoleSwitch,
      // Unreachable from `lib/`: `GlobalMaterialLocalizations` names every
      // dismiss barrier before the kit asks, and nothing mounts a slider or a
      // side sheet, or sets `onDeleted:` on an `AppTag`/`AppBadge`.
      SemanticRoleLabel.deleteTarget ||
      SemanticRoleLabel.dismissBarrier ||
      SemanticRoleLabel.sideSheet ||
      SemanticRoleLabel.slider =>
        null,
    };
  }
}
