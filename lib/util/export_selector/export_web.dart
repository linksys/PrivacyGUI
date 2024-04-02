import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<ShareResult?> exportFile(
    {required String content,
    required String fileName,
    String? text,
    String? subject}) async {
  List<int> utf8Bytes = utf8.encode(content);
  var blob = html.Blob([Uint8List.fromList(utf8Bytes), 'text/plain']);
  var anchor = html.AnchorElement(href: html.Url.createObjectUrlFromBlob(blob))
    ..target = 'blank'
    ..download = '$fileName.txt';
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  return null;
}
