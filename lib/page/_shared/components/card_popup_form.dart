import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Space left between the presented normal form and the edge of the screen.
///
/// Both sides, so a dialog can never be flush against the viewport. Named
/// because the "is this screen wide enough for a dialog" decision below is made
/// of exactly this plus the dialog's own chrome — a literal in two places would
/// let the decision and the geometry drift apart.
const double kCardPresentationInset = 24.0;

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
    showCardNormalForm(
      context,
      normalForm: normalForm,
      normalAbove: CardDensityScope.normalAboveOf(context),
      // The popup form still occupies the card's whole grid cell, so its own box
      // *is* the height the grid gives this card — no spec lookup, and no
      // invented number. Read at tap time, which is after layout.
      cardHeight: context.size?.height,
    );
  }
}

/// Presents [normalForm] over the popup form, at the widest width the screen can
/// give it up to the card's own [normalAbove].
///
/// ## The width is the whole point
///
/// The form being presented is the one that did not fit — so handing it a narrow
/// box reproduces exactly the overflow the popup form was introduced to avoid.
/// Two numbers bound it: the screen, and the width the card declared it needs.
/// The smaller wins, and when the card declared nothing the screen alone decides
/// (widest is safest, since overflow is monotonic in width).
///
/// `ui_kit`'s dialog defaults to 400px, which is narrower than most cards need,
/// so the width is injected as a [DialogStyle] override on this one dialog —
/// caller-side, per constitution Article XIV. Nothing in `ui_kit` changes, and no
/// other dialog in the app is affected.
///
/// ## Why a sheet on a narrow screen
///
/// A dialog spends [kCardPresentationInset] on each side plus its own padding
/// and border. On a 320px screen that is most of the width the card was asking
/// for. When what is left is narrower than the card's declared fit width, the
/// dialog cannot show the form whole no matter how it is styled, so the
/// presentation switches to a full-bleed bottom sheet, which spends none of the
/// width on chrome. It still may not reach the declared width — nothing on that
/// screen can — but it is the widest the device has.
Future<void> showCardNormalForm(
  BuildContext context, {
  required Widget normalForm,
  required double? normalAbove,
  required double? cardHeight,
}) {
  final screen = MediaQuery.sizeOf(context);
  final dialogStyle =
      Theme.of(context).extension<AppDesignTheme>()?.dialogStyle;

  // Chrome is padding plus border on both sides: `AppSurface` draws its border
  // inside its box, so the content gets that much less. Counted so the max width
  // asked of the dialog is a width for the *card*, not for the dialog.
  final chrome =
      (dialogStyle?.padding ?? const EdgeInsets.all(24.0)).horizontal +
          (dialogStyle?.containerStyle.borderWidth ?? 0.0) * 2;
  final dialogCanOffer = screen.width - kCardPresentationInset * 2 - chrome;

  // Falls back to a fraction of the viewport only if the tap arrived from
  // something that has no box, which a laid-out card always has.
  final height = cardHeight ?? screen.height * 0.6;

  final content = SizedBox(
    // Fills whatever the presentation ends up granting rather than naming a
    // width: if the chrome above is ever underestimated, the form is a little
    // narrower than asked instead of being over-constrained into a broken
    // layout.
    width: double.infinity,
    height: height,
    child: CardDensityScope(
      // The form shown here is the normal one by definition, and there is
      // nowhere further to degrade to — so no threshold travels into it.
      density: CardDensity.normal,
      child: normalForm,
    ),
  );

  if (normalAbove != null && dialogCanOffer < normalAbove) {
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

  final maxWidth = math.min(
    screen.width - kCardPresentationInset * 2,
    normalAbove == null ? double.infinity : normalAbove + chrome,
  );

  return showAppDialog<void>(
    context: context,
    // `withOverride` on the theme's own instance is the only way in: `DialogStyle`
    // carries a full `SurfaceStyle`, so there is no standalone one to build. With
    // the extension absent the dialog keeps ui_kit's 400px default and a wider
    // card is under-served — a themeless app, which nothing here can repair, and
    // which every other dialog in the app is equally subject to.
    builder: (_) => AppDialog(
      dialogStyle: dialogStyle?.withOverride(maxWidth: maxWidth),
      content: content,
    ),
  );
}
