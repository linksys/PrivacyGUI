import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/storage.dart';
import 'package:privacy_gui/util/export_selector/export_selector.dart';
import 'package:privacy_gui/util/get_log_selector/get_log_selector.dart';
import 'package:share_plus/share_plus.dart';

class Utils {
  static Future exportLogFile(BuildContext context) async {
    final content = await getLog(context);
    final String shareLogFilename =
        'log-${DateFormat("yyyy-MM-dd_HH_mm_ss").format(DateTime.now())}.txt';

    await exportFile(
      content: content,
      fileName: shareLogFilename,
      text: 'Linksys Log',
      subject: 'Log file',
    ).then((result) {
      if (result?.status == ShareResultStatus.success && !kIsWeb) {
        Storage.deleteFile(Storage.logFileUri);
        Storage.createLoggerFile();
      }
      if (!context.mounted) return;
      showSnackBar(context, content: Text("Log exported - $shareLogFilename"));
    });
  }

  static String stringBase64Encode(String value) {
    return utf8.fuse(base64).encode(value);
  }

  static String stringBase64Decode(String base64String) {
    return utf8.fuse(base64).decode(base64String);
  }

  static String fullStringEncoded(String value) {
    final utf8Encoded =
        String.fromCharCodes(Uint8List.fromList(utf8.encode(value)));
    final b64 = base64Encode(utf8Encoded.codeUnits);
    final uriFull = Uri.encodeQueryComponent(b64);
    logger.d('u: $utf8Encoded, b: $b64, i: $uriFull');
    return uriFull;
  }

  static String fullStringDecoded(String encoded) {
    final uriBack = Uri.decodeComponent(encoded);
    final b64Back = String.fromCharCodes(base64Decode(uriBack));
    final utf8Back = utf8.decode(b64Back.codeUnits);
    logger.d('i: $uriBack, b: $b64Back, u: $utf8Back');
    return utf8Back;
  }

  static Future<bool> isUIVersionChanged() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final uiVersion = packageInfo.version;
    final fileUIVersion = await getVersion();
    return uiVersion.compareToVersion(fileUIVersion) < 0;
  }

  static bool isMobilePlatform() {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}
