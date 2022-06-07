import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Storage {

  static Directory? _tempDirectory;
  static Directory? get tempDirectory => _tempDirectory;
  static Directory? _docDirectory;
  static Directory? get docDirectory => _docDirectory;
  static const String loggerFilename = 'logger.txt';
  static Uri get logFileUri => Uri.parse('${_tempDirectory?.path}/$loggerFilename');

  static init() async {
    _tempDirectory = (await getTemporaryDirectory());
    _docDirectory = await getApplicationDocumentsDirectory();
    print('temp directory: $_tempDirectory, doc directory: $_docDirectory');
    final logFile = File.fromUri(logFileUri);
    if (!logFile.existsSync()) {
      logFile.createSync();
    }
  }

  static deleteFile(Uri fileUri) async {
    File.fromUri(fileUri).delete();
  }
}