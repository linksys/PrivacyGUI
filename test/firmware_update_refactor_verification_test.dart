// test/firmware_update_refactor_verification_test.dart

import 'core/jnap/providers/firmware_update_provider_test.dart'
    as firmware_update_provider;
import 'core/jnap/services/firmware_update_service_test.dart'
    as firmware_update_service;
import 'page/instant_admin/providers/manual_firmware_update_provider_test.dart'
    as manual_firmware_update_provider;
import 'page/instant_admin/services/manual_firmware_update_service_test.dart'
    as manual_firmware_update_service;

void main() {
  firmware_update_service.main();
  firmware_update_provider.main();
  manual_firmware_update_service.main();
  manual_firmware_update_provider.main();
}
