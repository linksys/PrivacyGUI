import 'dart:io';

/// Deletes generated mock files under test/mocks/mockito_specs.
Future<void> main(List<String> args) async {
  final targetDir = Directory('test/mocks/mockito_specs');
  if (!await targetDir.exists()) {
    stderr.writeln('Directory not found: ${targetDir.path}');
    exitCode = 1;
    return;
  }

  final suffixes = ['.mocks.dart'];
  var deleted = 0;

  await for (final entity
      in targetDir.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final path = entity.path;
    final shouldDelete =
        suffixes.any((suffix) => path.toLowerCase().endsWith(suffix));
    if (!shouldDelete) continue;

    stdout.writeln('Deleting $path');
    await entity.delete();
    deleted++;
  }

  stdout.writeln('Deleted $deleted file(s).');
}
