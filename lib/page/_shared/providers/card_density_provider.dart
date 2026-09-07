import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';

/// Forces a dashboard card to render a specific [CardDensity], ignoring its
/// measured width. Keyed by card widget ID (e.g. 'connected_devices').
///
/// `null` — the default — leaves the card's own width in charge.
///
/// This exists for the same reason `cardTabIndexProvider` does: a test that
/// needs a card in a particular state should put it there directly rather than
/// simulating the gesture that produces it. The #1183 overflow gate pumps tabs
/// this way instead of tapping, and pins a density the same way instead of
/// pumping at a contrived width.
///
/// NOT autoDispose — matches `cardTabIndexProvider`, so an override survives a
/// card scrolling out of view.
final cardDensityOverrideProvider =
    StateProvider.family<CardDensity?, String>((_, __) => null);
