import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/storage.dart';

Future<String> getLog(BuildContext context) async {
  final file = File.fromUri(Storage.logFileUri);
  final value = await file.readAsBytes();
  final appInfo = await getAppInfoLogs();
  final screenInfo = getScreenInfo(context);
  return '$appInfo\n$screenInfo\n${String.fromCharCodes(value)}';
}
