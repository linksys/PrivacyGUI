import 'package:privacy_gui/constants/_constants.dart';

/// Resolves the URL **base** (scheme + host [+ port], plus proxy prefix when
/// proxying) to prepend to a Guardian API endpoint.
///
/// When the web app is served from the router itself (local build), the browser
/// origin is the router's LAN address. Client-side Remote Assistance requests
/// that hit the cloud host directly are blocked by CORS, so they are instead
/// routed through the router's reverse proxy ([kProxyPrefix]) to stay
/// same-origin. CA-side requests (support agent, cloud-hosted portal) must
/// always go direct to the cloud host.
///
/// Selection rule:
/// - CA-side → always direct cloud.
/// - Client-side → router proxy **iff** this is a local build AND the origin is
///   resolvable; otherwise direct cloud (safe fallback).
///
/// [originGetter] and [isLocal] are injected so the resolver is unit-testable
/// without a browser. The defaults ([_emptyOrigin] and [BuildConfig.isLocal])
/// deterministically resolve to the cloud base in the unit-test environment.
class CloudHostResolver {
  /// Returns the current browser origin (scheme+host+port), e.g.
  /// `https://192.168.1.1`. Empty when unavailable (non-web / not resolvable).
  final String Function() _originGetter;

  /// Whether this build is a local (router-hosted) build.
  final bool Function() _isLocal;

  CloudHostResolver({
    String Function()? originGetter,
    bool Function()? isLocal,
  })  : _originGetter = originGetter ?? _emptyOrigin,
        _isLocal = isLocal ?? BuildConfig.isLocal;

  static String _emptyOrigin() => '';

  /// Direct cloud base — always `https://<cloudBase>`.
  String get _cloudBase => 'https://${cloudEnvironmentConfig[kCloudBase]}';

  /// URL base to prepend to a Guardian endpoint.
  String resolve({required bool forCA}) {
    if (forCA || !_isLocal()) return _cloudBase;
    final origin = _originGetter();
    if (origin.isEmpty) return _cloudBase; // fallback: never break on no origin
    return '$origin$kProxyPrefix'; // e.g. https://192.168.1.1/cloud
  }
}
