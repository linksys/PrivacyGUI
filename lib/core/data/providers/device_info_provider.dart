import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/soft_sku_settings.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_helpers.dart';

final deviceInfoProvider = Provider<DeviceInfoState>((ref) {
  final pollingData = ref.watch(pollingProvider).value;

  NodeDeviceInfo? deviceInfo;
  String? skuModelNumber;

  final deviceInfoOutput =
      getPollingOutput(pollingData, JNAPAction.getDeviceInfo);
  if (deviceInfoOutput != null) {
    deviceInfo = NodeDeviceInfo.fromJson(deviceInfoOutput);
  }

  final skuOutput =
      getPollingOutput(pollingData, JNAPAction.getSoftSKUSettings);
  if (skuOutput != null) {
    final settings = SoftSKUSettings.fromMap(skuOutput);
    skuModelNumber = settings.modelNumber;
  }

  return DeviceInfoState(
    deviceInfo: deviceInfo,
    skuModelNumber: skuModelNumber,
  );
});

class DeviceInfoState extends Equatable {
  final NodeDeviceInfo? deviceInfo;
  final String? skuModelNumber;

  const DeviceInfoState({
    this.deviceInfo,
    this.skuModelNumber,
  });

  @override
  List<Object?> get props => [deviceInfo, skuModelNumber];
}
