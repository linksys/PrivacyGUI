import 'dart:io';
import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:privacy_gui/core/utils/storage.dart';
import 'package:privacy_gui/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A global logger instance for application-wide logging.
///
/// This logger is configured with a `ProductionFilter` to control log output
/// based on the build mode, a `SimplePrinter` for formatting, and a
/// [CustomOutput] for handling log persistence.
final logger = Logger(
  filter: ProductionFilter(),
  printer: SimplePrinter(
    printTime: true,
    colors: kIsWeb ? false : stdout.supportsAnsiEscapes,
  ),
  output: CustomOutput(),
);

/// A custom log output handler that writes logs to the console, files, or web storage.
///
/// In debug mode, all logs are printed to the console.
/// For mobile platforms, logs of level `debug` or higher are appended to a log file.
/// For the web platform, logs are cached in memory.
class CustomOutput extends LogOutput {
  final File _file = File.fromUri(Storage.logFileUri);

  @override
  void output(OutputEvent event) async {
    var output = '';
    for (var line in event.lines) {
      // Print every log message on the console in debug mode
      if (kDebugMode) {
        print(line);
      }
      // Log messages with levels lower than 'debug' will not be recorded in the log file
      if (event.level.value >= Level.debug.value) {
        output += line;
      }
    }
    if (!kIsWeb && output.isNotEmpty && _file.existsSync()) {
      await _file.writeAsBytes(
          "${Utils.maskSensitiveJsonValues(Utils.replaceHttpScheme(output.toString()))}\n"
              .codeUnits,
          mode: FileMode.writeOnlyAppend);
    } else if (kIsWeb && output.isNotEmpty) {
      // final SharedPreferences sp = await SharedPreferences.getInstance();
      // String content = sp.getString(pWebLog) ?? '';
      // await sp.setString(pWebLog,
      //     '$content\n${Utils.maskSensitiveJsonValues(Utils.replaceHttpScheme(output.toString()))}\n');
      _recordLog(
        Utils.maskUsernamePasswordBodyValue(
          Utils.maskSensitiveJsonValues(
            Utils.replaceHttpScheme(output.toString()),
          ),
        ),
      );
    }
  }
}

/// A cache to store log messages in memory, primarily for the web platform.
/// The key is the log tag, and the value is a list of tuples containing the
/// timestamp and the log message.
Map<String, List<(int, String)>> _webLogCache = {};

/// A cache specifically for storing the latest state of different state management providers.
/// The key is the provider's name, and the value is its string representation.
Map<String, String> _stateLogCache = {};

/// The maximum number of log entries to keep for the 'RouteChanged' tag.
const _maxLogSizeOfRouteTag = 20;

/// The maximum number of log entries to keep for general tags.
const _maxLogSizeOfGeneralTag = 2000;

/// A regular expression to extract a tag and message from a formatted log string.
/// Expects the format `[TAG]:message`.
const _logTagRegex = r'\[(\w*)\]:(.*)';

/// The default tag for general application logs.
const appLogTag = 'app';

/// The tag used for logging route changes.
const routeLogTag = 'RouteChanged';

/// Records a log message, adding it to the appropriate cache.
///
/// This function adds the log to the general `appLogTag` list and also to a
/// custom tag list if a tag is present in the log message.
///
/// [log] The log message string to record.
void _recordLog(String log) async {
  // Add every log message to the 'app' log list
  _addLogWithTag(message: log);
  // If a custom tag is specified, add to its log list
  final record = _splitTagAndMessage(log);
  if (record != null) {
    _addLogWithTag(message: record.$1, tag: record.$2);
  }
}

/// Adds a log message to the cache under a specific tag, managing size limits.
///
/// If the `tag` is 'State', the message is parsed to update the [stateLogCache].
/// Otherwise, the message is added to the corresponding list in [_webLogCache],
/// removing the oldest entry if the list exceeds its maximum size.
///
/// [message] The log message to add.
/// [tag] The tag under which to store the message. Defaults to [appLogTag].
void _addLogWithTag({required String message, String tag = appLogTag}) {
  final logList = _webLogCache[tag] ?? [];
  final maxSize =
      tag == routeLogTag ? _maxLogSizeOfRouteTag : _maxLogSizeOfGeneralTag;

  if (tag == 'State') {
    final stateMessage = _splitTagAndMessage(message);
    if (stateMessage != null) {
      _stateLogCache[stateMessage.$2] = stateMessage.$1;
    }
  } else {
    if (logList.length + 1 > maxSize) {
      logList.removeAt(0);
    }
    logList.add((DateTime.now().millisecondsSinceEpoch, message));
    _webLogCache[tag] = logList;
  }
}

/// Splits a formatted log string into its message and tag components.
///
/// Uses [_logTagRegex] to parse the string.
///
/// [log] The formatted log string (e.g., `[MyTag]:This is the message`).
///
/// Returns a tuple `(message, tag)` if successful, otherwise `null`.
(String, String)? _splitTagAndMessage(String log) {
  final match = RegExp(_logTagRegex).firstMatch(log);
  if (match == null) {
    return null;
  }
  final tag = match.group(1);
  final message = match.group(2);
  if (message == null || tag == null) {
    return null;
  }
  return (message, tag);
}

/// Retrieves all log messages for a specific tag from the cache.
///
/// The messages are sorted by timestamp before being concatenated into a single string.
///
/// [tag] The log tag to retrieve. Defaults to [appLogTag].
///
/// Returns a single string containing all the log messages for the given tag,
/// separated by newlines.
String _getWebLogByTag({String tag = appLogTag}) {
  final logList = _webLogCache[tag] ?? [];
  return logList
      .sorted((a, b) => a.$1.compareTo(b.$1))
      .map((e) => e.$2)
      .join('\n');
}

/// Compiles a full diagnostic log report as a single string.
///
/// This function is intended for debugging and support purposes. It gathers
/// information about the application package, device, screen, view history,
/// state management, and all cached logs into a structured, readable format.
///
/// [context] The `BuildContext` used to retrieve screen information.
///
/// Returns a `Future<String>` that completes with the full log report.
Future<String> outputFullWebLog(BuildContext context) async {
  final keys = List.from(_webLogCache.keys)
    ..remove(appLogTag)
    ..remove(routeLogTag);
  final screenInfo = getScreenInfo(context);

  return '''
${await getPackageInfo()}
$screenInfo
================================ View History ==================================
${_getWebLogByTag(tag: routeLogTag)}
============================== Custom Tag Summary ==============================
${keys.map((e) => '[$e]\n${_getWebLogByTag(tag: e)}').join('\n\n')}
============================== State Management ==============================
${_stateLogCache.entries.map((e) => '[${e.key}]\n${e.value}').join('\n\n')}
================================== Full Logs ===================================
${_getWebLogByTag()}\n
''';
}

/// Retrieves detailed information about the application package and the host device.
///
/// This function gathers data like app name, version, build number, and OS details
/// using the `package_info_plus` and `device_info_plus` packages.
///
/// Returns a `Future<String>` that completes with a formatted string containing
/// the package and device information.
Future<String> getPackageInfo() async {
  final packageInfo = await PackageInfo.fromPlatform();
  List<String> appInfo = [
    '================================= Package Info =================================',
    'App Name: ${packageInfo.appName}',
    'App ID: ${packageInfo.packageName}',
    'App Build Number: ${packageInfo.buildNumber}',
    'App Version: ${packageInfo.version}',
    if (!kIsWeb) 'Platform OS: ${Platform.operatingSystem}',
    if (!kIsWeb) 'OS version: ${Platform.operatingSystemVersion}',
    'OS: ${defaultTargetPlatform.name}',
  ];

    appInfo.add(
      '================================= Device Info ==================================',
    );
    appInfo.add(await _getDeviceInfo(DeviceInfoPlugin()));

  return appInfo.join('\n');
}

/// A private helper to get device-specific information based on the platform.
///
/// [plugin] An instance of [DeviceInfoPlugin].
///
/// Returns a `Future<String>` with formatted device info, or an empty string
/// for unsupported platforms.
Future<String> _getDeviceInfo(DeviceInfoPlugin plugin) async {
  if (kIsWeb) {
    return (await plugin.webBrowserInfo).data.toString();
  }
  if (Platform.isIOS) {
    return _getIosDeviceInfo(await plugin.iosInfo).join('\n');
  } else if (Platform.isAndroid) {
    return _getAndroidDeviceInfo(await plugin.androidInfo).join('\n');
  } else {
    return '';
  }
}

/// Formats information from an [IosDeviceInfo] object into a list of strings.
///
/// [info] The [IosDeviceInfo] object containing the device details.
///
/// Returns a `List<String>` where each string is a key-value pair of device info.
List<String> _getIosDeviceInfo(IosDeviceInfo info) {
  return [
    'Phone name: ${info.name}',
    'System name: ${info.systemName}',
    'System version: ${info.systemVersion}',
    'Model: ${info.model}',
    'Localized model: ${info.localizedModel}',
    'Vendor identifier: ${info.identifierForVendor}',
    'isPhysicalDevice: ${info.isPhysicalDevice}',
    '(Utsname) System name: ${info.utsname.sysname}',
    '(Utsname) Network node name: ${info.utsname.nodename}',
    '(Utsname) Release level: ${info.utsname.release}',
    '(Utsname) Version level: ${info.utsname.version}',
    '(Utsname) Hardware type: ${info.utsname.machine}',
  ];
}

/// Formats information from an [AndroidDeviceInfo] object into a list of strings.
///
/// [info] The [AndroidDeviceInfo] object containing the device details.
///
/// Returns a `List<String>` where each string is a key-value pair of device info.
List<String> _getAndroidDeviceInfo(AndroidDeviceInfo info) {
  return [
    'version.securityPatch: ${info.version.securityPatch}',
    'version.sdkInt: ${info.version.sdkInt}',
    'version.release: ${info.version.release}',
    'brand: ${info.brand}',
    'device: ${info.device}',
    'hardware: ${info.hardware}',
    'host: ${info.host}',
    'id: ${info.id}',
    'manufacturer: ${info.manufacturer}',
    'model: ${info.model}',
    'product: ${info.product}',
    'isPhysicalDevice: ${info.isPhysicalDevice}',
  ];
}

/// Gathers and formats information about the device's screen and display settings.
///
/// [context] The `BuildContext` from which to access `MediaQuery` data.
///
/// Returns a formatted string containing screen size, pixel ratio, text scale factor,
/// and safe area padding.
String getScreenInfo(BuildContext context) {
  final List data = [
    '================================= Screen Info ==================================',
    'Screen size: ${MediaQueryUtils.getScreenSize(context)}',
    'Physical Screen size: ${MediaQueryUtils.getScreenSize(context)}',
    'Screen pixel ratio: ${MediaQueryUtils.getScreenRatio(context)}',
    'Font scale: ${MediaQueryUtils.getTextScaleFactor(context)}',
    'Top padding of safe area: ${MediaQueryUtils.getTopSafeAreaPadding(context)}',
    'Bottom padding of safe area: ${MediaQueryUtils.getBottomSafeAreaPadding(context)}',
  ];
  return data.join('\n');
}
