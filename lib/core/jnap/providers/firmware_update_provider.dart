// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/command/base_command.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_settings.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:linksys_app/core/jnap/providers/firmware_update_state.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';

final firmwareUpdateProvider =
    NotifierProvider<FirmwareUpdateNotifier, FirmwareUpdateState>(
        () => FirmwareUpdateNotifier());

class FirmwareUpdateNotifier extends Notifier<FirmwareUpdateState> {
  @override
  FirmwareUpdateState build() {
    final fwUpdateSettingsRaw = ref.watch(pollingProvider.select<JNAPResult?>(
        (value) => value.value?.data[JNAPAction.getFirmwareUpdateSettings]));
    final fwUpdateCheckRaw = ref.watch(pollingProvider.select(
        (value) => value.value?.data[JNAPAction.getFirmwareUpdateStatus]));
    final nodesFwUpdateCheckRaw = ref.watch(pollingProvider.select(
        (value) => value.value?.data[JNAPAction.getNodesFirmwareUpdateStatus]));

    FirmwareUpdateSettings? fwUpdateSettings;
    if (fwUpdateSettingsRaw is JNAPSuccess) {
      fwUpdateSettings =
          FirmwareUpdateSettings.fromMap(fwUpdateSettingsRaw.output);
    }

    FirmwareUpdateStatus? fwUpdateStatus;
    if (fwUpdateCheckRaw is JNAPSuccess) {
      fwUpdateStatus = FirmwareUpdateStatus.fromMap(fwUpdateCheckRaw.output);
    }

    List<NodesFirmwareUpdateStatus>? nodesFwUpdateStatus;
    if (nodesFwUpdateCheckRaw is JNAPSuccess) {
      nodesFwUpdateStatus =
          List.from(nodesFwUpdateCheckRaw.output['firmwareUpdateStatus'])
              .map((e) => NodesFirmwareUpdateStatus.fromMap(e))
              .toList();
    }
    return FirmwareUpdateState(
      settings: fwUpdateSettings ??
          FirmwareUpdateSettings(
              updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto,
              autoUpdateWindow: FirmwareAutoUpdateWindow.simple()),
      status: fwUpdateStatus ??
          const FirmwareUpdateStatus(lastSuccessfulCheckTime: '0'),
      nodesStatus: nodesFwUpdateStatus,
    );
  }

  Future setFirmwareUpdatePolicy(String policy) {
    final repo = ref.read(routerRepositoryProvider);
    final newSettings = state.settings.copyWith(updatePolicy: policy);
    return repo
        .send(JNAPAction.setFirmwareUpdateSettings,
            auth: true,
            cacheLevel: CacheLevel.noCache,
            data: newSettings.toMap())
        .then((_) async {
      await repo.send(JNAPAction.getFirmwareUpdateSettings,
          auth: true, fetchRemote: true);
    }).then((_) {
      state = state.copyWith(settings: newSettings);
    });
  }
}
