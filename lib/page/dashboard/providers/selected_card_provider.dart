import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The card the user has selected in the grid, or null when the selection is not
/// a single card (#1299).
///
/// ## Why a provider and not the beacon
///
/// The selection itself lives on `DashboardController.selectedItemIds`, a
/// `state_beacon` beacon owned by the `sliver_dashboard` package. Watching a
/// beacon from a widget needs `state_beacon`'s own `watch(context)` extension,
/// and `state_beacon` is a transitive dependency here — the package does not
/// re-export it. Nothing in `lib/` observes a beacon from a widget for that
/// reason; every other reactive read in this app is Riverpod. So the beacon is
/// mirrored into this provider by
/// [UspSliverDashboardControllerNotifier], the way `cardFormsProvider` is
/// published, and the widgets stay on one reactive mechanism.
///
/// ## Exactly one, or none
///
/// The grid supports shift-click multi-selection, but a form is picked per card,
/// so a control acting on "the selection" needs an unambiguous target. Two cards
/// selected therefore reads the same as none: the toolbar shows its prompt
/// instead of a picker, rather than silently reshaping whichever card happens to
/// be first.
///
/// This is a read model with exactly one writer. Widgets watch it; only the
/// controller notifier assigns to it.
final selectedCardIdProvider = StateProvider<String?>((_) => null);
