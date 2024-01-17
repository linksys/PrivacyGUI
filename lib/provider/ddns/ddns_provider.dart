import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/actions/jnap_transaction.dart';
import 'package:linksys_app/core/jnap/models/ddns_settings_model.dart';
import 'package:linksys_app/core/jnap/models/dyn_dns_settings.dart';
import 'package:linksys_app/core/jnap/models/no_ip_settings.dart';
import 'package:linksys_app/core/jnap/models/tzo_settings.dart';
import 'package:linksys_app/core/jnap/models/wan_status.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/provider/ddns/ddns_state.dart';

final ddnsProvider =
    NotifierProvider<DDNSNotifier, DDNSState>(() => DDNSNotifier());

class DDNSNotifier extends Notifier<DDNSState> {
  @override
  DDNSState build() {
    return DDNSState(
      supportedProvider: const [],
      provider: NoDDNSProvider(),
      status: '',
      ipAddress: '',
    );
  }

  Future fetch({bool force = false}) async {
    final builder = JNAPTransactionBuilder(commands: [
      const MapEntry(JNAPAction.getDDNSSettings, {}),
      const MapEntry(JNAPAction.getSupportedDDNSProviders, {}),
      const MapEntry(JNAPAction.getDDNSStatus, {}),
      const MapEntry(JNAPAction.getWANStatus, {}),
    ]);

    await ref
        .read(routerRepositoryProvider)
        .transaction(builder, fetchRemote: force)
        .then((value) => value.data.fold<Map<JNAPAction, JNAPSuccess>>({},
                (previousValue, element) {
              if (element.value is JNAPSuccess) {
                previousValue[element.key] = element.value as JNAPSuccess;
              }
              return previousValue;
            }))
        .then((results) {
      final wanStatusData = results[JNAPAction.getWANStatus];
      final wanStatus = wanStatusData != null
          ? RouterWANStatus.fromJson(wanStatusData.output)
          : null;

      final ddnsSettingsData = results[JNAPAction.getDDNSSettings];
      final ddnsSettings = ddnsSettingsData != null
          ? DDNSSettings.fromMap(ddnsSettingsData.output)
          : null;

      final ddnsSupportedProvidersData =
          results[JNAPAction.getSupportedDDNSProviders];
      final ddnsSupportedProviders = ddnsSupportedProvidersData != null
          ? List<String>.from(
              ddnsSupportedProvidersData.output['supportedDDNSProviders'])
          : <String>[];

      final ddnsStatusData = results[JNAPAction.getDDNSStatus];
      final ddnsStatus =
          ddnsStatusData != null ? ddnsStatusData.output['status'] : null;

      state = state.copyWith(
        supportedProvider: ['disabled', ...ddnsSupportedProviders],
        status: ddnsStatus,
        provider: DDNSProvider.reslove(ddnsSettings),
        ipAddress: wanStatus?.wanConnection?.ipAddress,
      );
    });
  }

  Future getStatus() {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getDDNSStatus, fetchRemote: true)
        .then((value) => value.output['status'])
        .then((value) {
      state = state.copyWith(status: value);
    });
  }

  Future save(
    String selected, {
    DynDNSSettings? dynDNSSettings,
    NoIPSettings? noIPSettings,
    TZOSettings? tzoSettings,
  }) {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.setDDNSSetting,
            data: DDNSSettings(
              ddnsProvider: selected,
              dynDNSSettings: dynDNSSettings,
              noIPSettings: noIPSettings,
              tzoSettings: tzoSettings,
            ).toMap()
              ..removeWhere((key, value) => value == null))
        .then((value) => null);
  }
}
