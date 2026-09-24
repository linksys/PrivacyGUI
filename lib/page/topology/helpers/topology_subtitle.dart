import 'package:flutter/widgets.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_backhaul_link.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The one line under a node's name on a tree row, in the viewer's language.
///
/// Most of a subtitle is device data — a model string, an IP, a Wi-Fi band — which
/// reads the same in every locale, so `UspTopologyBuilder` puts it straight into
/// [GraphNode.extra] and this only has to pass it through.
///
/// A slave's backhaul medium is the exception, and it is why this exists. It
/// arrives as `MultiAPDevice.Backhaul.LinkType`, a **firmware string**, so putting
/// it in `extra` printed `Ethernet` on the screen in all 26 locales. The builder
/// has no `BuildContext` — it is a pure function over the mesh network, which is
/// what makes it testable — so the word cannot be chosen there. It is chosen here,
/// from the boolean the builder recorded instead.
class TopologySubtitle {
  TopologySubtitle._();

  /// [node]'s subtitle: its data from the builder, plus any word that had to wait
  /// for a locale.
  ///
  /// Returns the empty string rather than null because `subtitleBuilder` is
  /// `String Function(GraphNode)`; the tree draws no subtitle row for an empty one.
  static String build(BuildContext context, GraphNode node) {
    return _join([
      node.extra,
      _backhaul(context, node.metadata),
    ]);
  }

  /// A slave's backhaul as one phrase: the medium, and its signal when that is
  /// both meaningful and measured.
  ///
  /// Null when firmware named no medium. `LinkType = None` is the ordinary state
  /// on FL-WRT 2.0, not an error, and claiming `Wi-Fi` for it is the defect #1464
  /// closed — a subtitle is no place to re-introduce it. The caller drops the null,
  /// so such a row falls back to its model alone.
  ///
  /// The medium is classified through [isMeshBackhaulEthernet] rather than compared
  /// to a literal, so a build spelling the value differently still gets the right
  /// word — and, below, does not acquire a signal reading it has no business
  /// showing (#1555).
  ///
  /// The signal is withheld for a wired backhaul on the same grounds the link style
  /// is: a wire has no RSSI by design, so a reading beside `Ethernet` would be
  /// describing something else.
  static String? _backhaul(
      BuildContext context, Map<String, dynamic>? metadata) {
    final linkType = (metadata?['backhaulLinkType'] as String?)?.trim() ?? '';
    if (linkType.isEmpty ||
        linkType.toLowerCase() == meshBackhaulLinkTypeNone) {
      return null;
    }

    final wired = isMeshBackhaulEthernet(linkType);
    final medium = wired ? loc(context).ethernet : loc(context).wifi;

    final rssi = metadata?['backhaulSignalStrength'] as int?;
    if (wired || rssi == null) return medium;

    return '$medium ${loc(context).signalStrengthDbm(rssi.toString())}';
  }

  /// Joins with ` · `, dropping the parts a node has nothing for, so a row never
  /// leads with a separator and never shows a dangling one — which is what a naive
  /// `join` over a list containing empties produces.
  static String _join(List<String?> parts) {
    return parts
        .map((p) => p?.trim() ?? '')
        .where((p) => p.isNotEmpty)
        .join(' · ');
  }
}
