import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/models/wan_status.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/ip_details/ip_details_state.dart';

final ipDetailsProvider = NotifierProvider<IpDetailsNotifier, IpDetailsState>(
    () => IpDetailsNotifier());

class IpDetailsNotifier extends Notifier<IpDetailsState> {
  @override
  IpDetailsState build() => IpDetailsState.init();

  fetch() async {
    final repo = ref.read(routerRepositoryProvider);
    final results = await repo.fetchIpDetails();
    final wanStatusJson =
        JNAPTransactionSuccessWrap.getResult(JNAPAction.getWANStatus, Map.fromEntries(results));
    final wanStatus = wanStatusJson == null
        ? null
        : RouterWANStatus.fromJson(wanStatusJson.output);
    final devicesJson =
        JNAPTransactionSuccessWrap.getResult(JNAPAction.getDevices, Map.fromEntries(results));
    final devices = devicesJson == null
        ? null
        : List.from(devicesJson.output['devices'])
            .map((e) => RawDevice.fromMap(e))
            .toList();
    final masterNode =
        devices?.firstWhereOrNull((element) => element.nodeType == 'Master');
    final slaveNodes =
        devices?.where((element) => element.nodeType == 'Slave').toList();
    state = state.copyWith(
      ipv4WANType: wanStatus?.wanConnection?.wanType ?? '',
      ipv4WANAddress: wanStatus?.wanConnection?.ipAddress ?? '',
      ipv6WANType: wanStatus?.wanIPv6Connection?.wanType ?? '',
      ipv6WANAddress:
          wanStatus?.wanIPv6Connection?.networkInfo?.ipAddress ?? '',
      masterNode: masterNode,
      slaveNodes: slaveNodes,
    );
  }

  Future renewIp(bool isIPv6) async {
    final repo = ref.read(routerRepositoryProvider);
    if (isIPv6) {
      state = state.copyWith(ipv6Renewing: true);
      await repo.send(
        JNAPAction.renewDHCPIPv6WANLease,
        auth: true,
      );
    } else {
      state = state.copyWith(ipv4Renewing: true);
      await repo.send(
        JNAPAction.renewDHCPWANLease,
        auth: true,
      );
    }
    // TODO #SIDEEFFECT WANInterruption
    await Future.delayed(const Duration(seconds: 20));
    // await repo.connectToBroker();
    await fetch();
    if (isIPv6) {
      state = state.copyWith(ipv6Renewing: false);
    } else {
      state = state.copyWith(ipv4Renewing: false);
    }
  }
}
