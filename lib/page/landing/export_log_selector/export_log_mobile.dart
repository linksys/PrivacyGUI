import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/logger.dart';
import '../../../core/utils/storage.dart';
import '../../components/shortcuts/snack_bar.dart';

Future<void> exportLog(BuildContext context) async {
  final file = File.fromUri(Storage.logFileUri);
  final appInfo = await getAppInfoLogs();
  final screenInfo = getScreenInfo(context);
  final String shareLogFilename =
      'log-${DateFormat("yyyy-MM-dd_HH_mm_ss").format(DateTime.now())}.txt';
  final String shareLogPath =
      '${Storage.tempDirectory?.path}/$shareLogFilename';
  final value = await file.readAsBytes();

  String content = '$appInfo\n$screenInfo\n${String.fromCharCodes(value)}';
  await Storage.saveFile(Uri.parse(shareLogPath), content);

  Size size = MediaQuery.of(context).size;
  final result = await Share.shareFilesWithResult(
    [shareLogPath],
    text: 'Linksys Log',
    subject: 'Log file',
    sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 2),
  );
  if (result.status == ShareResultStatus.success) {
    Storage.deleteFile(Storage.logFileUri);
    Storage.deleteFile(Uri.parse(shareLogPath));
    Storage.createLoggerFile();
  }
  showSnackBar(context, content: Text("Share result: ${result.status}"));
}
