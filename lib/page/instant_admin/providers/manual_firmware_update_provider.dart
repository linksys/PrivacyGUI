import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/data/providers/side_effect_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_state.dart';
import 'package:privacy_gui/page/instant_admin/services/manual_firmware_update_service.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/core/utils/ip_getter/get_local_ip.dart'
    if (dart.library.io) 'package:privacy_gui/core/utils/ip_getter/mobile_get_local_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/utils/ip_getter/web_get_local_ip.dart';

final manualFirmwareUpdateProvider = NotifierProvider.autoDispose<
    ManualFirmwareUpdateNotifier, ManualFirmwareUpdateState>(
  () => ManualFirmwareUpdateNotifier(),
);

class ManualFirmwareUpdateNotifier
    extends AutoDisposeNotifier<ManualFirmwareUpdateState> {
  @override
  ManualFirmwareUpdateState build() {
    return ManualFirmwareUpdateState();
  }

  void setFile(String name, Uint8List bytes) {
    state = state.copyWith(file: () => FileInfo(name: name, bytes: bytes));
  }

  void removeFile() {
    state = state.copyWith(file: () => null);
  }

  void setStatus(ManualUpdateStatus? status) {
    state = state.copyWith(status: () => status);
  }

  void reset() {
    state.status?.stop();
    state = ManualFirmwareUpdateState();
  }

  Future<bool> manualFirmwareUpdate(String filename, List<int> bytes) async {
    final localPassword = ref.read(authProvider).value?.localPassword;
    final localIp = getLocalIp(ref);
    ref.read(pollingProvider.notifier).stopPolling();
    return ref
        .read(manualFirmwareUpdateServiceProvider)
        .manualFirmwareUpdate(filename, bytes, localPassword, localIp);
  }

  Future waitForRouterBackOnline() {
    return ref
        .read(sideEffectProvider.notifier)
        .manualDeviceRestart()
        .whenComplete(() {
      ref.read(pollingProvider.notifier).startPolling();
    });
  }
}
