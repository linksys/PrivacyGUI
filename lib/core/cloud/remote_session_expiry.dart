import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/cloud/model/error_response.dart';

/// Whether [error] is the cloud refusing a request because the remote
/// assistance session it was made through has ended.
///
/// Only a cloud [ErrorResponse] counts: a router result carrying the same
/// string is not the cloud ending the session.
bool isRemoteSessionExpired(Object? error) =>
    error is ErrorResponse && error.code == errorRemoteSessionExpired;
