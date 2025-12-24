import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// A custom implementation of [InAppBrowser] tailored for the application.
///
/// This class extends the functionality of [InAppBrowser] to provide logging for
/// key browser events. It can be used to open web pages within the app and
/// monitor their state, such as when a page starts or stops loading, encounters
/// an error, or when the browser is closed.
class MoabInAppBrowser extends InAppBrowser {
  /// Creates a standard instance of the in-app browser.
  MoabInAppBrowser();

  /// Creates an instance of the in-app browser with default options.
  ///
  /// Note: The implementation for setting default options is currently commented out.
  MoabInAppBrowser.withDefaultOption() {
    // setSettings(settings: InAppBrowserClassSettings());
  }

  @override
  Future onBrowserCreated() async {}

  @override
  Future onLoadStart(url) async {}

  @override
  Future onLoadStop(url) async {}

  @override
  void onLoadError(url, code, message) {}

  @override
  void onProgressChanged(progress) {}

  @override
  void onExit() {}
}
