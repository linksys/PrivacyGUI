import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:linksys_moab/constants/build_config.dart';
import 'package:linksys_moab/network/http/model/cloud_config.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:path_provider/path_provider.dart';

class Storage {

  static Directory? _tempDirectory;
  static Directory? get tempDirectory => _tempDirectory;
  static Directory? _docDirectory;
  static Directory? get docDirectory => _docDirectory;
  static const String loggerFilename = 'logger.txt';
  static final String appPublicKeyFilename = '${cloudEnvTarget.name}_key.pem';
  static final String appPrivateKeyFilename = '${cloudEnvTarget.name}_key.key';
  static const String iconMapFilename = 'sprite-icons-map.png';
  static const String appSignaturesFilename = 'app-signatures.json';
  static const String webFiltersFilename = 'web-filters.json';
  static const String categoryPresetsFilename = 'security-category-presets.json';
  static const String secureProfilePresets = 'profile-presets.json';

  static Uri get logFileUri => Uri.parse('${_tempDirectory?.path}/$loggerFilename');
  static Uri get shareLogFileUri => Uri.parse('${_tempDirectory?.path}/$loggerFilename');

  static Uri get iconFileUri => Uri.parse('${Storage.tempDirectory?.path}/$iconMapFilename');
  static Uri get appSignaturesFileUri => Uri.parse('${Storage.tempDirectory?.path}/$appSignaturesFilename');
  static Uri get webFiltersFileUri => Uri.parse('${Storage.tempDirectory?.path}/$webFiltersFilename');
  static Uri get categoryPresetsFileUri => Uri.parse('${Storage.tempDirectory?.path}/$categoryPresetsFilename');
  static Uri get secureProfilePresetsFileUri => Uri.parse('${Storage.tempDirectory?.path}/$secureProfilePresets');

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