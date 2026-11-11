import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/providers/wan_interface_path_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/tr181_path.dart';
import 'package:privacy_gui/generated/dynamic_dns.g.dart';
import 'package:privacy_gui/page/ddns/models/ddns_server_ui_model.dart';
import 'package:privacy_gui/page/ddns/models/ddns_settings.dart';
import 'package:privacy_gui/page/ddns/models/ddns_status.dart';

final uspDdnsServiceProvider = Provider<UspDdnsService>((ref) {
  final usp = ref.read(uspClientProvider);
  if (usp == null) {
    throw const ServiceNotInitializedError(detail: 'USP service not available');
  }
  return UspDdnsService(usp);
});

/// L2 Service of the DDNS page: reads `Device.DynamicDNS.` into the page's
/// working copy and writes it back in one Set.
///
/// The firmware ships the rows the page edits (`Server.1` DynDNS, `Server.2`
/// No-IP, a disabled `Client.1` with `Hostname.1`), so the page only Sets. The
/// GUI contract is §9 of the implementation doc on linksys/FWDEV#191.
class UspDdnsService {
  final UspClient _usp;

  UspDdnsService(this._usp);

  /// Reads the providers, the client and its host name.
  ///
  /// Throws [ResourceNotFoundError] when the router has no client row, or the
  /// client has no host name row: the page edits those rows and adds none.
  Future<(DdnsSettings, DdnsStatus)> fetch() async {
    try {
      final ddns = await DynamicDns.fetch(_usp);
      return (buildSettings(ddns), const DdnsStatus(isLoading: false));
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Writes [settings] in one Set with `allow_partial=false`.
  ///
  /// With a provider, the client gets `Enable`, `Server`, `Interface` (the WAN
  /// the router publishes), `Username` and the password if one was typed, and
  /// the host name gets `Enable` and `Name`. "Disabled" writes the client's
  /// `Enable` alone, so the router keeps the account and the host name for the
  /// next time a provider is chosen.
  ///
  /// The firmware's setters add no checks of their own, so a Set that passed
  /// the page's checks applies in full; a refusal from the provider shows in
  /// the status afterwards, not here.
  Future<void> save(DdnsSettings settings) async {
    try {
      final params = await saveParams(settings);
      final result = await _usp.set(params, allowPartial: false);
      _handleSetResult(result);
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Transform
  // ---------------------------------------------------------------------------

  /// The page's working copy from a read of `Device.DynamicDNS.`.
  ///
  /// Every table is read as a list, as the firmware allows a controller to add
  /// rows: the providers are all the enabled `Server` rows, and the page edits
  /// the first client and its first host name.
  DdnsSettings buildSettings(DynamicDns ddns) {
    if (ddns.clients.isEmpty) {
      throw const ResourceNotFoundError(
          detail: 'No Device.DynamicDNS.Client row');
    }
    final client = ddns.clients.first;
    if (client.hostnames.isEmpty) {
      throw ResourceNotFoundError(
          detail: 'No Hostname row under ${client.instancePath}');
    }
    final hostname = client.hostnames.first;

    final providers = [
      for (final server in ddns.servers)
        if (server.enable)
          DdnsServerUIModel(
            path: withoutTrailingDot(server.instancePath),
            name: server.name,
          ),
    ];

    // `Client.Server` reads back without the trailing dot whichever way it
    // was written. An enabled client on a provider the router no longer
    // offers, or on none, has no dropdown item, so it shows as "Disabled"
    // while `clientEnabled` stays true: choosing "Disabled" then writes
    // `Enable` false, and the status shows the client cannot update.
    final serverPath = withoutTrailingDot(client.server);
    final isOffered = providers.any((p) => p.path == serverPath);

    return DdnsSettings(
      providers: providers,
      clientEnabled: client.enable,
      providerPath: client.enable && isOffered ? serverPath : null,
      username: client.username,
      password: '',
      hostname: hostname.name,
      hasStoredAccount: client.username.isNotEmpty,
      clientPath: client.instancePath,
      hostnamePath: hostname.instancePath,
    );
  }

  /// The Set params of a save of [settings]. See [save].
  ///
  /// The WAN is resolved by its `Alias` only when a provider is chosen;
  /// "Disabled" does not touch `Interface`.
  Future<Map<String, dynamic>> saveParams(DdnsSettings settings) async {
    if (!settings.isEnabled) {
      return DynamicDns.updateClientsParams([
        DdnsClientUpdate(instancePath: settings.clientPath, enable: false),
      ]);
    }
    final wanPath = await resolveWanInterfacePath(_usp);
    return {
      ...DynamicDns.updateClientsParams([
        DdnsClientUpdate(
          instancePath: settings.clientPath,
          enable: true,
          server: settings.providerPath,
          wanInterface: withoutTrailingDot(wanPath),
          username: settings.username,
          // The stored password reads back as "", so an empty field means
          // "keep it". Sending "" would erase it.
          password: settings.password.isEmpty ? null : settings.password,
        ),
      ]),
      ...DynamicDns.updateHostnamesParams([
        DdnsHostnameUpdate(
          instancePath: settings.hostnamePath,
          enable: true,
          name: settings.hostname,
        ),
      ]),
    };
  }

  void _handleSetResult(Map<String, dynamic> result) {
    final parsed = UspResultParser.parseSetResult(result);
    switch (parsed) {
      case UspSuccess():
        break;
      case UspPartialSuccess(
          :final errorSummary,
          :final successes,
          :final failures
        ):
        throw UspPartialFailureError(
          summary: 'DDNS update partial failure: $errorSummary',
          successPaths: successes.map((s) => s.requestedPath).toList(),
          failures: failures,
        );
      case UspFailure(:final errorSummary, :final errors):
        throw UspCompleteFailureError(
          summary: 'DDNS update failed: $errorSummary',
          failures: errors,
        );
    }
  }
}
