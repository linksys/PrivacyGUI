import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Space left between the presented normal form and the edge of the screen.
///
/// Both sides, so a dialog can never be flush against the viewport. Named
/// because the "is this screen wide enough for a dialog" decision below is made
/// of exactly this plus [kCardPresentationWidth] — a literal in two places would
/// let the decision and the geometry drift apart.
const double kCardPresentationInset = 24.0;

/// Width the presented normal form is given, in logical pixels.
///
/// One number for every card, rather than the width each card declares it needs.
/// A declaration is a *threshold* — the width below which the card stops being
/// readable — and both formulas built on it produced a worse box than a constant
/// does: derived from the threshold, the dialog was a different size for every
/// card (they run 250 to 386); with no threshold declared it fell back to the
/// viewport, which on a desktop is one card in a dialog a thousand pixels wide.
///
/// 400 clears every threshold the specs declare, so no card is handed back a
/// width it has already said it cannot be read at — that floor is the one derived
/// thing here, and `dashboard_card_popup_overflow_test.dart` pins it because it is
/// the file that can see the specs. It is also `ui_kit`'s own dialog width, so the
/// presentation is the app's standard dialog rather than a bespoke one.
const double kCardPresentationWidth = 400.0;

/// The degraded form a dashboard card renders below [kPopupBelow]: its icon and
/// one value, with the full form one tap away (#1239).
///
/// ## Why a form rather than a smaller version of the card
///
/// Under ~200px there is no arrangement of a full card that stays readable — the
/// density design's §2.4 measurement is that shrinking type and clipping labels
/// produces something that technically fits and cannot be read. So the card
/// stops trying to show everything and shows the one thing worth seeing at a
/// glance, on the promise that the rest is still reachable. That promise is what
/// makes the tap target, the keyboard path and the screen-reader label part of
/// the form rather than polish: below 200px this widget is the *only* way to
/// read the card.
///
/// ## It fits by construction, not by measurement
///
/// One icon over one ellipsized line, in a column. No arrangement of a longer
/// localized string can overflow it, so the sweep in
/// `dashboard_card_popup_overflow_test.dart` confirms a property the layout
/// already guarantees instead of holding it up.
class CardPopupForm extends StatelessWidget {
  const CardPopupForm({
    super.key,
    required this.title,
    required this.normalForm,
    this.leading,
    this.value,
  });

  /// The card's title. Not displayed — the form has room for one line and the
  /// value is what earns it — but announced, so a screen reader hears which card
  /// this is.
  final String title;

  /// The card's full form, shown when this one is tapped.
  final Widget normalForm;

  /// The card's header icon, if it has one.
  final Widget? leading;

  /// The one value this card degrades to. Absent falls back to [title]: a card
  /// that declares a threshold should also declare its value, but a form with
  /// nothing in it is worse than one showing the card's name.
  final String? value;

  @override
  Widget build(BuildContext context) {
    final displayed = value ?? title;
    return AppCard(
      // The whole card is the target rather than a button inside it: at this
      // width a button large enough to hit would leave no room for the value.
      onTap: () => _open(context),
      semanticLabel: value == null ? title : '$title, $value',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            AppGap.sm(),
          ],
          // Flexible so a card only one grid row tall cannot overflow this
          // column vertically; the ellipsis is what keeps it inside
          // horizontally.
          Flexible(
            child: AppText.titleMedium(
              displayed,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context) {
    // Two candidate heights, and the larger wins — because this form cannot tell
    // which of the two routes into it was taken, and one of them poisons the box.
    //
    // Reached by *width* (#1239) the cell is trustworthy: the grid narrowed the
    // card and left its height alone, so the box is the height the card had, and
    // a user who dragged it taller than its spec's floor should get that height
    // back. Reached by a *pick* (#1299) it is not: `applyCardForms` pins the cell
    // to one grid row, so the box is a consequence of the degradation and is
    // roughly a third of what the card declares — sizing the presentation to it
    // lays the full form out in the very height the popup form existed to escape.
    //
    // `max` rather than a branch on the route: nothing here needs to know the
    // route, and more height can never cause the bottom overflow this avoids.
    // Both may be absent (a tap from something with no box, on a card with no
    // spec), and then the presentation picks its own fallback.
    final candidates = [
      CardDensityScope.normalHeightOf(context),
      // Read at tap time, which is after layout.
      context.size?.height,
    ].nonNulls;

    showCardNormalForm(
      context,
      normalForm: normalForm,
      cardHeight: candidates.isEmpty ? null : candidates.reduce(math.max),
    );
  }
}

/// Presents [normalForm] over the popup form, at [kCardPresentationWidth] and the
/// height the card needs.
///
/// ## One width, and the card decides nothing about it
///
/// The form being presented is the one that did not fit, so the box has to be
/// wide enough to read it — but that is a floor, not a formula, and the formulas
/// this used to compute are what [kCardPresentationWidth] replaces. See there for
/// why one constant beats both of them.
///
/// The width is injected as a [DialogStyle] override on this one dialog —
/// caller-side, per constitution Article XIV. Nothing in `ui_kit` changes, and no
/// other dialog in the app is affected.
///
/// ## The card is the frame
///
/// A dashboard card is already a bordered, filled, rounded surface, and
/// `AppDialog` draws one of its own around whatever it is handed — so the
/// presentation read as a frame inside a frame, the two borders separated by a
/// ring of dialog padding. The override paints nothing and spends nothing, which
/// leaves the card's own surface as the only frame on screen.
///
/// ## Why a sheet on a narrow screen
///
/// A screen narrower than the presentation plus [kCardPresentationInset] on each
/// side cannot seat the dialog at all, and a dialog clamped down to fit such a
/// screen would hand the card back a width near the one it degraded at. There the
/// presentation switches to a full-bleed bottom sheet, which spends none of the
/// width on chrome and gives the card the whole device. It still may not reach the
/// width the card asked for — nothing on that screen can — but it is the widest
/// the device has.
Future<void> showCardNormalForm(
  BuildContext context, {
  required Widget normalForm,
  required double? cardHeight,
}) {
  final screen = MediaQuery.sizeOf(context);
  final theme = Theme.of(context);
  final dialogStyle = theme.extension<AppDesignTheme>()?.dialogStyle;

  // Falls back to a fraction of the viewport only if the tap arrived from
  // something that has no box, which a laid-out card always has.
  final height = cardHeight ?? screen.height * 0.6;

  final content = SizedBox(
    // Fills whatever the presentation ends up granting rather than naming a
    // width, so the card is never over-constrained into a layout narrower than
    // the box it was given.
    width: double.infinity,
    height: height,
    child: CardDensityScope(
      // The form shown here is the normal one by definition, and there is
      // nowhere further to degrade to — so no threshold travels into it.
      density: CardDensity.normal,
      child: normalForm,
    ),
  );

  if (screen.width - kCardPresentationInset * 2 < kCardPresentationWidth) {
    return showAppBottomSheet<void>(
      context: context,
      // No padding: on the screen that triggered this branch, every pixel spent
      // on the sheet's own inset is a pixel the card asked for and did not get.
      // The card draws its own surface and padding anyway.
      padding: EdgeInsets.zero,
      maxHeight: screen.height,
      child: content,
    );
  }

  // Built rather than copied-from-the-theme-and-cleared: a `SurfaceStyle`'s
  // defaults already are "no border, no shadow, no blur, no gradient", so naming
  // two transparent colours is the whole of "paint nothing". Unsetting the
  // theme's own decorations one property at a time would silently start painting
  // again the day a theme adds one this call does not know to clear. The content
  // colour is still the theme's, for anything the card does not paint over.
  final unpainted = SurfaceStyle(
    backgroundColor: Colors.transparent,
    borderColor: Colors.transparent,
    contentColor:
        dialogStyle?.containerStyle.contentColor ?? theme.colorScheme.onSurface,
  );

  return showAppDialog<void>(
    context: context,
    // `withOverride` on the theme's own instance is the only way in: `DialogStyle`
    // carries a full `SurfaceStyle` and an `OverlaySpec`, so there is no
    // standalone one to build. With the extension absent the dialog keeps
    // ui_kit's defaults — the same 400px, but 24px of padding that cannot be
    // overridden from here, so a themeless app keeps the ring. Nothing here can
    // repair that, and every other dialog in the app is equally subject to it.
    builder: (_) => AppDialog(
      dialogStyle: dialogStyle?.withOverride(
        maxWidth: kCardPresentationWidth,
        padding: EdgeInsets.zero,
        containerStyle: unpainted,
      ),
      content: content,
    ),
  );
}
