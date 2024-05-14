import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:privacy_gui/util/in_app_browser.dart';

void openUrl(String url) => MoabInAppBrowser.withDefaultOption()
    .openUrlRequest(urlRequest: URLRequest(url: Uri.parse(url)));
