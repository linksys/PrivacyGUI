import 'dart:io';
import 'dart:typed_data';
import 'package:moab_poc/network/http/model/cloud_config.dart';
import 'package:moab_poc/util/logger.dart';
import 'package:path_provider/path_provider.dart';

class Storage {

  static Directory? _tempDirectory;
  static Directory? get tempDirectory => _tempDirectory;
  static Directory? _docDirectory;
  static Directory? get docDirectory => _docDirectory;
  static const String loggerFilename = 'logger.txt';
  static final String appPublicKeyFilename = '${cloudEnvTarget.name}_key.pem';
  static final String appPrivateKeyFilename = '${cloudEnvTarget.name}_key.key';

  static Uri get logFileUri => Uri.parse('${_tempDirectory?.path}/$loggerFilename');
  static Uri get appPublicKeyUri => Uri.parse('${_tempDirectory?.path}/$appPublicKeyFilename');
  static Uri get appPrivateKeyUri => Uri.parse('${_tempDirectory?.path}/$appPrivateKeyFilename');


  static init() async {
    _tempDirectory = (await getTemporaryDirectory());
    _docDirectory = await getApplicationDocumentsDirectory();
    logger.d('temp directory: $_tempDirectory, doc directory: $_docDirectory');
    final logFile = File.fromUri(logFileUri);
    if (!logFile.existsSync()) {
      logFile.createSync();
    }
  }

  static deleteFile(Uri fileUri) async {
    File.fromUri(fileUri).delete();
  }

  static Future<void> saveFile(Uri fileUri, String contents) async {
    File file = File.fromUri(fileUri);
    if (!file.existsSync()) {
      file.createSync();
    }
    file.writeAsStringSync(contents);
  }

  static Future<void> saveByteFile(Uri fileUri, Uint8List bytes) async {
    final File file = File.fromUri(fileUri);
    file.writeAsBytesSync(bytes);
  }
}