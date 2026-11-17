/// Steps the browser back one history entry, the way its Back button does,
/// and returns whether it did.
///
/// This is the non-web stub, selected by conditional export when
/// `dart.library.js_interop` is unavailable (the Dart VM, tests, mobile): there
/// is no browser history, so it does nothing and returns `false`, and the
/// caller navigates the app's own way instead.
bool browserHistoryBack() => false;
