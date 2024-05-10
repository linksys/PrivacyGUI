import 'package:flutter/widgets.dart';
import 'package:linksys_app/core/utils/logger.dart';

Future<String> getLog(BuildContext context) async {
  // final SharedPreferences sp = await SharedPreferences.getInstance();
  // return sp.getString(pWebLog) ?? '';
  return getFullLogs();
}
