import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/model/router/ipv6_automatic_settings.dart';
import 'package:linksys_moab/model/router/wan_status.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/commands/_commands.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';

import 'state.dart';

class InternetSettingsCubit extends Cubit<InternetSettingsState> {
  InternetSettingsCubit(RouterRepository repository)
      : _repository = repository,
        super(InternetSettingsState.init());

  final RouterRepository _repository;

  fetch() async {
    final results = await _repository.fetchInternetSettings();
    final wanSettings = results[JNAPAction.getWANSettings.actionValue]?.output;
    final ipv6Settings =
        results[JNAPAction.getIPv6Settings.actionValue]?.output;
    final wanStatus = results[JNAPAction.getWANStatus.actionValue] == null
        ? null
        : RouterWANStatus.fromJson(
            results[JNAPAction.getWANStatus.actionValue]!.output);
    final ipv6AutomaticSettings = ipv6Settings?['ipv6AutomaticSettings'] == null
        ? null
        : IPv6AutomaticSettings.fromJson(
            ipv6Settings!['ipv6AutomaticSettings']);
    final macAddressCloneSettings =
        results[JNAPAction.getMACAddressCloneSettings]?.output;
    emit(state.copyWith(
      ipv4ConnectionType: wanSettings?['wanType'] ?? '',
      ipv6ConnectionType: ipv6Settings?['wanType'] ?? '',
      supportedIPv4ConnectionType: wanStatus?.supportedWANTypes ?? [],
      supportedIPv6ConnectionType: wanStatus?.supportedIPv6WANTypes ?? [],
      supportedWANCombinations: wanStatus?.supportedWANCombinations ?? [],
      mtu: wanSettings?['mtu'] ?? 0,
      duid: ipv6Settings?['duid'] ?? '',
      isIPv6AutomaticEnabled:
          ipv6AutomaticSettings?.isIPv6AutomaticEnabled ?? false,
      macClone: macAddressCloneSettings?['isMACAddressCloneEnabled'] ?? false,
      macCloneAddress: macAddressCloneSettings?['macAddress'] ?? '',
    ));
  }

  setIPv4ConnectionType(String connectionType) {
    emit(state.copyWith(ipv4ConnectionType: connectionType));
  }

  setIPv6ConnectionType(String connectionType) {
    emit(state.copyWith(ipv6ConnectionType: connectionType));
  }

  setMtu(int mtu) {
    emit(state.copyWith(mtu: mtu));
  }

  setMacClone(bool isEnabled, String mac) {
    emit(state.copyWith(macClone: isEnabled, macCloneAddress: mac));
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    if (error is JNAPError) {
      // handle error
      emit(state.copyWith(error: error.error));
    }
  }

  @override
  void onChange(Change<InternetSettingsState> change) {
    super.onChange(change);
    if (!kReleaseMode) {
      logger.d(change);
    }
  }
}
