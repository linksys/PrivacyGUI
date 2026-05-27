import 'package:privacy_gui/core/usp/services/turbo_session_manager.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_upload_strategy.dart';

/// Stub factory for non-Web platforms.
/// WebSocket strategy is not available on non-Web.
FirmwareUploadStrategy createWsStrategy({
  required TurboSessionManager turboManager,
  required String wsUrl,
  String fromId = 'controller::localui',
  String toId = 'os::router',
}) {
  throw UnsupportedError('WebSocket strategy is only available on Web');
}
