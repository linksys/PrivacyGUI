import 'dart:async';
import 'package:logging/logging.dart';

/// Manages the lifecycle of polling operations across the application.
///
/// Allows for global pausing/resuming of all polling (e.g., when app is in background
/// or user is logged out).
///
/// NOTE: This class is NOT a singleton. The App layer should create and manage
/// the instance via Riverpod Provider or similar DI mechanism.
class PollingManager {
  final Logger _logger = Logger('PollingManager');
  final _pauseController = StreamController<bool>.broadcast();

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  Stream<bool> get pauseStateStream => _pauseController.stream;

  void pauseAll() {
    if (_isPaused) return;
    _isPaused = true;
    _logger.info('⏸️ Polling globally paused');
    _pauseController.add(true);
  }

  void resumeAll() {
    if (!_isPaused) return;
    _isPaused = false;
    _logger.info('▶️ Polling globally resumed');
    _pauseController.add(false);
  }

  void dispose() {
    _pauseController.close();
  }
}
