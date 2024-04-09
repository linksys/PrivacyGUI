sealed class PnpError {
  final String? message;

  PnpError({required this.message});
  
}

class ErrorInvalidAdminPassword extends PnpError {
  ErrorInvalidAdminPassword(): super(message: 'PnP Invalid admin password');
}

class ErrorCheckInternetConnection extends PnpError {
  ErrorCheckInternetConnection(): super(message: 'PnP No internet connection');

}