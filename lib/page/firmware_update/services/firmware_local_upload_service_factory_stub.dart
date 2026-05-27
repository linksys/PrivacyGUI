import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_upload_strategy.dart';

/// Stub factory for non-Web platforms.
/// Returns a service without WebSocket support.
FirmwareLocalUploadService createFirmwareUploadService({
  required UspClient client,
  required UspMutationLock lock,
  Future<FirmwareUploadStrategy> Function()? wsStrategyFactory,
}) {
  return FirmwareLocalUploadService(client, lock);
}
