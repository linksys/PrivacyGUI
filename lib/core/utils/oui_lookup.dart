import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// OUI (Organizationally Unique Identifier) lookup for MAC address vendor identification.
///
/// The first 3 bytes of a MAC address identify the manufacturer.
/// Data source: IEEE OUI database (https://standards-oui.ieee.org/)
/// Database file: assets/resources/oui_database.json (39,447 entries)
///
/// Usage:
/// ```dart
/// // Initialize once at app startup
/// await OuiLookup.initialize();
///
/// // Then use synchronously
/// final vendor = OuiLookup.getVendor('A0:7D:9C:67:CD:4C');
/// // Returns 'Samsung Electronics Co.,Ltd'
/// ```
class OuiLookup {
  OuiLookup._();

  static Map<String, String>? _ouiDatabase;
  static bool _isInitialized = false;
  static Duration? _loadDuration;

  /// Initialize the OUI database from assets.
  /// Call once at app startup. Safe to call multiple times.
  /// Returns the time taken to load the database.
  static Future<Duration> initialize() async {
    if (_isInitialized) return _loadDuration ?? Duration.zero;

    final stopwatch = Stopwatch()..start();

    final jsonString =
        await rootBundle.loadString('assets/resources/oui_database.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _ouiDatabase = jsonMap.cast<String, String>();

    stopwatch.stop();
    _loadDuration = stopwatch.elapsed;
    _isInitialized = true;

    return _loadDuration!;
  }

  /// Check if the database is initialized.
  static bool get isInitialized => _isInitialized;

  /// Get the number of OUI entries in the database.
  static int get entryCount => _ouiDatabase?.length ?? 0;

  /// Get the time taken to load the database (null if not yet loaded).
  static Duration? get loadDuration => _loadDuration;

  /// Look up vendor name by MAC address.
  /// Returns null if OUI is not in the database or database not initialized.
  static String? getVendor(String mac) {
    if (_ouiDatabase == null) return null;
    final oui = _normalizeOui(mac);
    if (oui == null) return null;
    return _ouiDatabase![oui];
  }

  /// Returns vendor name, or 'Private/Random' for locally administered MACs.
  static String? getVendorOrPrivate(String mac) {
    if (isRandomizedMac(mac)) return 'Private/Random';
    return getVendor(mac);
  }

  /// Check if OUI exists in database.
  static bool hasVendor(String mac) {
    if (_ouiDatabase == null) return false;
    final oui = _normalizeOui(mac);
    if (oui == null) return false;
    return _ouiDatabase!.containsKey(oui);
  }

  /// Check if MAC is locally administered (random/private).
  /// Bit 1 of first byte indicates locally administered.
  static bool isRandomizedMac(String mac) {
    final cleaned = mac.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
    if (cleaned.length < 2) return false;
    final firstByte = int.tryParse(cleaned.substring(0, 2), radix: 16);
    if (firstByte == null) return false;
    return (firstByte & 0x02) != 0;
  }

  /// Normalize MAC to OUI format (uppercase, no separator).
  /// Accepts formats: AA:BB:CC:DD:EE:FF, AA-BB-CC-DD-EE-FF, AABBCCDDEEFF
  static String? _normalizeOui(String mac) {
    final cleaned = mac.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
    if (cleaned.length < 6) return null;
    return cleaned.substring(0, 6);
  }

  /// Reset the database (for testing purposes only).
  @visibleForTesting
  static void reset() {
    _ouiDatabase = null;
    _isInitialized = false;
    _loadDuration = null;
  }

  /// Initialize with a pre-built map (for testing purposes only).
  @visibleForTesting
  static void initializeForTesting(Map<String, String> database) {
    _ouiDatabase = database;
    _isInitialized = true;
    _loadDuration = Duration.zero;
  }
}
