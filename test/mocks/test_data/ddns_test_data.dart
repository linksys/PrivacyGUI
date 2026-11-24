import 'package:privacy_gui/page/ddns/models/ddns_server_ui_model.dart';
import 'package:privacy_gui/page/ddns/models/ddns_settings.dart';

/// Test data builder for the DDNS page (PrivacyGUI#641).
///
/// [response] builds the wire response `DynamicDns.fetch` reads. Its defaults
/// are the shipped rows as `Device.DynamicDNS.` read on an M60-US on
/// 2.0.4.26110110 (2026-11-11): `Server.1` DynDNS and `Server.2` No-IP, both
/// enabled; `Client.1` disabled with `Hostname.1` disabled; `Password` `""`;
/// `LastUpdate` the `0001-01-01T00:00:00Z` sentinel.
class DdnsTestData {
  static const clientPath = 'Device.DynamicDNS.Client.1.';
  static const hostnamePath = 'Device.DynamicDNS.Client.1.Hostname.1.';
  static const dynDnsPath = 'Device.DynamicDNS.Server.1';
  static const noIpPath = 'Device.DynamicDNS.Server.2';

  /// The WAN interface's path as `Device.IP.Interface.*.Alias` resolves it on
  /// the same bench.
  static const wanInterfacePath = 'Device.IP.Interface.2.';

  static const dynDns = DdnsServerUIModel(path: dynDnsPath, name: 'DynDNS');
  static const noIp = DdnsServerUIModel(path: noIpPath, name: 'No-IP');

  /// A `Device.DynamicDNS.` Get response with one client and one host name.
  ///
  /// [servers] is `(enable, name)` per `Server.{i}`, in instance order.
  static Map<String, dynamic> response({
    List<(bool, String)> servers = const [(true, 'DynDNS'), (true, 'No-IP')],
    bool clientEnable = false,
    String clientServer = '',
    String clientInterface = '',
    String username = '',
    String clientStatus = 'Disabled',
    String lastError = 'NO_ERROR',
    bool hostnameEnable = false,
    String hostname = '',
    String hostnameStatus = 'Disabled',
    String lastUpdate = '0001-01-01T00:00:00Z',
  }) {
    return {
      'Device.DynamicDNS.SupportedServices': 'dyndns.org,no-ip.com',
      for (var i = 0; i < servers.length; i++) ...{
        'Device.DynamicDNS.Server.${i + 1}.Enable': servers[i].$1,
        'Device.DynamicDNS.Server.${i + 1}.Name': servers[i].$2,
      },
      '${clientPath}Enable': clientEnable,
      '${clientPath}Server': clientServer,
      '${clientPath}Interface': clientInterface,
      '${clientPath}Username': username,
      '${clientPath}Password': '',
      '${clientPath}Status': clientStatus,
      '${clientPath}LastError': lastError,
      '${hostnamePath}Enable': hostnameEnable,
      '${hostnamePath}Name': hostname,
      '${hostnamePath}Status': hostnameStatus,
      '${hostnamePath}LastUpdate': lastUpdate,
    };
  }

  /// [response] for a client the router updates: No-IP chosen, an account
  /// and a host name stored, and [clientStatus] / [lastError] /
  /// [hostnameStatus] as the update left them.
  static Map<String, dynamic> configuredResponse({
    String clientStatus = 'Updated',
    String lastError = 'NO_ERROR',
    String hostnameStatus = 'Registered',
  }) =>
      response(
        clientEnable: true,
        clientServer: noIpPath,
        clientInterface: 'Device.IP.Interface.2',
        username: 'user@example.com',
        clientStatus: clientStatus,
        lastError: lastError,
        hostnameEnable: true,
        hostname: 'home.example.net',
        hostnameStatus: hostnameStatus,
        lastUpdate: '2026-11-11T08:00:00Z',
      );

  /// The page's working copy. Defaults to the shipped rows: both providers,
  /// "Disabled", nothing stored. [clientEnabled] follows [providerPath]
  /// unless given. [storedUsername] and [storedServerPath] are what the router
  /// holds, apart from what the page edits.
  static DdnsSettings settings({
    List<DdnsServerUIModel> providers = const [dynDns, noIp],
    bool? clientEnabled,
    String? providerPath,
    String username = '',
    String password = '',
    String hostname = '',
    String storedUsername = '',
    String storedServerPath = '',
  }) =>
      DdnsSettings(
        providers: providers,
        clientEnabled: clientEnabled ?? providerPath != null,
        providerPath: providerPath,
        username: username,
        password: password,
        hostname: hostname,
        storedUsername: storedUsername,
        storedServerPath: storedServerPath,
        clientPath: clientPath,
        hostnamePath: hostnamePath,
      );

  /// [settings] for the client [configuredResponse] reads: No-IP, an account
  /// and a host name stored, the password untouched. [providerPath],
  /// [username], [password] and [hostname] are the page's; the router keeps
  /// No-IP and `user@example.com`.
  static DdnsSettings configuredSettings({
    String? providerPath = noIpPath,
    String username = 'user@example.com',
    String password = '',
    String hostname = 'home.example.net',
  }) =>
      settings(
        clientEnabled: true,
        providerPath: providerPath,
        username: username,
        password: password,
        hostname: hostname,
        storedUsername: 'user@example.com',
        storedServerPath: noIpPath,
      );
}
