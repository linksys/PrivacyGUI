import 'package:flutter/widgets.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The words this app puts on a topology tree row, in the viewer's language.
///
/// ui_kit 3.4.0 stopped shipping label text for these two. That is the right
/// split — a UI library knows which authored appearance a node wears and which
/// state it is in, but not what either is called in our domain — and it also
/// closes a defect: until then the kit printed its own enum names, so the tree
/// row read `GATEWAY` / `online` in English in all 26 locales, and the 3.4.0
/// rename would have turned that into `PRIMARY` / `active`.
///
/// Shared by the dashboard card and the full-page view rather than written twice.
/// Both render the same tree with the same vocabulary, and a second copy is a
/// second place for a branch to go missing.
class TopologyTreeLabels {
  TopologyTreeLabels._();

  /// What to call the appearance [node] wears.
  ///
  /// Keyed on the slot the builder **stated**, which is this app's own
  /// classification round-tripped through the kit — `primary` is the master and
  /// `secondary` a slave.
  ///
  /// Null means no label is drawn, and three of the five cases take it
  /// deliberately rather than reaching for an approximate word:
  ///
  /// - **A leaf** — every localised string we have for it is plural (`devices`,
  ///   `clients`); there is no singular key, and a row label is singular. It is
  ///   also the row that needs one least, since a leaf is what a tree row is by
  ///   default. Adding six keys × 26 locales to caption the obvious is not worth
  ///   it; if a word is wanted later, add `device` to the ARB and fill this arm.
  /// - **An external node** — "Master" is wrong for the upstream endpoint, and it
  ///   is the one node whose meaning the picture already carries.
  /// - **`tertiary`** — authored and assignable, but nothing in this app assigns
  ///   it, so there is no domain word to give.
  static String? slot(
      BuildContext context, GraphNode node, NodeStyleSlot slot) {
    if (node.isExternal) return null;
    return switch (slot) {
      NodeStyleSlot.primary => loc(context).master.toUpperCase(),
      NodeStyleSlot.secondary => loc(context).slave.toUpperCase(),
      NodeStyleSlot.leaf => null,
      NodeStyleSlot.tertiary => null,
    };
  }

  /// What to call [state].
  ///
  /// `alert` returns null rather than borrowing one of the other two words: this
  /// app never puts a node in that state, so there is no string for it and
  /// inventing one would be asserting something about the node.
  static String? status(BuildContext context, NodeState state) {
    return switch (state) {
      NodeState.active => loc(context).online,
      NodeState.inactive => loc(context).offline,
      NodeState.alert => null,
    };
  }
}
