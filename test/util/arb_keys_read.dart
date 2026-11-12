import 'dart:io';

/// `l10n.key`, `_l10n.key` and `loc(context).key`.
final _keyRead =
    RegExp(r'(?:\b_?l10n|\bloc\(\s*\w+\s*\))\s*\.\s*([a-z][A-Za-z0-9]*)');

/// The ARB keys the Dart sources under [paths] read (#1312).
///
/// Each path is a file or a directory, read recursively. Read off the source so
/// a key a later change starts reading is covered without anyone listing it.
Set<String> arbKeysReadBy(List<String> paths) {
  final files = [
    for (final path in paths)
      if (FileSystemEntity.isDirectorySync(path))
        ...Directory(path)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
      else
        File(path),
  ];
  return {
    for (final file in files)
      for (final match in _keyRead.allMatches(file.readAsStringSync()))
        match.group(1)!,
  };
}
