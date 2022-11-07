import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/wan_status.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/network/mqtt/model/command/jnap/base.dart';
import 'package:linksys_moab/repository/router/batch_extension.dart';
import 'package:linksys_moab/repository/router/router_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';

import 'state.dart';

class IpDetailsCubit extends Cubit<IpDetailsState> {
  IpDetailsCubit(RouterRepository repository)
      : _repository = repository,
        super(IpDetailsState.init());

  final RouterRepository _repository;

  fetch() async {
    final result = await _repository.fetchIpDetails();
    final wanStatus = result[JNAPAction.getWANStatus.actionValue] == null
        ? null
        : RouterWANStatus.fromJson(
            result[JNAPAction.getWANStatus.actionValue]!.output);
    final devices = result[JNAPAction.getDevices.actionValue] == null
        ? null
        : List.from(result[JNAPAction.getDevices.actionValue]!.output['devices'])
            .map((e) => RouterDevice.fromJson(e))
            .toList();
    final masterNode = devices?.firstWhereOrNull((element) => element.nodeType == 'Master');
    final slaveNodes = devices?.where((element) => element.nodeType == 'Slave').toList();
    emit(state.copyWith(
      ipv4WANType: wanStatus?.wanConnection?.wanType ?? '',
      ipv4WANAddress: wanStatus?.wanConnection?.ipAddress ?? '',
      ipv6WANType: wanStatus?.wanIPv6Connection?.wanType ?? '',
      ipv6WANAddress:
          wanStatus?.wanIPv6Connection?.networkInfo?.ipAddress ?? '',
      masterNode: masterNode,
      slaveNodes: slaveNodes,
    ));
  }

  Future renewIp(bool isIPv6) async {
    if (isIPv6) {
      emit(state.copyWith(ipv6Renewing: true));
      await _repository.renewDHCPIPv6WANLease();
    } else {
      emit(state.copyWith(ipv4Renewing: true));
      await _repository.renewDHCPWANLease();
    }
    // TODO #SIDEEFFECT WANInterruption
    await Future.delayed(Duration(seconds: 20));
    await fetch();
    if (isIPv6) {
      emit(state.copyWith(ipv6Renewing: false));
    } else {
      emit(state.copyWith(ipv4Renewing: false));
    }
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
  void onChange(Change<IpDetailsState> change) {
    super.onChange(change);
    if (!kReleaseMode) {
      logger.d(change);
    }
  }
}
