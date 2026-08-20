import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The dashboard page's title row: the page name, and the actions that apply to
/// the whole dashboard rather than to one card.
///
/// ## Why this is a widget of its own
///
/// It was `_buildHeader` inside `UspSliverDashboardView` until #1314. Two reasons
/// it moved out, and only the second is about tidiness:
///
/// 1. **It has to be measurable.** The header overflowed at and below 480px and
///    nothing caught it, because the #1183 overflow gate pumps *cards* at
///    computed card widths — it never renders a page at a screen width, so page
///    chrome is invisible to it by construction. Measuring the header meant being
///    able to pump it, and pumping the whole view means standing up the entire
///    dashboard orchestrator first. As a provider-free widget it pumps with
///    nothing at all, which is what makes a screen-width × 26-locale sweep
///    affordable (`test/page/shell/page_chrome_overflow_test.dart`).
/// 2. It keeps the responsive decision in one place rather than inline in a
///    600-line view.
///
/// Deliberately takes no `WidgetRef` and reads no provider: every input is a
/// value or a callback the view supplies.
class DashboardHeaderBar extends StatelessWidget {
  const DashboardHeaderBar({
    super.key,
    required this.isEditMode,
    required this.isRemoteMode,
    required this.onPrint,
    required this.onRefresh,
    required this.onEdit,
    required this.onOptimizeLayout,
    required this.onLayoutSettings,
    required this.onCancelEdit,
    required this.onCommitEdit,
  });

  /// Whether the dashboard is in layout-edit mode, which swaps the whole action
  /// set (optimize / settings / cancel / done) for the viewing one.
  final bool isEditMode;

  /// Remote (cloud) sessions cannot edit the layout, so the edit action is
  /// dropped entirely rather than disabled.
  final bool isRemoteMode;

  final VoidCallback onPrint;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onOptimizeLayout;
  final VoidCallback onLayoutSettings;
  final VoidCallback onCancelEdit;
  final VoidCallback onCommitEdit;

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context);
    // One breakpoint, the app-wide one. The measured failure band was <=480px, so
    // <=600 covers it with room to spare, and reusing `isMobileLayout` keeps this
    // page's idea of "narrow" the same as every other page's — a bespoke constant
    // here would be a second, quieter breakpoint to keep in sync.
    final collapsed = context.isMobileLayout;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // One line in both forms, one type size smaller once collapsed. Both
        // halves are measured, not chosen.
        //
        // Collapsing the actions is what frees the title's width and it is all
        // there is to free: at 320px what remains of the row is one icon button
        // and one menu trigger, leaving the title exactly 188px. At
        // `headlineSmall` (24px) that is not enough — `sv` "Instrumentpanel"
        // wants 191.6px, and `el` (186.9), `fr` (186.1) and `vi` (183.3) clear
        // the box by 1–5px, so any future wording or font change tips them over.
        // At `titleLarge` (22px) the widest of the 26 locales is `sv` at 175.6px
        // — every locale on one line with at least 12px of headroom.
        //
        // Two lines were the alternative and they are worse here: wrapping a
        // 2–3 word page title reads as a paragraph, and it does not actually
        // rescue a locale whose *single longest word* overruns the box —
        // Flutter breaks that word mid-way ("Instrumentpane / l"), which no
        // reader can parse and which `didExceedMaxLines` reports as clean.
        Flexible(
          child: collapsed
              ? AppText.titleLarge(
                  loc(context).uspDashboard,
                  maxLines: 1,
                  // Last line of defence, not the fix. Ellipsis alone would
                  // have made the gate green and the header useless — the title
                  // would truncate to a couple of characters while the row
                  // measured clean. With the size above it should never fire;
                  // the suite asserts as much for all 26 locales at 320px.
                  overflow: TextOverflow.ellipsis,
                )
              : AppText.headlineSmall(
                  loc(context).uspDashboard,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        collapsed
            ? _buildCollapsedActions(context, actions)
            : _buildFullActions(actions),
      ],
    );
  }

  /// The actions in display order, with exactly one marked primary.
  ///
  /// Order and identifiers are unchanged from the pre-#1314 header, so the wide
  /// form renders exactly as it did and every existing E2E selector still
  /// resolves there.
  List<_HeaderAction> _actions(BuildContext context) {
    if (isEditMode) {
      return [
        _HeaderAction(
          identifier: 'dashboard-optimize-layout',
          label: loc(context).optimizeLayout,
          icon: Icons.auto_fix_high,
          onTap: onOptimizeLayout,
        ),
        _HeaderAction(
          identifier: 'dashboard-layout-settings',
          label: loc(context).settings,
          icon: Icons.tune,
          onTap: onLayoutSettings,
        ),
        _HeaderAction(
          identifier: 'dashboard-edit-cancel',
          label: loc(context).cancel,
          icon: Icons.close,
          onTap: onCancelEdit,
        ),
        // Committing the layout is the action the mode exists to reach, so it is
        // the one that survives the collapse.
        _HeaderAction(
          identifier: 'dashboard-edit-commit',
          label: loc(context).done,
          icon: Icons.check,
          onTap: onCommitEdit,
          isPrimary: true,
        ),
      ];
    }
    return [
      _HeaderAction(
        identifier: 'dashboard-print',
        label: loc(context).print,
        icon: Icons.print,
        onTap: onPrint,
      ),
      // Refreshing is the only one of the three a reader might repeat, and the
      // only one whose value is immediacy, so it keeps its own button.
      _HeaderAction(
        identifier: 'dashboard-refresh',
        label: loc(context).refresh,
        icon: Icons.refresh,
        onTap: onRefresh,
        isPrimary: true,
      ),
      if (!isRemoteMode)
        _HeaderAction(
          identifier: 'dashboard-edit',
          label: loc(context).edit,
          icon: Icons.edit,
          onTap: onEdit,
        ),
    ];
  }

  Widget _buildFullActions(List<_HeaderAction> actions) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) AppGap.sm(),
          _iconButton(actions[i]),
        ],
      ],
    );
  }

  /// The narrow form: the primary action, and everything else behind one menu.
  ///
  /// This is also #1314's second half. The header's width no longer scales with
  /// the number of actions — a fifth one lands in the menu and costs the row
  /// nothing — which is why "we cannot add another header button" stopped being
  /// true. The suite pins that by asserting the collapsed row is the same width
  /// in viewing mode (three actions) as in edit mode (four).
  Widget _buildCollapsedActions(
    BuildContext context,
    List<_HeaderAction> actions,
  ) {
    final primary = actions.firstWhere((a) => a.isPrimary);
    final overflow = actions.where((a) => !a.isPrimary).toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconButton(primary),
        if (overflow.isNotEmpty) ...[
          AppGap.xs(),
          // `AppPopupMenu` has no `identifier` of its own — its trigger builds a
          // `Semantics(container: true)` with a label and no identifier — so the
          // E2E anchor goes on a boundary of ours, the same shape
          // `card_form_toolbar.dart` uses.
          Semantics(
            container: true,
            identifier: 'dashboard-header-more',
            child: AppPopupMenu<VoidCallback>(
              icon: Icons.more_vert,
              iconSize: 20,
              // Flutter's own "Show menu", already translated for all 26
              // locales, and the exact string `AppPopupMenu` falls back to for
              // its tooltip when none is given — so the trigger reads the same
              // way to a screen reader and to a pointer without adding an ARB
              // key for it.
              //
              // It goes here rather than on the `Semantics` above because
              // `AppPopupMenu` already annotates its trigger as a labelled
              // button carrying the tap action. A second label on our boundary
              // would be a second thing announced for one control.
              semanticLabel: MaterialLocalizations.of(context).showMenuTooltip,
              items: overflow
                  .map((a) => AppPopupMenuItem<VoidCallback>(
                        value: a.onTap,
                        label: a.label,
                        icon: a.icon,
                        // Same identifier the button carries in the wide form, so
                        // one selector covers both — it just needs the menu open
                        // first when the viewport is narrow.
                        identifier: a.identifier,
                      ))
                  .toList(),
              onSelected: (action) => action(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _iconButton(_HeaderAction action) {
    return AppIconButton(
      identifier: action.identifier,
      semanticLabel: action.label,
      tooltip: action.label,
      icon: AppIcon.font(action.icon),
      onTap: action.onTap,
    );
  }
}

/// One dashboard-level action, in the form both the button and the menu item can
/// be built from.
///
/// Having the two forms read the same declaration is the point: the identifier,
/// the label and the callback cannot drift between the wide header and the
/// collapsed one, because there is only one of each.
class _HeaderAction {
  const _HeaderAction({
    required this.identifier,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  final String identifier;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Whether this action keeps a button of its own when the header collapses.
  /// Exactly one action per mode sets it.
  final bool isPrimary;
}
