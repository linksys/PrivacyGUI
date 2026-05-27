import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_upload_strategy.dart';

/// Web factory that includes WebSocket strategy support.
FirmwareLocalUploadService createFirmwareUploadService({
  required UspClient client,
  required UspMutationLock lock,
  Future<FirmwareUploadStrategy> Function()? wsStrategyFactory,
}) {
  return FirmwareLocalUploadService(
    client,
    lock,
    wsStrategyFactory: wsStrategyFactory,
  );
}
