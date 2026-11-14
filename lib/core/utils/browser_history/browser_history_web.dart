import 'package:web/web.dart' as web;

/// Steps the browser back one history entry, the way its Back button does,
/// and returns whether it did — always, on web.
///
/// Why an app needs it: on web every navigation the app makes — a `go`, and a
/// `pop` too — is recorded as a **new** browser history entry (go_router 17
/// reports it with `replace: false`). So an in-app "Back" that navigates to the
/// previous page adds an entry instead of returning to one, and the browser's
/// own Back afterwards undoes the in-app Back. Calling this instead makes the
/// two the same action, so router redirects and `onExit` guards see one kind
/// of Back.
///
/// Only for a page whose previous history entry is known to be where Back
/// should go; the browser does not say what that entry is.
bool browserHistoryBack() {
  web.window.history.back();
  return true;
}
