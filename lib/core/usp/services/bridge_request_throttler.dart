import 'dart:async';
import 'dart:collection';

import 'package:privacy_gui/core/utils/logger.dart';

/// Priority levels for queued requests.
///
/// Higher priority requests are dispatched before lower ones.
enum RequestPriority { high, normal, low }

/// Centralized request throttler for all outbound requests to the router.
///
/// Limits concurrent requests to [maxConcurrent] to prevent overwhelming the
/// router's lighttpd/CGI workers. OBUSPA is single-threaded, so only 1 USP
/// message is processed at a time — [maxConcurrent]=2 provides pipeline
/// effect (next request waits in bridge queue) without wasting connections.
/// Browser HTTP/1.1 allows 6 per origin; reserving slots for SSE + auth.
///
/// Features:
/// - **Concurrency limit**: FIFO queue with priority ordering
/// - **Per-request timeout**: Frees the slot if action exceeds [requestTimeout]
/// - **In-flight dedup**: Same cacheKey shares one Future across queue + active
/// - **Cache dedup**: Completed results within TTL are returned instantly
class BridgeRequestThrottler {
  BridgeRequestThrottler({
    this.maxConcurrent = 2,
    this.staggerDelay = const Duration(milliseconds: 80),
    this.defaultCacheTtl = const Duration(seconds: 5),
    this.requestTimeout = const Duration(seconds: 15),
  });

  final int maxConcurrent;
  final Duration staggerDelay;
  final Duration defaultCacheTtl;
  final Duration requestTimeout;

  int _active = 0;
  final _queue = SplayTreeMap<_QueueKey, _PendingRequest<dynamic>>();
  int _sequence = 0;
  bool _draining = false;
  Completer<void>? _idleCompleter;

  // In-flight: cacheKey → pending request (dispatched but not yet completed)
  final _inFlight = <String, _PendingRequest<dynamic>>{};

  // Cache: cacheKey → (Future, expiry)
  final _cache = <String, _CacheEntry<dynamic>>{};

  /// Enqueue a request for throttled execution.
  ///
  /// Dedup order: cache (completed) → in-flight (executing) → queue (waiting).
  /// If a match is found at any level, the existing Future is returned.
  Future<T> enqueue<T>({
    required String cacheKey,
    required Future<T> Function() action,
    Duration? cacheTtl,
    RequestPriority priority = RequestPriority.normal,
  }) {
    final ttl = cacheTtl ?? defaultCacheTtl;

    // 1. Check cache (completed results within TTL)
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.future as Future<T>;
    }

    // 2. Check in-flight (dispatched, executing)
    final active = _inFlight[cacheKey];
    if (active != null) {
      return active.completer.future as Future<T>;
    }

    // 3. Check queue (waiting to be dispatched)
    final queued = _findQueued(cacheKey);
    if (queued != null) {
      return queued.completer.future as Future<T>;
    }

    // 4. Create new pending request
    final completer = Completer<T>();
    final seq = _sequence++;
    final key = _QueueKey(priority, seq);
    final pending = _PendingRequest<T>(
      cacheKey: cacheKey,
      action: action,
      completer: completer,
      cacheTtl: ttl,
    );
    _queue[key] = pending;

    _drain();

    return completer.future;
  }

  /// Number of currently in-flight requests.
  int get activeCount => _active;

  /// Number of requests waiting in queue.
  int get queueLength => _queue.length;

  /// Clear all cached results.
  void clearCache() => _cache.clear();

  /// Resolves when the throttler has no active or queued requests.
  ///
  /// If already idle, returns immediately. Otherwise waits for all
  /// in-flight and queued requests to complete.
  Future<void> whenIdle() {
    if (_active == 0 && _queue.isEmpty) return Future.value();
    _idleCompleter ??= Completer<void>();
    return _idleCompleter!.future;
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  /// Drain the queue: dispatch requests up to [maxConcurrent].
  ///
  /// Uses [_draining] guard to prevent re-entrant drain loops from
  /// interleaving. The stagger delay is applied between dispatches in the
  /// drain loop (not in the finally block) to avoid idle gaps when multiple
  /// active requests complete simultaneously.
  void _drain() {
    if (_draining) return;
    _draining = true;

    Future<void>(() async {
      try {
        while (_active < maxConcurrent && _queue.isNotEmpty) {
          final entry = _queue.entries.first;
          _queue.remove(entry.key);
          _dispatch(entry.value);

          // Stagger: brief pause between dispatches to avoid burst-hammering
          // the router. Only stagger if more items remain AND we have capacity.
          if (_queue.isNotEmpty && _active < maxConcurrent) {
            await Future.delayed(staggerDelay);
          }
        }
      } finally {
        _draining = false;
      }
    });
  }

  void _dispatch(_PendingRequest<dynamic> pending) {
    _active++;
    _inFlight[pending.cacheKey] = pending;
    logger.t('[Throttler]: Dispatch (active=$_active, queue=${_queue.length}): '
        '${pending.cacheKey}');

    Future<void>(() async {
      try {
        // Per-request timeout: if the action exceeds [requestTimeout], free
        // the slot immediately. The underlying HTTP call may still complete
        // in the background, but the slot is released for other requests.
        final result = await pending.action().timeout(requestTimeout);
        if (!pending.completer.isCompleted) {
          pending.completer.complete(result);
        }

        // Cache the result
        _cache[pending.cacheKey] = _CacheEntry(
          future: pending.completer.future,
          expiresAt: DateTime.now().add(pending.cacheTtl),
        );
      } on TimeoutException {
        logger.w('[Throttler]: Request timeout (${requestTimeout.inSeconds}s): '
            '${pending.cacheKey}');
        if (!pending.completer.isCompleted) {
          pending.completer.completeError(
            TimeoutException(
              'Throttler: request exceeded ${requestTimeout.inSeconds}s',
              requestTimeout,
            ),
          );
        }
      } catch (e, st) {
        if (!pending.completer.isCompleted) {
          pending.completer.completeError(e, st);
        }
      } finally {
        _active--;
        _inFlight.remove(pending.cacheKey);
        if (_active == 0 && _queue.isEmpty && _idleCompleter != null) {
          _idleCompleter!.complete();
          _idleCompleter = null;
        }
        _drain();
      }
    });
  }

  _PendingRequest<dynamic>? _findQueued(String cacheKey) {
    for (final entry in _queue.entries) {
      if (entry.value.cacheKey == cacheKey) {
        return entry.value;
      }
    }
    return null;
  }
}

/// Queue key for priority + FIFO ordering.
///
/// Lower priority index = higher priority. Within same priority, lower
/// sequence = earlier (FIFO).
class _QueueKey implements Comparable<_QueueKey> {
  final RequestPriority priority;
  final int sequence;

  _QueueKey(this.priority, this.sequence);

  @override
  int compareTo(_QueueKey other) {
    final p = priority.index.compareTo(other.priority.index);
    if (p != 0) return p;
    return sequence.compareTo(other.sequence);
  }
}

class _PendingRequest<T> {
  final String cacheKey;
  final Future<T> Function() action;
  final Completer<T> completer;
  final Duration cacheTtl;

  _PendingRequest({
    required this.cacheKey,
    required this.action,
    required this.completer,
    required this.cacheTtl,
  });
}

class _CacheEntry<T> {
  final Future<T> future;
  final DateTime expiresAt;

  _CacheEntry({required this.future, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
