import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/support/providers/system_connectivity_state.dart';

final systemConnectivityProvider =
    NotifierProvider<SystemConnectivityNotifier, SystemConnectivityState>(
        () => SystemConnectivityNotifier());

class SystemConnectivityNotifier extends Notifier<SystemConnectivityState> {
  @override
  SystemConnectivityState build() {
    final pollingData = ref.watch(pollingProvider).value?.data ?? {};
    final wanStatusResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getWANStatus, pollingData);
    final wanStatus = wanStatusResult == null
        ? null
        : RouterWANStatus.fromMap(wanStatusResult.output);
    final radioInfoResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getRadioInfo, pollingData);
    final radioInfo = radioInfoResult == null
        ? null
        : GetRadioInfo.fromMap(radioInfoResult.output);
    final guestRadioSettingsResult = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getGuestRadioSettings, pollingData);
    final guestRadioSettings = guestRadioSettingsResult == null
        ? null
        : GuestRadioSettings.fromMap(guestRadioSettingsResult.output);
    return SystemConnectivityState(
      wanConnection: wanStatus?.wanConnection,
      radioInfo: radioInfo ??
          const GetRadioInfo(isBandSteeringSupported: false, radios: []),
      guestRadioSettings: guestRadioSettings ??
          const GuestRadioSettings(
            isGuestNetworkACaptivePortal: false,
            isGuestNetworkEnabled: false,
            radios: [],
          ),
    );
  }
}
