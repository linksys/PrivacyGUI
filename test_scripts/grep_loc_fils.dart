import 'dart:io';

void main() {
  const rootSnapshotDirPath = './snapshots';
  final dir = Directory(rootSnapshotDirPath);
  if (!dir.existsSync()) {
    throw Exception('snapshots dorectory does not exist!!');
  }
  const filenameRegex = r'.*-(Device\d+w)-(.+).png';
  final regex = RegExp(filenameRegex);
  for (var file in dir.listSync()) {
    if (file is! File) {
      continue;
    }
    final match = regex.firstMatch(file.path);
    if (match != null) {
      final device = match.group(1);
      final locale = match.group(2);
      final targetDir = Directory('$rootSnapshotDirPath/$locale/$device');
      targetDir.createSync(recursive: true);
      file.rename('${targetDir.path}/${file.uri.pathSegments.last}');
    }
  }
}
