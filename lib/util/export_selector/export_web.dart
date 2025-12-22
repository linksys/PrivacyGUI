import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart';
import 'package:share_plus/share_plus.dart';

Future<ShareResult?> exportFile(
    {required String content,
    required String fileName,
    String? text,
    String? subject}) async {
  Uint8List utf8Bytes = Uint8List.fromList(utf8.encode(content));
  final blob = Blob([utf8Bytes.toJS].toJS, BlobPropertyBag(type: 'text/plain'));
  final anchor = document.createElement('a') as HTMLAnchorElement;
  anchor.href = URL.createObjectURL(blob);
  anchor.target = 'blank';
  anchor.download = fileName;
  document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(anchor.href);
  return const ShareResult('', ShareResultStatus.success);
}

Future<ShareResult?> exportFileFromBytes(
    {required Uint8List utf8Bytes,
    required String fileName,
    String? text,
    String? subject}) async {
  final blob = Blob([utf8Bytes.toJS].toJS, BlobPropertyBag(type: 'text/plain'));
  final anchor = document.createElement('a') as HTMLAnchorElement;
  anchor.href = URL.createObjectURL(blob);
  anchor.target = 'blank';
  anchor.download = fileName;
  document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(anchor.href);
  return const ShareResult('', ShareResultStatus.success);
}
