import 'package:privacy_gui/core/mode/app_mode.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/impl/remote_credential_strategy.dart';
import 'package:privacy_gui/core/mode/impl/remote_proximity_strategy.dart';
import 'package:privacy_gui/core/mode/impl/remote_session_strategy.dart';
import 'package:privacy_gui/core/mode/impl/remote_transport_strategy.dart';
import 'package:privacy_gui/framework/mode/credential_strategy.dart';
import 'package:privacy_gui/framework/mode/proximity_strategy.dart';
import 'package:privacy_gui/framework/mode/session_strategy.dart';
import 'package:privacy_gui/framework/mode/transport_strategy.dart';

/// The profile for a Remote Assistance build: a support agent, somewhere else,
/// reaching the router through the Guardian proxy on a session-scoped token.
///
/// This class is the object acceptance 3 of #1493 is about. One
/// `appModeProfileProvider.overrideWithValue(const RemoteModeProfile())` puts
/// transport, credentials, session ending and proximity all in remote at once —
/// which is what makes a remote-mode test possible without assigning
/// `BuildConfig.forceCommandType` and without a `tearDown` to restore it.
class RemoteModeProfile implements AppModeProfile {
  const RemoteModeProfile();

  @override
  AppMode get mode => AppMode.remote;

  // Statics for the same reason as LocalModeProfile's — see the comment there.
  static const _credential = RemoteCredentialStrategy();
  static const _transport = RemoteTransportStrategy(credential: _credential);
  static const _session = RemoteSessionStrategy();
  static const _proximity = RemoteProximityStrategy();

  @override
  TransportStrategy get transport => _transport;

  @override
  CredentialStrategy get credential => _credential;

  @override
  SessionStrategy get session => _session;

  @override
  ProximityStrategy get proximity => _proximity;
}
