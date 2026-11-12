import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/ddns/models/ddns_server_ui_model.dart';

/// The editable working copy of the DDNS page: the provider, the account and
/// the host name of the one client the page edits.
///
/// The router models several clients (`Client.{i}`) with several host names
/// each (`Client.{i}.Hostname.{i}`). This version edits the first client and
/// its first host name, the rows the firmware ships ([clientPath],
/// [hostnamePath]); the page only Sets them and never Adds one.
///
/// Plain [Equatable] rather than `DiagnosticLoggable`: that mixin derives
/// equality from the same map it prints, so it cannot both compare the real
/// [password] and print something else. [toString] leaves the account out of
/// what this object prints; the Set that carries it is masked by the logger.
class DdnsSettings extends Equatable {
  /// The providers the router offers, in instance order.
  final List<DdnsServerUIModel> providers;

  /// The client's `Enable`: as read, then as the page will write it — true
  /// with a provider, false for "Disabled".
  ///
  /// Kept apart from [providerPath] for the one case where they disagree: an
  /// enabled client on a provider the router no longer offers (or on none).
  /// The dropdown cannot show that provider, so it reads "Disabled", and
  /// choosing "Disabled" must still be a change — it writes `Enable` false.
  final bool clientEnabled;

  /// The chosen provider's path, or null when none is chosen.
  ///
  /// Read as the provider `Client.Server` names when the client is enabled
  /// and that provider is offered.
  final String? providerPath;

  final String username;

  /// The password typed on the page.
  ///
  /// The router never reads its password back (the leaf is secure and a Get
  /// returns `""`), so this starts empty. Left empty, it is not sent, and the
  /// router keeps the password it holds.
  final String password;

  final String hostname;

  /// The user name the router holds for this client, as read; never edited.
  final String storedUsername;

  /// The provider the router holds for this client (`Client.Server` without
  /// its trailing dot, `""` for none), as read, whether or not the client is
  /// enabled; never edited.
  final String storedServerPath;

  /// `Device.DynamicDNS.Client.{i}.`, the client the page edits.
  final String clientPath;

  /// `Device.DynamicDNS.Client.{i}.Hostname.{i}.`, its host name row.
  final String hostnamePath;

  const DdnsSettings({
    required this.providers,
    required this.clientEnabled,
    required this.providerPath,
    required this.username,
    required this.password,
    required this.hostname,
    required this.storedUsername,
    required this.storedServerPath,
    required this.clientPath,
    required this.hostnamePath,
  });

  /// Before the first read: no providers and nothing to edit.
  const DdnsSettings.empty()
      : providers = const [],
        clientEnabled = false,
        providerPath = null,
        username = '',
        password = '',
        hostname = '',
        storedUsername = '',
        storedServerPath = '',
        clientPath = '',
        hostnamePath = '';

  /// Whether a provider is chosen, so a save writes the account; false is
  /// "Disabled", which writes `Enable` false alone.
  bool get isEnabled => clientEnabled && providerPath != null;

  /// Whether the router holds an account for this client, read as a stored
  /// user name. The stored password cannot be read, so a stored user name is
  /// what says one was saved with it.
  bool get hasStoredAccount => storedUsername.isNotEmpty;

  /// Whether an empty [password] may keep the router's: the account on the
  /// page is the one the router holds — the same provider and the same user
  /// name — so the stored password still belongs to it. A new provider or a
  /// new user name needs its own password typed; otherwise the router would
  /// send the old account's password for the new one.
  bool get canKeepStoredPassword =>
      hasStoredAccount &&
      providerPath == storedServerPath &&
      username == storedUsername;

  DdnsSettings copyWith({
    bool? clientEnabled,
    String? providerPath,
    bool clearProviderPath = false,
    String? username,
    String? password,
    String? hostname,
  }) {
    return DdnsSettings(
      providers: providers,
      clientEnabled: clientEnabled ?? this.clientEnabled,
      providerPath:
          clearProviderPath ? null : (providerPath ?? this.providerPath),
      username: username ?? this.username,
      password: password ?? this.password,
      hostname: hostname ?? this.hostname,
      storedUsername: storedUsername,
      storedServerPath: storedServerPath,
      clientPath: clientPath,
      hostnamePath: hostnamePath,
    );
  }

  @override
  List<Object?> get props => [
        providers,
        clientEnabled,
        providerPath,
        username,
        password,
        hostname,
        storedUsername,
        storedServerPath,
        clientPath,
        hostnamePath,
      ];

  /// The user name and password are left out: the first is personal, the
  /// second a secret.
  @override
  String toString() => 'DdnsSettings('
      'clientEnabled: $clientEnabled, '
      'providerPath: $providerPath, '
      'providers: ${providers.map((p) => p.name).toList()}, '
      'username: ${username.isEmpty ? 'empty' : 'set'}, '
      'password: ${password.isEmpty ? 'untouched' : 'typed'}, '
      'hostname: $hostname, '
      'storedUsername: ${storedUsername.isEmpty ? 'empty' : 'set'}, '
      'storedServerPath: $storedServerPath, '
      'clientPath: $clientPath, '
      'hostnamePath: $hostnamePath)';
}
