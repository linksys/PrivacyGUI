import 'package:equatable/equatable.dart';

/// Whether the session's core subscriptions are in place.
///
/// The dashboard renders and fetches **before** these are registered, on purpose
/// (subscription POSTs would compete with the first reads), so "the page is up"
/// and "the page keeps itself current" are two moments — about a minute apart on
/// the QA Guardian router. This is the second one.
sealed class CoreSubscriptionState extends Equatable {
  const CoreSubscriptionState();
}

/// Not registered yet, or the session that registered them has ended.
final class CoreSubscriptionsPending extends CoreSubscriptionState {
  const CoreSubscriptionsPending();

  @override
  List<Object?> get props => const [];
}

/// The registration has run. [failed] counts the ones that did not take, which
/// is what lets the UI say live updates may be incomplete rather than claim they
/// are not — a failed subscription ends the wait like a successful one, because
/// nothing would ever end it otherwise.
final class CoreSubscriptionsReady extends CoreSubscriptionState {
  final int registered;
  final int failed;

  const CoreSubscriptionsReady(
      {required this.registered, required this.failed});

  @override
  List<Object?> get props => [registered, failed];
}
