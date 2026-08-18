import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';

/// The form a user picked for one card on one breakpoint, plus what it takes to
/// undo the pick.
///
/// #1299 inverts #1232's mechanism. #1232 reads a card's rendered width and
/// derives the form from it; this reads the form the user asked for and derives
/// the sizes that are legal. A [CardFormChoice] is the stored half of that
/// inversion: the geometry it implies is re-derived on every import by
/// `UspWidgetSpecs.applyCardForms`, never persisted twice.
///
/// Why the inversion does not contradict §2.1's "not a user preference": the
/// framework still guarantees the layout, it just guarantees it by constraining
/// the geometry rather than by degrading the content. On a phone the user has no
/// influence over width at all — the 4-column grid pins `x: 0, w: cols` and the
/// #1293 left-edge lock forbids horizontal resize outright — so a pick is the
/// only mechanism that puts a phone user in control of density.
class CardFormChoice extends Equatable {
  const CardFormChoice({
    required this.density,
    this.restoreW,
    this.restoreH,
  });

  final CardDensity density;

  /// The `w` the card had on this breakpoint before popup collapsed it, or null
  /// when the card is not in popup.
  ///
  /// Recorded on the way into popup and consumed on the way out, per breakpoint
  /// because each grid has its own geometry. Without it "cannot be resized" is a
  /// one-way door: an icon-and-one-value tile has no handles to drag back, so
  /// whatever the card was is unrecoverable unless it was written down.
  ///
  /// Deliberately not recorded for compact. Compact only ever *grows* a card, to
  /// its floor, and that width is one the card genuinely needs — the user can
  /// shrink it again the moment they return to normal, whose floor is lower.
  final int? restoreW;

  /// The `h` counterpart of [restoreW].
  final int? restoreH;

  /// Whether this choice carries a size to put back.
  bool get hasRestore => restoreW != null || restoreH != null;

  Map<String, dynamic> toJson() => {
        'density': density.name,
        if (restoreW != null) 'restoreW': restoreW,
        if (restoreH != null) 'restoreH': restoreH,
      };

  /// Parses one stored choice, or returns null when it cannot be read.
  ///
  /// An unreadable choice is dropped rather than rejecting the whole payload:
  /// the geometry beside it is the user's real work, and losing a density pick
  /// is a far smaller loss than resetting a dashboard they arranged.
  static CardFormChoice? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final density = CardDensity.values.asNameMap()[raw['density']];
    if (density == null) return null;
    final restoreW = raw['restoreW'];
    final restoreH = raw['restoreH'];
    return CardFormChoice(
      density: density,
      restoreW: restoreW is int ? restoreW : null,
      restoreH: restoreH is int ? restoreH : null,
    );
  }

  @override
  List<Object?> get props => [density, restoreW, restoreH];

  @override
  String toString() => 'CardFormChoice(${density.name}'
      '${hasRestore ? ', restore ${restoreW}x$restoreH' : ''})';
}

/// Every card's chosen form, keyed by breakpoint then by card id.
///
/// Per breakpoint because "compact on a phone, normal on a laptop" is the
/// primary use case this ticket exists for — a single global value would be
/// wrong by design, and a value stored outside [UspLayoutEnvelope] would repeat
/// #1293's trap of a preference that is not keyed by the grid it describes.
///
/// Absent means "no pick": the card falls back to #1232's width-derived form.
/// That is not the same as an explicit [CardDensity.normal], which pins the card
/// to normal at every width — see `UspWidgetSpecs.applyCardForms`.
///
/// Value equality is load-bearing rather than decorative: this is the value of a
/// `StateProvider` (`cardFormsProvider`), and every reload and every revert
/// republishes a freshly built instance. On identity alone each of those would
/// rebuild every card that reads its density, for picks that did not change.
/// [Equatable] compares the nested map deeply, keys included.
class CardForms extends Equatable {
  const CardForms(this.byBreakpoint);

  static const CardForms empty = CardForms({});

  final Map<int, Map<String, CardFormChoice>> byBreakpoint;

  bool get isEmpty => byBreakpoint.values.every((choices) => choices.isEmpty);

  bool get isNotEmpty => !isEmpty;

  /// The picks on the [slotCount]-wide grid.
  Map<String, CardFormChoice> at(int slotCount) =>
      byBreakpoint[slotCount] ?? const {};

  CardFormChoice? choiceFor(int slotCount, String cardId) =>
      at(slotCount)[cardId];

  /// The form picked for [cardId] on the [slotCount]-wide grid, or null when the
  /// user has not picked one and the width should decide.
  CardDensity? densityFor(int slotCount, String cardId) =>
      choiceFor(slotCount, cardId)?.density;

  /// Returns a copy with [cardId]'s pick on [slotCount] replaced, or removed
  /// when [choice] is null.
  CardForms withChoice(int slotCount, String cardId, CardFormChoice? choice) {
    final choices = Map<String, CardFormChoice>.from(at(slotCount));
    if (choice == null) {
      choices.remove(cardId);
    } else {
      choices[cardId] = choice;
    }
    final next = Map<int, Map<String, CardFormChoice>>.from(byBreakpoint);
    if (choices.isEmpty) {
      next.remove(slotCount);
    } else {
      next[slotCount] = choices;
    }
    return CardForms(next);
  }

  /// Returns a copy with [cardId]'s pick dropped from every breakpoint.
  ///
  /// Membership is not per breakpoint — deleting a card deletes the card — so a
  /// pick that outlived its card would come back the moment the card was re-added
  /// and silently apply a form the user chose in a previous session.
  CardForms withoutCard(String cardId) {
    final next = <int, Map<String, CardFormChoice>>{};
    for (final entry in byBreakpoint.entries) {
      final choices = {
        for (final choice in entry.value.entries)
          if (choice.key != cardId) choice.key: choice.value,
      };
      if (choices.isNotEmpty) next[entry.key] = choices;
    }
    return CardForms(next);
  }

  Map<String, dynamic> toJson() => {
        for (final entry in byBreakpoint.entries)
          if (entry.value.isNotEmpty)
            entry.key.toString(): {
              for (final choice in entry.value.entries)
                choice.key: choice.value.toJson(),
            },
      };

  /// Parses stored picks, dropping anything unreadable.
  ///
  /// Never returns null and never throws: see [CardFormChoice.tryFromJson] for
  /// why a bad pick must not cost the user their layout.
  static CardForms fromJson(Object? raw) {
    if (raw is! Map) return empty;
    final byBreakpoint = <int, Map<String, CardFormChoice>>{};
    for (final entry in raw.entries) {
      final slotCount = int.tryParse('${entry.key}');
      final choices = entry.value;
      if (slotCount == null || choices is! Map) continue;
      final parsed = <String, CardFormChoice>{};
      for (final choice in choices.entries) {
        final value = CardFormChoice.tryFromJson(choice.value);
        if (value != null) parsed['${choice.key}'] = value;
      }
      if (parsed.isNotEmpty) byBreakpoint[slotCount] = parsed;
    }
    return CardForms(byBreakpoint);
  }

  @override
  List<Object?> get props => [byBreakpoint];

  @override
  String toString() => 'CardForms($byBreakpoint)';
}
