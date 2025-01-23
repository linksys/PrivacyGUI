import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_admin/providers/manual_firmware_update_state.dart';

final manualFirmwareUpdateProvider = NotifierProvider.autoDispose<
    ManualFirmwareUpdateNotifier, ManualFirmwareUpdateState>(
  () => ManualFirmwareUpdateNotifier(),
);

class ManualFirmwareUpdateNotifier extends AutoDisposeNotifier<ManualFirmwareUpdateState> {
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
}
