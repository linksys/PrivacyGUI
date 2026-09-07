import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/framework/mode/credential_strategy.dart';

/// Local / cloud credential handling: the browser holds the router's own
/// session, so a 401 is transient and worth retrying.
class LocalCredentialStrategy implements CredentialStrategy {
  const LocalCredentialStrategy();

  @override
  AuthBehavior get authBehavior => AuthBehavior.local;
}
