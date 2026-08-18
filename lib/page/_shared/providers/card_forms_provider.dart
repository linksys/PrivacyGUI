import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/card_form_choice.dart';

/// The form each card was picked into, per breakpoint (#1299).
///
/// A read model, with exactly one writer:
/// `UspSliverDashboardControllerNotifier` owns the pref the picks live in and
/// republishes them here whenever it loads or changes them. Nothing else writes
/// it.
///
/// Why a mirror rather than a notifier of its own: the picks have to be readable
/// from inside a card's build ([CardDensityHost]) and from the edit-mode toolbar's
/// form picker, but they are stored in the same pref as the geometry they constrain —
/// see [UspLayoutEnvelope.forms] for why they cannot be split off. Two writers of
/// one pref is how the two halves of a single value drift apart, so there is one
/// owner and one read model.
///
/// Not `autoDispose`: a pick outlives the dashboard route, and the layout
/// notifier that writes it is not autoDispose either.
final cardFormsProvider = StateProvider<CardForms>((_) => CardForms.empty);
