import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/ipv6_automatic_settings.dart';
import 'package:linksys_moab/model/router/wan_status.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/batch_extension.dart';
import 'package:linksys_moab/repository/router/router_extension.dart';
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
    ));
  }

  setIPv4ConnectionType(String connectionType) {
    emit(state.copyWith(ipv4ConnectionType: connectionType));
  }

  setIPv6ConnectionType(String connectionType) {
    emit(state.copyWith(ipv6ConnectionType: connectionType));
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    if (error is JnapError) {
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
