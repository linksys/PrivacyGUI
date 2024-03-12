import 'package:flutter/widgets.dart';
import 'package:linksys_app/constants/pref_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getLog(BuildContext context) async {
  final SharedPreferences sp = await SharedPreferences.getInstance();
  return sp.getString(pWebLog) ?? '';
}
