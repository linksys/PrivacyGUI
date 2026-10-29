import 'package:privacy_gui/core/errors/service_error.dart';

/// A feature status that can carry the error of the last read.
///
/// The Preservable delegate is generic over its status, so this is how it sees
/// a failed read: `performFetch` turns one into a status carrying [error]
/// rather than throwing, because the initial load runs from `build()` with no
/// caller to catch it (#1274). After a save the delegate needs the error itself
/// — see `_PreservableDelegate.save()` (#1212, #1279).
///
/// Every status that has an `error` field implements this; the field already
/// matches, so implementing it adds nothing else.
abstract interface class HasServiceError {
  ServiceError? get error;
}
