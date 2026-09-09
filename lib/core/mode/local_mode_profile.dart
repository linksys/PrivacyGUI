import 'package:privacy_gui/core/mode/app_mode.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/impl/local_credential_strategy.dart';
import 'package:privacy_gui/core/mode/impl/local_proximity_strategy.dart';
import 'package:privacy_gui/core/mode/impl/local_session_strategy.dart';
import 'package:privacy_gui/core/mode/impl/local_transport_strategy.dart';
import 'package:privacy_gui/framework/mode/credential_strategy.dart';
import 'package:privacy_gui/framework/mode/proximity_strategy.dart';
import 'package:privacy_gui/framework/mode/session_strategy.dart';
import 'package:privacy_gui/framework/mode/transport_strategy.dart';

/// The profile for a build served by the router the user is standing next to.
///
/// Also the profile `AppMode.cloud` and `AppMode.demo` compose, via
/// [LocalModeProfile.aliasedAs] — see that constructor.
class LocalModeProfile implements AppModeProfile {
  @override
  final AppMode mode;

  const LocalModeProfile() : mode = AppMode.local;

  /// The same behaviour under a different [mode] label.
  ///
  /// `AppMode.cloud` (a `force=none` build) and `AppMode.demo` (the `lib/demo/`
  /// entry point) answer all four core causes exactly as `local` does today, so
  /// they must not get copies of these four strategies — a copy is the thing that
  /// drifts. But they must not *report* `AppMode.local` either: `mode` is what a
  /// diagnostic log and a future strategy read, and a profile that lied about its
  /// build would send a reader looking for a local bug in a cloud session.
  ///
  /// One implementation, three labels, and the day one of the three needs its own
  /// answer, the change is a new profile class plus one `switch` arm in
  /// `appModeProfileProvider` — not a hunt for the reads that assumed otherwise.
  ///
  /// The assert excludes `AppMode.remote`: aliasing remote onto the local
  /// strategies is the exact defect phase 1 of this epic fixed (a Guardian-proxied
  /// client behind local endpoint paths), so it is worth failing loudly in debug
  /// rather than trusting that nobody types it.
  const LocalModeProfile.aliasedAs(this.mode)
      : assert(
          mode != AppMode.remote,
          'Remote Assistance cannot alias the local profile: it would pair '
          'Guardian-proxied requests with on-router endpoint paths and no '
          'bearer token. Use RemoteModeProfile.',
        );

  // Held as statics so that `transport` can be a const expression and so that
  // every read returns the identical instance: `appModeProfileProvider` compares
  // its value with `==`, and a fresh strategy object per read would make the
  // provider notify — hence rebuild the bridge — on every unrelated invalidation.
  static const _credential = LocalCredentialStrategy();
  static const _transport = LocalTransportStrategy(credential: _credential);
  static const _session = LocalSessionStrategy();
  static const _proximity = LocalProximityStrategy();

  @override
  TransportStrategy get transport => _transport;

  @override
  CredentialStrategy get credential => _credential;

  @override
  SessionStrategy get session => _session;

  @override
  ProximityStrategy get proximity => _proximity;
}
