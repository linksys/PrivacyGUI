sealed class PnpException {
  final String? message;

  PnpException({required this.message});
}

class ExceptionInvalidAdminPassword extends PnpException {
  ExceptionInvalidAdminPassword()
      : super(message: '[PnP] Invalid admin password');
}

class ExceptionNoInternetConnection extends PnpException {
  ExceptionNoInternetConnection()
      : super(message: '[PnP] No internet connection');
}

class ExceptionRouterUnconfigured extends PnpException {
  ExceptionRouterUnconfigured() : super(message: '[PnP] Router is unconfigured');
}

class ExceptionSavingChanges extends PnpException {
  ExceptionSavingChanges() : super(message: '[PnP] Saving changes error!');
}

class ExceptionNeedToReconnect extends PnpException {
  ExceptionNeedToReconnect()
      : super(message: '[PnP] Need to reconnect to the router');
}

class ExceptionGoAddNodes extends PnpException {
  ExceptionGoAddNodes()
      : super(message: '[PnP] Go add nodes');
}