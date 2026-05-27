import 'package:privacy_gui/core/usp/services/turbo_session_manager.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_upload_strategy.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_ws_upload_strategy.dart';

/// Web factory that creates the WebSocket upload strategy.
///
/// [fromId] defaults to 'controller::localui-turbo' to match turbo channel usage.
FirmwareUploadStrategy createWsStrategy({
  required TurboSessionManager turboManager,
  required String wsUrl,
  String fromId = 'controller::localui-turbo',
  String toId = 'os::router',
}) {
  return FirmwareWsUploadStrategy(
    turboManager: turboManager,
    wsUrl: wsUrl,
    fromId: fromId,
    toId: toId,
  );
}
