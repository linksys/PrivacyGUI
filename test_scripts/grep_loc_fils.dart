import 'dart:io';

/// Organizes screenshot files into locale/device/theme/ folder structure.
///
/// Filename formats supported:
/// - New format with theme: `NAME-Device480w-en-glass-light.png`
/// - Old format without theme: `NAME-Device480w-en.png`
void main() {
  const rootSnapshotDirPath = './snapshots';
  final dir = Directory(rootSnapshotDirPath);
  if (!dir.existsSync()) {
    throw Exception('snapshots directory does not exist!!');
  }

  // New format: matches files with theme (e.g., NAME-Device480w-en-glass-light.png)
  // Groups: 1=device, 2=locale, 3=theme (style-brightness)
  const themeFilenameRegex =
      r'.*-(Device\d+w(?:-Tall)?)-([a-z]{2}(?:_[A-Z]{2})?)-([a-z]+-(?:light|dark)).png';
  final themeRegex = RegExp(themeFilenameRegex);

  // Old format: matches files without theme (e.g., NAME-Device480w-en.png)
  // Groups: 1=device, 2=locale
  const oldFilenameRegex = r'.*-(Device\d+w(?:-Tall)?)-([a-z]{2}(?:_[A-Z]{2})?).png';
  final oldRegex = RegExp(oldFilenameRegex);

  for (var file in dir.listSync()) {
    if (file is! File) {
      continue;
    }

    // Try new format with theme first
    var match = themeRegex.firstMatch(file.path);
    if (match != null) {
      final device = match.group(1);
      final locale = match.group(2);
      final theme = match.group(3);
      final targetDir =
          Directory('$rootSnapshotDirPath/$locale/$device/$theme');
      targetDir.createSync(recursive: true);
      file.rename('${targetDir.path}/${file.uri.pathSegments.last}');
      continue;
    }

    // Fall back to old format without theme
    match = oldRegex.firstMatch(file.path);
    if (match != null) {
      final device = match.group(1);
      final locale = match.group(2);
      final targetDir = Directory('$rootSnapshotDirPath/$locale/$device');
      targetDir.createSync(recursive: true);
      file.rename('${targetDir.path}/${file.uri.pathSegments.last}');
    }
  }
}
