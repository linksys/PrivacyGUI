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
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final ddnsProvider =
    NotifierProvider<DDNSNotifier, DDNSState>(() => DDNSNotifier());

final preservableDDNSProvider = Provider<PreservableContract>(
  (ref) => ref.watch(ddnsProvider.notifier),
);

class DDNSNotifier extends Notifier<DDNSState>
    with PreservableNotifierMixin<DDNSSettings, DDNSStatus, DDNSState> {
  @override
  DDNSState build() {
    const settings = DDNSSettings(provider: NoDDNSProvider());
    return DDNSState(
      settings: Preservable(original: settings, current: settings),
      status: const DDNSStatus(
        supportedProvider: [],
        status: '',
        ipAddress: '',
      ),
    );
  }

  @override
  Future<(DDNSSettings?, DDNSStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final builder = JNAPTransactionBuilder(commands: [
      const MapEntry(JNAPAction.getDDNSSettings, {}),
      const MapEntry(JNAPAction.getSupportedDDNSProviders, {}),
      const MapEntry(JNAPAction.getDDNSStatus, {}),
      const MapEntry(JNAPAction.getWANStatus, {}),
    ], auth: true);

    final results = await ref
        .read(routerRepositoryProvider)
        .transaction(
          builder,
          fetchRemote: forceRemote,
        )
        .then((value) => value.data.fold<Map<JNAPAction, JNAPSuccess>>({},
                (previousValue, element) {
              if (element.value is JNAPSuccess) {
                previousValue[element.key] = element.value as JNAPSuccess;
              }
              return previousValue;
            }));

    final wanStatusData = results[JNAPAction.getWANStatus];
    final wanStatus = wanStatusData != null
        ? RouterWANStatus.fromMap(wanStatusData.output)
        : null;

    final ddnsSettingsData = results[JNAPAction.getDDNSSettings];
    final ddnsSettings = ddnsSettingsData != null
        ? RouterDDNSSettings.fromMap(ddnsSettingsData.output)
        : null;

    final ddnsSupportedProvidersData =
        results[JNAPAction.getSupportedDDNSProviders];
    final ddnsSupportedProviders = ddnsSupportedProvidersData != null
        ? List<String>.from(
            ddnsSupportedProvidersData.output['supportedDDNSProviders'])
        : <String>[];

    final ddnsStatusData = results[JNAPAction.getDDNSStatus];
    final ddnsStatusString =
        ddnsStatusData != null ? ddnsStatusData.output['status'] : null;

    final settings = DDNSSettings(
      provider: DDNSProvider.reslove(ddnsSettings),
    );
    final status = DDNSStatus(
      supportedProvider: [noDNSProviderName, ...ddnsSupportedProviders],
      status: ddnsStatusString ?? '',
      ipAddress: wanStatus?.wanConnection?.ipAddress ?? '',
    );

    logger.d('[State]:[DDNS]: ${state.toJson()}');
    // state = state.copyWith(
    //     settings: Preservable(original: settings, current: settings),
    //     status: status);
    return (settings, status);
  }

  Future getStatus() {
    return ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getDDNSStatus, fetchRemote: true, auth: true)
        .then((value) => value.output['status'])
        .then((value) {
      state = state.copyWith(status: state.status.copyWith(status: value));
    });
  }

  @override
  Future<void> performSave() async {
    await ref.read(routerRepositoryProvider).send(
          JNAPAction.setDDNSSetting,
          data: RouterDDNSSettings(
            ddnsProvider: state.settings.current.provider.name,
            dynDNSSettings: state.settings.current.provider is DynDNSProvider
                ? state.settings.current.provider.settings
                : null,
            noIPSettings: state.settings.current.provider is NoIPDNSProvider
                ? state.settings.current.provider.settings
                : null,
            tzoSettings: state.settings.current.provider is TzoDNSProvider
                ? state.settings.current.provider.settings
                : null,
          ).toMap()
            ..removeWhere((key, value) => value == null),
          auth: true,
        );
  }

  void setProvider(String value) {
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current
                .copyWith(provider: DDNSProvider.create(value))));
  }

  void setProviderSettings(dynamic settings) {
    final provider = state.settings.current.provider.applySettings(settings);
    state = state.copyWith(
        settings: state.settings.copyWith(
            current: state.settings.current.copyWith(provider: provider)));
  }

  bool isDataValid() {
    return switch (state.settings.current.provider.settings) {
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
