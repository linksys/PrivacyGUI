import 'dart:async';
import 'package:logging/logging.dart';
import 'watch_strategy.dart';
import 'polling_manager.dart';

/// A reusable watcher that handles data monitoring via Push (Subscription) or Pull (Polling).
///
/// NOTE: [pollingManager] must be injected. The App layer controls the PollingManager instance.
class ResourceWatcher<T> {
  final String path;
  final WatchStrategy strategy;
  final Duration pollingInterval;
  final PollingManager pollingManager;

  /// Function to fetch data (Pull)
  final Future<T> Function() fetchData;

  /// Function to establish subscription (Push)
  /// Returns valid/invalid result.
  final Future<void> Function()? ensureSubscription;

  /// Stream of notifications for this resource.
  final Stream<T>? notificationStream;

  /// Callback to check if events are supported for this resource.
  final bool Function()? checkEventSupport;

  final Logger _logger;
  Timer? _pollingTimer;
  final StreamController<T> _controller = StreamController<T>.broadcast();
  bool _isDisposed = false;
  StreamSubscription<bool>? _pauseSubscription;
  StreamSubscription<T>? _notificationSubscription;

  ResourceWatcher({
    required this.path,
    required this.fetchData,
    required this.pollingManager,
    this.strategy = WatchStrategy.eventPreferred,
    this.pollingInterval = const Duration(seconds: 5),
    this.ensureSubscription,
    this.notificationStream,
    this.checkEventSupport,
  }) : _logger = Logger('ResourceWatcher[$path]');

  /// Starts the watcher.
  Stream<T> start() {
    if (_isDisposed) {
      _logger.warning('Attempted to start disposed watcher');
      return const Stream.empty();
    }

    _decideAndExecuteStrategy();

    // Listen to global pause/resume
    _pauseSubscription = pollingManager.pauseStateStream.listen((paused) {
      if (paused) {
        _stopPollingTimer();
      } else {
        // Resume polling if strategy dictates
        if (_shouldPoll()) {
          _startPolling();
        }
      }
    });

    return _controller.stream;
  }

  bool _shouldPoll() {
    // Check global pause
    if (pollingManager.isPaused) return false;
    return _isPollingMode;
  }

  bool _isPollingMode = false;

  Future<void> _decideAndExecuteStrategy() async {
    bool supportsEvents =
        checkEventSupport?.call() ?? (notificationStream != null);

    bool usePolling = false;
    bool useEvents = false;

    switch (strategy) {
      case WatchStrategy.pollingOnly:
        usePolling = true;
        break;
      case WatchStrategy.eventOnly:
        if (supportsEvents) useEvents = true;
        break;
      case WatchStrategy.eventPreferred:
        if (supportsEvents) {
          useEvents = true;
        } else {
          usePolling = true;
        }
        break;
      case WatchStrategy.hybrid:
        useEvents = supportsEvents;
        usePolling = true;
        break;
    }

    if (useEvents) {
      bool subscriptionSuccess = await _setupSubscription();
      if (!subscriptionSuccess && strategy == WatchStrategy.eventPreferred) {
        _logger
            .info('Subscription failed/unsupported, falling back to polling');
        usePolling = true;
      }
    }

    if (usePolling) {
      _isPollingMode = true;
      _startPolling();
    } else {
      _isPollingMode = false;
    }
  }

  Future<bool> _setupSubscription() async {
    if (ensureSubscription == null || notificationStream == null) return false;

    try {
      await ensureSubscription!();

      // Listen to notification stream and store subscription for cleanup
      _notificationSubscription = notificationStream!.listen((data) {
        if (!_isDisposed && !_controller.isClosed) {
          _controller.add(data);
        }
      });
      return true;
    } catch (e) {
      _logger.warning('Subscription error: $e');
      return false;
    }
  }

  void _startPolling() {
    if (pollingManager.isPaused) return;

    _logger.fine('Starting polling (${pollingInterval.inSeconds}s)');
    _fetchSafe(); // Initial fetch

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(pollingInterval, (_) => _fetchSafe());
  }

  void _stopPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _fetchSafe() async {
    if (_isDisposed || _controller.isClosed) return;
    try {
      final data = await fetchData();
      if (!_controller.isClosed) {
        _controller.add(data);
      }
    } catch (e) {
      if (!_controller.isClosed) {
        _controller.addError(e);
      }
    }
  }

  void stop() {
    _isDisposed = true;
    _stopPollingTimer();
    _pauseSubscription?.cancel();
    _notificationSubscription?.cancel();
    _controller.close();
  }
}
