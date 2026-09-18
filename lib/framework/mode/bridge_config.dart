import 'package:privacy_gui/core/usp/services/bridge_endpoints.dart';
// AuthBehavior is re-exported by usp_bridge_client_base.dart, so this single
// import carries both it and UspBridgeClient. Importing its real home
// (sse_operation_strategy.dart) as well trips `unnecessary_import`.
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';

/// Everything a [UspBridgeClient] needs, as one value a test can look at.
///
/// This type exists because of a measured hole: the VM stub
/// `usp_bridge_client_base.dart` accepts all five of these arguments and
/// **ignores every one**, exposing no getter for any of them. So the pre-#1474
/// `if (GlobalConfig.remote.isActive)` that chose them — 5 differing arguments,
/// the difference between talking to the router and talking to Guardian — was
/// unobservable from a unit test by construction. Naming the arguments moves the
/// decision one step earlier, to a place a test can read.
///
/// The 5 differences, all of them wrong-in-a-local-build if the mode is
/// mis-decided: [endpoints] (on-router paths vs session-scoped Guardian paths),
/// [baseUrl] (same-origin vs the Guardian host), [authToken] (none vs a bearer),
/// [clientTypeId] (none vs the agent's), [authBehavior] (retry a 401 vs treat it
/// as the end of the support session).
class BridgeConfig {
  /// Which endpoint table is in force. `BridgeEndpoints.local` is a `const`
  /// singleton; the remote table is session-scoped, so it is a function of the
  /// session id and a fresh object each time.
  final BridgeEndpoints endpoints;

  /// Origin to prefix every bridge request with, or `null` for same-origin.
  ///
  /// Null is the local answer and it is not "unset": the app is served *by* the
  /// router, so the correct base is the page's own origin and
  /// `usp_bridge_client_web.dart` interpolates an empty prefix at its 8 request
  /// sites.
  final String? baseUrl;

  /// Guardian's temporary access token, or `null` locally.
  final String? authToken;

  /// Guardian's client-type discriminator, or `null` locally.
  final String? clientTypeId;

  /// What an auth failure means on this transport. Supplied by
  /// `CredentialStrategy`, not by the transport itself — the two causes are
  /// independent, and this field is where they meet.
  final AuthBehavior authBehavior;

  const BridgeConfig({
    required this.endpoints,
    this.baseUrl,
    this.authToken,
    this.clientTypeId,
    required this.authBehavior,
  });

  /// No `operator ==`, deliberately.
  ///
  /// It is tempting — this is a value object — but adding one would change
  /// behaviour, and #1493 is a refactor. `uspBridgeClientProvider` watches this
  /// config, and `RemoteAssistanceConfig` has no `==` of its own, so today an
  /// equal-but-new session config rebuilds the bridge. With `==` here those
  /// rebuilds would coalesce. That is very likely an improvement, and it belongs
  /// in the same change that gives `RemoteAssistanceConfig` an `==` — where the
  /// rebuild count can actually be measured, rather than arriving as a side
  /// effect of a file move.
  ///
  /// Tests therefore assert on fields, which is what they want to read anyway:
  /// "the endpoints are the session-scoped ones" beats "the config equals this
  /// other config I also had to build".
  @override
  String toString() => 'BridgeConfig(baseUrl: $baseUrl, '
      'endpoints: ${endpoints.subscription}, '
      'authToken: ${authToken == null ? 'none' : '<redacted>'}, '
      'clientTypeId: $clientTypeId, authBehavior: $authBehavior)';
}
