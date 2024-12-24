import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/models/ddns_settings_model.dart';
import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';
import 'package:privacy_gui/core/jnap/models/tzo_settings.dart';
import 'package:privacy_gui/core/jnap/models/wan_status.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';

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

  Future<DDNSState> fetch([bool force = false]) async {
    final builder = JNAPTransactionBuilder(commands: [
      const MapEntry(JNAPAction.getDDNSSettings, {}),
      const MapEntry(JNAPAction.getSupportedDDNSProviders, {}),
      const MapEntry(JNAPAction.getDDNSStatus, {}),
      const MapEntry(JNAPAction.getWANStatus, {}),
    ], auth: true);

    await ref
        .read(routerRepositoryProvider)
        .transaction(
          builder,
          fetchRemote: force,
        )
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
          ? RouterWANStatus.fromMap(wanStatusData.output)
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
        supportedProvider: [noDNSProviderName, ...ddnsSupportedProviders],
        status: ddnsStatus,
        provider: DDNSProvider.reslove(ddnsSettings),
        ipAddress: wanStatus?.wanConnection?.ipAddress,
      );
    });
    return state;
  }

  Future getStatus() {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getDDNSStatus, fetchRemote: true, auth: true)
        .then((value) => value.output['status'])
        .then((value) {
      state = state.copyWith(status: value);
    });
  }

  Future<DDNSState> save() {
    return ref
        .read(routerRepositoryProvider)
        .send(
          JNAPAction.setDDNSSetting,
          data: DDNSSettings(
            ddnsProvider: state.provider.name,
            dynDNSSettings: state.provider is DynDNSProvider
                ? state.provider.settings
                : null,
            noIPSettings: state.provider is NoIPDNSProvider
                ? state.provider.settings
                : null,
            tzoSettings: state.provider is TzoDNSProvider
                ? state.provider.settings
                : null,
          ).toMap()
            ..removeWhere((key, value) => value == null),
          auth: true,
        )
        .then((value) => fetch(true));
  }

  void setProvider(String value) {
    state = state.copyWith(provider: DDNSProvider.create(value));
  }

  void setProviderSettings(dynamic settings) {
    final provider = state.provider.applySettings(settings);
    state = state.copyWith(provider: provider);

  }

  bool isDataValid() {
    return switch (state.provider.settings) {
      final DynDNSSettings settings => settings.username.isNotEmpty &&
          settings.password.isNotEmpty &&
          settings.hostName.isNotEmpty,
          final NoIPSettings settings => settings.username.isNotEmpty &&
          settings.password.isNotEmpty &&
          settings.hostName.isNotEmpty,
          final TZOSettings settings => settings.username.isNotEmpty &&
          settings.password.isNotEmpty &&
          settings.hostName.isNotEmpty,
      _ => true,
    };
  }
}
