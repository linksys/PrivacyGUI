/// Strategies for monitoring a resource.
enum WatchStrategy {
  /// Only use polling (Timer-based).
  pollingOnly,

  /// Only use events (Subscription-based).
  /// If events fail or are unsupported, data will not update.
  eventOnly,

  /// Prefer events, but fallback to polling if subscription fails or is unsupported.
  eventPreferred,

  /// Use both events and polling.
  /// Useful if events are reliable for changes but you still want a periodic sync
  /// to ensure data integrity.
  hybrid,
}
