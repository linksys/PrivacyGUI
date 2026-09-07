import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/card_form_choice.dart';

/// The form each card is in on the grid currently on screen (#1299).
///
/// A projection of the live layout, with exactly one writer:
/// `UspSliverDashboardControllerNotifier` subscribes to the controller's layout
/// beacon and republishes [CardForms.of] its items — see `_armFormsMirror`.
/// Nothing else writes it.
///
/// Why a projection rather than a notifier of its own: the picks have to be
/// readable from inside a card's build ([CardDensityHost]) and from the edit-mode
/// toolbar's form picker, but they *live* on the grid items, which is what makes it
/// impossible for a pick and the geometry it justifies to be persisted out of step
/// (#1400). A second store of the same picks is exactly the thing that ticket
/// deleted, so this holds a read of the first one and never the picks themselves.
///
/// The consequence for a test or a scope that overrides it: what changes is what
/// the cards render, and nothing else. Before #1400 the geometry was re-derived
/// from the published value on every import, so an override silently changed which
/// sizes were legal.
///
/// Not `autoDispose`: a pick outlives the dashboard route, and the layout
/// notifier that publishes it is not autoDispose either.
final cardFormsProvider = StateProvider<CardForms>((_) => CardForms.empty);
