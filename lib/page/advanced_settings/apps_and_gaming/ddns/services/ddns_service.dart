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
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/models/_models.dart';

/// Riverpod provider for DDNSService
final ddnsServiceProvider = Provider<DDNSService>((ref) {
  return DDNSService(ref.watch(routerRepositoryProvider));
});

/// Data result containing both settings and status
class DDNSDataResult {
  final DDNSSettingsUIModel settings;
  final DDNSStatusUIModel status;

  const DDNSDataResult({
    required this.settings,
    required this.status,
  });
}

/// Stateless service for DDNS operations
///
/// Encapsulates JNAP communication and model transformations,
/// separating business logic from state management (DDNSNotifier).
class DDNSService {
  /// Constructor injection of dependencies
  DDNSService(this._routerRepository);

  final RouterRepository _routerRepository;

  /// Fetches DDNS data from router and transforms to UI models
  ///
  /// Returns: [DDNSDataResult] containing settings and status
  Future<DDNSDataResult> fetchDDNSData({bool forceRemote = false}) async {
    final builder = JNAPTransactionBuilder(commands: [
      const MapEntry(JNAPAction.getDDNSSettings, {}),
      const MapEntry(JNAPAction.getSupportedDDNSProviders, {}),
      const MapEntry(JNAPAction.getDDNSStatus, {}),
      const MapEntry(JNAPAction.getWANStatus, {}),
    ], auth: true);

    final results = await _routerRepository
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

    // Parse JNAP responses
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

    // Transform to UI models
    final settings = DDNSSettingsUIModel(
      provider: _transformToUIProvider(ddnsSettings),
    );
    final status = DDNSStatusUIModel(
      supportedProviders: [noDNSProviderName, ...ddnsSupportedProviders],
      status: ddnsStatusString ?? '',
      ipAddress: wanStatus?.wanConnection?.ipAddress ?? '',
    );

    return DDNSDataResult(settings: settings, status: status);
  }

  /// Saves DDNS settings to router
  ///
  /// Parameters:
  ///   - settings: UI model to save
  Future<void> saveDDNSSettings(DDNSSettingsUIModel settings) async {
    final jnapModel = _transformToJNAPModel(settings.provider);

    await _routerRepository.send(
      JNAPAction.setDDNSSetting,
      data: jnapModel.toMap()..removeWhere((key, value) => value == null),
      auth: true,
    );
  }

  /// Refreshes DDNS status
  ///
  /// Returns: Current status string
  Future<String> refreshStatus() async {
    final result = await _routerRepository.send(
      JNAPAction.getDDNSStatus,
      fetchRemote: true,
      auth: true,
    );
    return result.output['status'] as String? ?? '';
  }

  /// Transforms JNAP RouterDDNSSettings to UI Provider model
  DDNSProviderUIModel _transformToUIProvider(RouterDDNSSettings? settings) {
    if (settings == null) {
      return const NoDDNSProviderUIModel();
    }

    if (settings.dynDNSSettings != null) {
      return _transformDynDNSToUI(settings.dynDNSSettings!);
    } else if (settings.noIPSettings != null) {
      return _transformNoIPToUI(settings.noIPSettings!);
    } else if (settings.tzoSettings != null) {
      return _transformTZOToUI(settings.tzoSettings!);
    }

    return const NoDDNSProviderUIModel();
  }

  /// Transforms DynDNSSettings JNAP model to UI model
  DynDNSProviderUIModel _transformDynDNSToUI(DynDNSSettings jnap) {
    return DynDNSProviderUIModel(
      username: jnap.username,
      password: jnap.password,
      hostName: jnap.hostName,
      isWildcardEnabled: jnap.isWildcardEnabled,
      mode: jnap.mode,
      isMailExchangeEnabled: jnap.isMailExchangeEnabled,
      mailExchangeSettings: jnap.mailExchangeSettings != null
          ? DynDNSMailExchangeUIModel(
              hostName: jnap.mailExchangeSettings!.hostName,
              isBackup: jnap.mailExchangeSettings!.isBackup,
            )
          : null,
    );
  }

  /// Transforms NoIPSettings JNAP model to UI model
  NoIPDNSProviderUIModel _transformNoIPToUI(NoIPSettings jnap) {
    return NoIPDNSProviderUIModel(
      username: jnap.username,
      password: jnap.password,
      hostName: jnap.hostName,
    );
  }

  /// Transforms TZOSettings JNAP model to UI model
  TzoDNSProviderUIModel _transformTZOToUI(TZOSettings jnap) {
    return TzoDNSProviderUIModel(
      username: jnap.username,
      password: jnap.password,
      hostName: jnap.hostName,
    );
  }

  /// Transforms UI provider model to JNAP RouterDDNSSettings
  RouterDDNSSettings _transformToJNAPModel(DDNSProviderUIModel uiProvider) {
    return switch (uiProvider) {
      DynDNSProviderUIModel ui => RouterDDNSSettings(
          ddnsProvider: ui.name,
          dynDNSSettings: DynDNSSettings(
            username: ui.username,
            password: ui.password,
            hostName: ui.hostName,
            isWildcardEnabled: ui.isWildcardEnabled,
            mode: ui.mode,
            isMailExchangeEnabled: ui.isMailExchangeEnabled,
            mailExchangeSettings: ui.mailExchangeSettings != null
                ? DynDNSMailExchangeSettings(
                    hostName: ui.mailExchangeSettings!.hostName,
                    isBackup: ui.mailExchangeSettings!.isBackup,
                  )
                : null,
          ),
        ),
      NoIPDNSProviderUIModel ui => RouterDDNSSettings(
          ddnsProvider: ui.name,
          noIPSettings: NoIPSettings(
            username: ui.username,
            password: ui.password,
            hostName: ui.hostName,
          ),
        ),
      TzoDNSProviderUIModel ui => RouterDDNSSettings(
          ddnsProvider: ui.name,
          tzoSettings: TZOSettings(
            username: ui.username,
            password: ui.password,
            hostName: ui.hostName,
          ),
        ),
      NoDDNSProviderUIModel() => const RouterDDNSSettings(
          ddnsProvider: noDNSProviderName,
        ),
    };
  }

  /// Validates DDNS provider settings
  ///
  /// Returns: true if settings are valid
  bool validateSettings(DDNSProviderUIModel provider) {
    return switch (provider) {
      DynDNSProviderUIModel p =>
        p.username.isNotEmpty && p.password.isNotEmpty && p.hostName.isNotEmpty,
      NoIPDNSProviderUIModel p =>
        p.username.isNotEmpty && p.password.isNotEmpty && p.hostName.isNotEmpty,
      TzoDNSProviderUIModel p =>
        p.username.isNotEmpty && p.password.isNotEmpty && p.hostName.isNotEmpty,
      NoDDNSProviderUIModel() => true,
    };
  }
}
