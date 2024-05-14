import 'package:privacy_gui/core/utils/storage.dart';
import 'package:share_plus/share_plus.dart';

Future<ShareResult?> exportFile(
    {required String content,
    required String fileName,
    String? text,
    String? subject}) async {
  final String tempPath = '${Storage.tempDirectory?.path}/$fileName.txt';
  await Storage.saveFile(Uri.parse(tempPath), content);
  final file = XFile(tempPath, name: '$fileName.txt', mimeType: 'text/plain');
  final result = await Share.shareXFiles(
    [file],
    text: text,
    subject: subject,
  );
  if (result.status == ShareResultStatus.success) {
    Storage.deleteFile(Uri.parse(tempPath));
  }
  return result;
}
