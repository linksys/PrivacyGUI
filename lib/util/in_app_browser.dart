import 'package:flutter_inappwebview/flutter_inappwebview.dart';

final inAppBrowserOptions = InAppBrowserClassOptions(
    crossPlatform: InAppBrowserOptions(hideUrlBar: true),
    inAppWebViewGroupOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(javaScriptEnabled: true)));

class MoabInAppBrowser extends InAppBrowser {

  MoabInAppBrowser();
  MoabInAppBrowser.withDefaultOption() {
    setOptions(options: inAppBrowserOptions);
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
