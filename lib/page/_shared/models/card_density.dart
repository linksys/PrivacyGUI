/// The three forms a dashboard card can render in, selected from the card's own
/// rendered width.
///
/// See `doc/dashboard/dashboard_density_design.md` §2.1. The three forms exist
/// because a dashboard card is user-resizable: the same card can be dragged from
/// 12 columns down to 3, and the grid's narrowest realization of a 3-column card
/// is 191.4px.
enum CardDensity {
  /// Icon plus a single value. Tapping opens the normal form in a dialog (#1239).
  popup,

  /// Reduced form: fewer rows, shorter labels, no secondary detail.
  compact,

  /// The card as designed, with everything it has to show.
  normal,
}

/// The width below which a card that has opted in renders its
/// [CardDensity.popup] form.
///
/// A constant rather than a per-card value: §2.1 fixes the *width* at 200px for
/// every card, because below it there is not room for a label and a value side
/// by side in any locale, whatever the card shows.
///
/// It is not, however, reached by every card. #1239 settled popup as **opt-in**
/// (§2.6c): the band is entered only through a declared [WidgetSpec.normalAbove],
/// so a card that declares none stays [CardDensity.normal] all the way down. See
/// [densityForWidth]. §2.1's table reads as an unconditional rule and should be
/// read against §2.6c, which is the later decision.
///
/// In pixels, never columns. §1.5: a 3-column card spans 191.4-422.0px depending
/// on screen width — a 2.2x range — so a column count does not name a width, and
/// 433 (span, screen) pairs invert against each other.
const double kPopupBelow = 200;

/// Selects the form a card of [width] should render.
///
/// [normalAbove] is the card's own declared threshold — the narrowest width at
/// which it is whole. Absent means the card has no degraded form and stays
/// [CardDensity.normal] at every width, popup included; per #1240 AC 2, absent
/// is the correct value for a card that fits at its narrowest realization.
///
/// #1240's own sweep found every card clean at its narrowest realization and so
/// expected *no* card to declare a threshold. Readability, measured separately,
/// then contradicted that: **6 of the 18 cards in [UspWidgetSpecs.all] declare
/// one** — `device_info`, `lan_info`, `ethernet_ports`, `connected_devices`,
/// `time_settings` and `network_health`, the cards #1288-#1291 found green but
/// unreadable at 191.4px. The other 12 declare none, which is also why the
/// popup band is unreachable for them.
///
/// Precedence, when a threshold is declared:
///
/// 1. `width >= normalAbove` selects normal. The declared threshold wins over
///    [kPopupBelow], so a card declaring a threshold *below* 200px is whole at
///    190px and simply has no compact band. Declaring one is almost certainly a
///    mistake, but the meaning is unambiguous rather than undefined.
/// 2. `width < kPopupBelow` selects popup.
/// 3. Otherwise compact.
CardDensity densityForWidth({required double width, double? normalAbove}) {
  if (normalAbove == null) return CardDensity.normal;
  if (width >= normalAbove) return CardDensity.normal;
  if (width < kPopupBelow) return CardDensity.popup;
  return CardDensity.compact;
}
