import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_helpers.dart';

final wifiRadiosProvider = Provider<WifiRadiosState>((ref) {
  final pollingData = ref.watch(pollingProvider).value;

  List<RouterRadio> mainRadios = [];
  List<GuestRadioInfo> guestRadios = [];
  bool isGuestNetworkEnabled = false;

  final radioInfoOutput =
      getPollingOutput(pollingData, JNAPAction.getRadioInfo);
  if (radioInfoOutput != null) {
    final getRadioInfo = GetRadioInfo.fromMap(radioInfoOutput);
    mainRadios = getRadioInfo.radios;
  }

  final guestOutput =
      getPollingOutput(pollingData, JNAPAction.getGuestRadioSettings);
  if (guestOutput != null) {
    final guestSettings = GuestRadioSettings.fromMap(guestOutput);
    guestRadios = guestSettings.radios;
    isGuestNetworkEnabled = guestSettings.isGuestNetworkEnabled;
  }

  return WifiRadiosState(
    mainRadios: mainRadios,
    guestRadios: guestRadios,
    isGuestNetworkEnabled: isGuestNetworkEnabled,
  );
});

class WifiRadiosState extends Equatable {
  final List<RouterRadio> mainRadios;
  final List<GuestRadioInfo> guestRadios;
  final bool isGuestNetworkEnabled;

  const WifiRadiosState({
    this.mainRadios = const [],
    this.guestRadios = const [],
    this.isGuestNetworkEnabled = false,
  });

  @override
  List<Object?> get props => [mainRadios, guestRadios, isGuestNetworkEnabled];
}
