sealed class PnpException {
  final String? message;

  PnpException({required this.message});
}

class ExceptionFetchDeviceInfo extends PnpException {
  ExceptionFetchDeviceInfo() : super(message: 'Failed to fetch device info!');
}

class ExceptionInvalidAdminPassword extends PnpException {
  ExceptionInvalidAdminPassword() : super(message: 'Invalid admin password');
}

class ExceptionNoInternetConnection extends PnpException {
  ExceptionNoInternetConnection() : super(message: 'No internet connection');
}

class ExceptionRouterUnconfigured extends PnpException {
  ExceptionRouterUnconfigured() : super(message: 'The router is unconfigured');
}

class ExceptionSavingChanges extends PnpException {
  final Object? error;
  ExceptionSavingChanges(this.error) : super(message: 'Saving changes error!');
}

class ExceptionNeedToReconnect extends PnpException {
  ExceptionNeedToReconnect()
      : super(message: 'Need to reconnect to the router');
}

class ExceptionGoAddNodes extends PnpException {
  ExceptionGoAddNodes() : super(message: 'Go add nodes');
}

class ExceptionInterruptAndExit extends PnpException {
  final String route;
  ExceptionInterruptAndExit({required this.route})
      : super(message: 'Interrupted and exit to $route');
}

class ExceptionAutoMasterPollingFailed extends PnpException {
  ExceptionAutoMasterPollingFailed()
      : super(message: 'Auto Master polling failed');
}

/// Auto Master ("make Master") completed, so the admin password has been
/// rotated and no credential this session holds is usable any more.
///
/// Deliberately not an [ExceptionInterruptAndExit] carrying
/// `localLoginPassword`: that page is where a *finished* setup lands
/// (`userAcknowledgedAutoConfiguration == true`), and PnP has not finished. The
/// user has to re-enter the password through PnP's own prompt, and where to go
/// afterwards stays the router's decision.
class ExceptionAutoMasterRotatedPassword extends PnpException {
  ExceptionAutoMasterRotatedPassword()
      : super(message: 'Auto Master rotated the admin password');
}
