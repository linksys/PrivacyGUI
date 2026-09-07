import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/framework/mode/credential_strategy.dart';

/// Remote Assistance credential handling: Guardian minted a temporary access
/// token for one support session, so a 401 means that session is over and a
/// retry re-asks a question whose answer is now permanent.
class RemoteCredentialStrategy implements CredentialStrategy {
  const RemoteCredentialStrategy();

  @override
  AuthBehavior get authBehavior => AuthBehavior.remote;
}
