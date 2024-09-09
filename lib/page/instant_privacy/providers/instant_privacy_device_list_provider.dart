import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_device_list_state.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

final instantPrivacyDeviceListProvider = NotifierProvider<
    InstantPrivacyDeviceListNotifier,
    InstantPrivacyDeviceListState>(() => InstantPrivacyDeviceListNotifier());

class InstantPrivacyDeviceListNotifier
    extends Notifier<InstantPrivacyDeviceListState> {
  @override
  InstantPrivacyDeviceListState build() {
    final deviceListState = ref.watch(deviceListProvider);
    final macFilteringState = ref.watch(instantPrivacyProvider);
    return createState(deviceListState, macFilteringState);
  }

  InstantPrivacyDeviceListState createState(
      DeviceListState deviceListState, InstantPrivacyState macFilteringState) {
    return InstantPrivacyDeviceListState(
      isEnable: macFilteringState.mode == MacFilterMode.allow,
      macAddresses: macFilteringState.macAddresses,
      deviceList: deviceListState.devices,
    );
  }
}
