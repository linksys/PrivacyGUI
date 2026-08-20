import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Fraction of the row a fixed label column may claim.
///
/// At the narrowest card realization (191px) this leaves the value ~115px,
/// enough for the longest common value on one line. The split favours the
/// value on purpose: per density design §2.10a the label is a name and the
/// value is the payload, so the label is what yields.
///
/// Public because a second, unrelated module now derives a fixed label column
/// from the row's real width the same way (`usp_wifi_status_card.dart`'s
/// Channel row, #1251). Per constitution Article V §5.3 the shared arithmetic
/// moves out of a single module once a second consumer converges on it — this
/// is that moment, so the two constants live here (the only current home of
/// the row-derived label-column rule) rather than being copied.
const double kUspLabelShare = 0.4;

/// Ceiling for a fixed label column, so a wide row does not open an absurd
/// gutter before the value. Sits inside the 130–187px band that the old
/// screen-derived `context.colWidth(2)` produced across desktop breakpoints,
/// so rows that were already wide enough keep roughly the column they had.
const double kUspLabelMaxWidth = 150.0;

/// A label–value row used throughout the USP Dashboard cards.
///
/// The label column is sized from the width the row is actually given (read
/// via a [LayoutBuilder]), never from screen width: inside a shrunken card
/// the two are unrelated, and a screen-derived column over-claims and clips
/// the value against the card surface without raising an overflow.
///
/// Degradation follows the shape settled in #1226 and applied in #1233 — the
/// label yields first with a one-line ellipsis, while the value never shrinks
/// and never ellipsizes. A clipped label is still recoverable from context; a
/// half-shown value misinforms.
class UspInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const UspInfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final labelWidth = math.min(
              constraints.maxWidth * kUspLabelShare, kUspLabelMaxWidth);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: AppText.labelLarge(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(child: AppText.bodyMedium(value)),
            ],
          );
        },
      ),
    );
  }
}
