import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:linksys_app/constants/_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> exportLog(BuildContext context) async {
  final SharedPreferences sp = await SharedPreferences.getInstance();
  final String content = sp.getString(pWebLog) ?? '';
  List<int> utf8Bytes = utf8.encode(content);
  var blob = html.Blob([Uint8List.fromList(utf8Bytes), 'text/plain']);
  var anchor = html.AnchorElement(href: html.Url.createObjectUrlFromBlob(blob))
    ..target = 'blank'
    ..download = 'web-log.txt';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
}
