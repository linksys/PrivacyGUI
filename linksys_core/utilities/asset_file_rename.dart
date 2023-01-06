import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    throw Exception('No Arguments Input');
  }
  final path = args[0];
  final dir = Directory(path);
  if (!dir.existsSync()) {
    throw Exception('path is not Directory');
  }
  RegExp regex = RegExp(r"(\w+=(\w+))");
  dir.listSync().forEach((element) {
    final fileName = Uri.parse(element.path).pathSegments.last;
    final filePath = element.path.replaceAll(fileName, '');
    final ext = fileName.split('.').last;
    final newName = regex
        .allMatches(fileName)
        .map((e) => e.group(2)?.toLowerCase())
        .toList()
        .join('_');
    final newFileName = '$newName.$ext';

    element.renameSync('$filePath$newFileName');
  });
}
