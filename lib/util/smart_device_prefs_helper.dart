// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:shared_preferences/shared_preferences.dart';

import 'package:privacy_gui/constants/_constants.dart';

/// A helper class for managing preferences related to smart devices.
///
/// This class provides utility methods to construct preference keys that are
/// specific to the currently selected network, ensuring that settings for
/// different networks are stored separately.
class SmartDevicesPrefsHelper {
  /// Constructs a network-specific preference key.
  ///
  /// This method retrieves the current network ID from [SharedPreferences] and
  /// appends it to the given [key], creating a unique key for the current network.
  /// For example, if the key is `settingA` and the network ID is `123`, the
  /// resulting key will be `settingA-123`.
  ///
  /// [prefs] An instance of [SharedPreferences] to access stored data.
  ///
  /// [key] The base key for the preference.
  ///
  /// Returns a `String` representing the network-specific preference key.
  static String getNidKey(SharedPreferences prefs, {required String key}) {
    final nId = prefs.getString(pSelectedNetworkId);
    return '$key-$nId';
  }
}

/// An exception class for errors related to smart device preferences.
///
/// This class can be used to signal issues that occur while accessing or
/// modifying smart device preferences, such as when a required preference
/// is not found.
class SmartDevicePreferenceException {
  /// An error code that provides specific information about the exception.
  final String code;

  /// Creates a [SmartDevicePreferenceException] with the given error [code].
  SmartDevicePreferenceException({
    required this.code,
  });
}
