/// A sealed class for custom exceptions specific to the PnP flow.
/// Using custom exceptions allows for cleaner, more specific error handling.
sealed class PnpException {
  final String? message;

  PnpException({required this.message});
}

/// Thrown when fetching the device info from the router fails.
class ExceptionFetchDeviceInfo extends PnpException {
  ExceptionFetchDeviceInfo()
      : super(message: 'Failed to fetch device info!');
}

/// Thrown when the provided admin password is incorrect.
class ExceptionInvalidAdminPassword extends PnpException {
  ExceptionInvalidAdminPassword()
      : super(message: 'Invalid admin password');
}

/// Thrown when no active internet connection is detected.
class ExceptionNoInternetConnection extends PnpException {
  ExceptionNoInternetConnection()
      : super(message: 'No internet connection');
}

/// Thrown when the router is detected to be in a factory default (unconfigured) state.
/// This is often used to trigger a specific UI flow rather than as a hard error.
class ExceptionRouterUnconfigured extends PnpException {
  ExceptionRouterUnconfigured()
      : super(message: 'The router is unconfigured');
}

/// Thrown when an error occurs during the final save operation.
class ExceptionSavingChanges extends PnpException {
  final Object? error;
  ExceptionSavingChanges(this.error)
      : super(message: 'Saving changes error!');
}

/// Thrown when a network change (e.g., Wi-Fi settings updated) requires the user
/// to manually reconnect to the router's new network.
class ExceptionNeedToReconnect extends PnpException {
  ExceptionNeedToReconnect()
      : super(message: 'Need to reconnect to the router');
}

/// Thrown to indicate the flow should proceed to the "Add Nodes" screen.
class ExceptionGoAddNodes extends PnpException {
  ExceptionGoAddNodes() : super(message: 'Go add nodes');
}

/// A special exception used to interrupt the current flow and navigate to a different route.
class ExceptionInterruptAndExit extends PnpException {
  final String route;
  ExceptionInterruptAndExit({required this.route})
      : super(message: 'Interrupted and exit to $route');
}