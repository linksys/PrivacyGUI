import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/wan_status.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/commands/_commands.dart';
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
    final wanStatusJson =
        JNAPTransactionSuccessWrap.getResult(JNAPAction.getWANStatus, result);
    final wanStatus = wanStatusJson == null
        ? null
        : RouterWANStatus.fromJson(wanStatusJson.output);
    final devicesJson =
        JNAPTransactionSuccessWrap.getResult(JNAPAction.getDevices, result);
    final devices = devicesJson == null
        ? null
        : List.from(devicesJson.output['devices'])
            .map((e) => RouterDevice.fromJson(e))
            .toList();
    final masterNode =
        devices?.firstWhereOrNull((element) => element.nodeType == 'Master');
    final slaveNodes =
        devices?.where((element) => element.nodeType == 'Slave').toList();
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
    // await _repository.connectToBroker();
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
    if (error is JNAPError) {
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
