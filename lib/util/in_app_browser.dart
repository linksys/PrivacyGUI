import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MoabInAppBrowser extends InAppBrowser {
  MoabInAppBrowser();
  MoabInAppBrowser.withDefaultOption() {
    // setSettings(settings: InAppBrowserClassSettings());
  }

  @override
  Future onBrowserCreated() async {
    print("Browser Created!");
  }

  @override
  Future onLoadStart(url) async {
    print("Started $url");
  }

  @override
  Future onLoadStop(url) async {
    print("Stopped $url");
  }

  @override
  void onLoadError(url, code, message) {
    print("Can't load $url.. Error: $message");
  }

  @override
  void onProgressChanged(progress) {
    print("Progress: $progress");
  }

  @override
  void onExit() {
    print("Browser closed!");
  }
}
