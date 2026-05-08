import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/oui_lookup.dart';

/// Device category for UI display and filtering.
enum DeviceCategory {
  phone('Phone', 'smartphone'),
  tablet('Tablet', 'tablet'),
  computer('Computer', 'computer'),
  tv('TV', 'tv'),
  gameConsole('Game Console', 'sports_esports'),
  mediaPlayer('Media Player', 'cast'),
  smartSpeaker('Smart Speaker', 'speaker'),
  camera('Camera', 'videocam'),
  printer('Printer', 'print'),
  networkDevice('Network Device', 'router'),
  iot('Smart Home', 'lightbulb'),
  wearable('Wearable', 'watch'),
  unknown('Unknown', 'devices_other');

  const DeviceCategory(this.displayName, this.iconName);

  final String displayName;
  final String iconName;
}

/// Classifies network devices based on hostname and MAC address.
///
/// Uses a combination of hostname pattern matching and OUI vendor lookup
/// to infer device category. Hostname patterns take priority as they are
/// more specific than vendor-only inference.
class DeviceClassifier {
  DeviceClassifier._();

  /// Classify a device based on hostname and MAC address.
  static DeviceCategory classify({
    required String hostname,
    required String mac,
  }) {
    // 1. Try hostname pattern matching first (most reliable)
    final fromHostname = _matchHostnamePattern(hostname);
    if (fromHostname != null) return fromHostname;

    // 2. Try OUI-based inference
    final vendor = OuiLookup.getVendor(mac);
    if (vendor != null) {
      final fromVendor = _inferFromVendor(vendor);
      if (fromVendor != null) return fromVendor;
    }

    // 3. Check for randomized MAC (iOS 14+, Android 10+)
    if (OuiLookup.isRandomizedMac(mac)) {
      // Randomized MACs are typically from phones/tablets
      return DeviceCategory.phone;
    }

    return DeviceCategory.unknown;
  }

  /// Get both category and confidence level.
  static ({DeviceCategory category, ClassificationConfidence confidence})
      classifyWithConfidence({
    required String hostname,
    required String mac,
  }) {
    // 1. Hostname pattern (high confidence)
    final fromHostname = _matchHostnamePattern(hostname);
    if (fromHostname != null) {
      return (
        category: fromHostname,
        confidence: ClassificationConfidence.high
      );
    }

    // 2. Definitive vendor (high confidence)
    final vendor = OuiLookup.getVendor(mac);
    if (vendor != null) {
      final definitive = _definitiveVendorCategory(vendor);
      if (definitive != null) {
        return (
          category: definitive,
          confidence: ClassificationConfidence.high
        );
      }

      // 3. Probable vendor (medium confidence)
      final probable = _probableVendorCategory(vendor);
      if (probable != null) {
        return (
          category: probable,
          confidence: ClassificationConfidence.medium
        );
      }
    }

    // 4. Randomized MAC (medium confidence - likely phone/tablet)
    if (OuiLookup.isRandomizedMac(mac)) {
      return (
        category: DeviceCategory.phone,
        confidence: ClassificationConfidence.medium
      );
    }

    return (
      category: DeviceCategory.unknown,
      confidence: ClassificationConfidence.none
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Hostname Pattern Matching
  // ═══════════════════════════════════════════════════════════════════════════

  static DeviceCategory? _matchHostnamePattern(String hostname) {
    if (hostname.isEmpty) return null;
    final lower = hostname.toLowerCase();

    // ── Phones ────────────────────────────────────────────────────────────────
    if (_matchesAny(lower, _phonePatterns)) return DeviceCategory.phone;

    // ── Tablets ───────────────────────────────────────────────────────────────
    if (_matchesAny(lower, _tabletPatterns)) return DeviceCategory.tablet;

    // ── Computers ─────────────────────────────────────────────────────────────
    if (_matchesAny(lower, _computerPatterns)) return DeviceCategory.computer;

    // ── TVs ───────────────────────────────────────────────────────────────────
    if (_matchesAny(lower, _tvPatterns)) return DeviceCategory.tv;

    // ── Game Consoles ─────────────────────────────────────────────────────────
    if (_matchesAny(lower, _gameConsolePatterns)) {
      return DeviceCategory.gameConsole;
    }

    // ── Media Players ─────────────────────────────────────────────────────────
    if (_matchesAny(lower, _mediaPlayerPatterns)) {
      return DeviceCategory.mediaPlayer;
    }

    // ── Smart Speakers ────────────────────────────────────────────────────────
    if (_matchesAny(lower, _smartSpeakerPatterns)) {
      return DeviceCategory.smartSpeaker;
    }

    // ── Cameras ───────────────────────────────────────────────────────────────
    if (_matchesAny(lower, _cameraPatterns)) return DeviceCategory.camera;

    // ── Printers ──────────────────────────────────────────────────────────────
    if (_matchesAny(lower, _printerPatterns)) return DeviceCategory.printer;

    // ── Network Devices ───────────────────────────────────────────────────────
    if (_matchesAny(lower, _networkDevicePatterns)) {
      return DeviceCategory.networkDevice;
    }

    // ── IoT / Smart Home ──────────────────────────────────────────────────────
    if (_matchesAny(lower, _iotPatterns)) return DeviceCategory.iot;

    // ── Wearables ─────────────────────────────────────────────────────────────
    if (_matchesAny(lower, _wearablePatterns)) return DeviceCategory.wearable;

    return null;
  }

  static bool _matchesAny(String text, List<RegExp> patterns) {
    return patterns.any((p) => p.hasMatch(text));
  }

  // ── Phone patterns ──────────────────────────────────────────────────────────
  static final _phonePatterns = [
    RegExp(r'iphone'),
    RegExp(r'android'),
    RegExp(r'galaxy[- ]?(s|z|a|m|note|fold|flip)', caseSensitive: false),
    RegExp(r'pixel[- ]?\d'),
    RegExp(r'oneplus'),
    RegExp(r'xiaomi|redmi|poco'),
    RegExp(r'huawei|honor'),
    RegExp(r'oppo|realme'),
    RegExp(r'vivo'),
    RegExp(r'motorola|moto[- ]?[gez]'),
    RegExp(r'nokia'),
    RegExp(r'sony[- ]?xperia'),
    RegExp(r'lg[- ]?(v|g)\d'),
    RegExp(r'zte'),
    RegExp(r'asus[- ]?zenfone'),
    RegExp(r'meizu'),
  ];

  // ── Tablet patterns ─────────────────────────────────────────────────────────
  static final _tabletPatterns = [
    RegExp(r'ipad'),
    RegExp(r'galaxy[- ]?tab'),
    RegExp(r'surface[- ]?(pro|go)'),
    RegExp(r'kindle'),
    RegExp(r'fire[- ]?hd'),
    RegExp(r'lenovo[- ]?tab'),
    RegExp(r'huawei[- ]?mediapad|matepad'),
    RegExp(r'xiaomi[- ]?pad'),
  ];

  // ── Computer patterns ───────────────────────────────────────────────────────
  static final _computerPatterns = [
    RegExp(r'macbook|imac|mac[- ]?mini|mac[- ]?pro|mac[- ]?studio'),
    RegExp(r'macintosh'),
    RegExp(r'-mac$'),
    RegExp(r'thinkpad|ideapad|lenovo[- ]?(yoga|legion)'),
    RegExp(r'dell[- ]?(xps|inspiron|latitude|precision|alienware)'),
    RegExp(r'hp[- ]?(pavilion|envy|spectre|elitebook|probook|omen)'),
    RegExp(r'asus[- ]?(rog|zenbook|vivobook|tuf)'),
    RegExp(r'acer[- ]?(aspire|predator|nitro|swift)'),
    RegExp(r'surface[- ]?(laptop|book|studio)'),
    RegExp(r'razer[- ]?blade'),
    RegExp(r'msi[- ]?(stealth|raider|creator)'),
    RegExp(r'desktop|workstation'),
    RegExp(r'windows[- ]?pc'),
    RegExp(r'-pc$|^pc-'),
    RegExp(r'laptop'),
  ];

  // ── TV patterns ─────────────────────────────────────────────────────────────
  static final _tvPatterns = [
    RegExp(r'samsung[- ]?tv|samsung[- ]?\d{2}'),
    RegExp(r'lg[- ]?tv|lg[- ]?(oled|nanocell|qned)'),
    RegExp(r'sony[- ]?(bravia|tv)'),
    RegExp(r'tcl[- ]?tv|tcl[- ]?\d'),
    RegExp(r'hisense[- ]?tv'),
    RegExp(r'vizio'),
    RegExp(r'philips[- ]?tv'),
    RegExp(r'panasonic[- ]?tv'),
    RegExp(r'sharp[- ]?tv'),
    RegExp(r'toshiba[- ]?tv'),
    RegExp(r'smart[- ]?tv'),
    RegExp(r'\[tv\]|\(tv\)|^tv[- ]'),
  ];

  // ── Game console patterns ───────────────────────────────────────────────────
  static final _gameConsolePatterns = [
    RegExp(r'playstation|ps[345]|ps[345][- ]?pro'),
    RegExp(r'xbox|xbox[- ]?(one|series|360)'),
    RegExp(r'nintendo|switch|wii[- ]?u?'),
    RegExp(r'steam[- ]?deck'),
  ];

  // ── Media player patterns ───────────────────────────────────────────────────
  static final _mediaPlayerPatterns = [
    RegExp(r'apple[- ]?tv'),
    RegExp(r'roku'),
    RegExp(r'chromecast|google[- ]?tv'),
    RegExp(r'fire[- ]?tv|fire[- ]?stick'),
    RegExp(r'nvidia[- ]?shield'),
    RegExp(r'mi[- ]?box|xiaomi[- ]?box'),
    RegExp(r'plex'),
    RegExp(r'kodi'),
  ];

  // ── Smart speaker patterns ──────────────────────────────────────────────────
  static final _smartSpeakerPatterns = [
    RegExp(r'echo|echo[- ]?(dot|show|studio|pop)'),
    RegExp(r'alexa'),
    RegExp(r'google[- ]?(home|nest|mini|hub|max)'),
    RegExp(r'homepod'),
    RegExp(r'sonos'),
    RegExp(r'bose[- ]?(home|soundbar|speaker)'),
    RegExp(r'jbl[- ]?(link|bar)'),
    RegExp(r'harman'),
  ];

  // ── Camera patterns ─────────────────────────────────────────────────────────
  static final _cameraPatterns = [
    RegExp(r'ring[- ]?(doorbell|camera|stick|floodlight)'),
    RegExp(r'nest[- ]?(cam|hello|doorbell)'),
    RegExp(r'arlo'),
    RegExp(r'wyze[- ]?cam'),
    RegExp(r'eufy[- ]?(cam|doorbell)'),
    RegExp(r'blink'),
    RegExp(r'reolink'),
    RegExp(r'hikvision|dahua'),
    RegExp(r'ip[- ]?cam|ipcamera'),
    RegExp(r'webcam'),
    RegExp(r'security[- ]?cam'),
  ];

  // ── Printer patterns ────────────────────────────────────────────────────────
  static final _printerPatterns = [
    RegExp(r'hp[- ]?(officejet|laserjet|envy|deskjet|photosmart)'),
    RegExp(r'epson[- ]?(ecotank|workforce|expression|stylus)'),
    RegExp(r'canon[- ]?(pixma|imageclass|maxify)'),
    RegExp(r'brother[- ]?(hl|mfc|dcp)'),
    RegExp(r'xerox'),
    RegExp(r'lexmark'),
    RegExp(r'printer'),
    RegExp(r'laserjet|inkjet|deskjet'),
  ];

  // ── Network device patterns ─────────────────────────────────────────────────
  static final _networkDevicePatterns = [
    RegExp(r'router|gateway'),
    RegExp(r'access[- ]?point|ap[- ]?\d'),
    RegExp(r'switch|hub'),
    RegExp(r'nas|synology|qnap|asustor'),
    RegExp(r'unifi|ubiquiti'),
    RegExp(r'netgear|orbi|nighthawk'),
    RegExp(r'tp[- ]?link|archer|deco'),
    RegExp(r'asus[- ]?(rt|rog|zen)?wifi'),
    RegExp(r'linksys|velop'),
    RegExp(r'eero'),
    RegExp(r'd[- ]?link'),
    RegExp(r'mesh|extender|repeater'),
  ];

  // ── IoT / Smart Home patterns ───────────────────────────────────────────────
  static final _iotPatterns = [
    RegExp(r'esp|esp32|esp8266'),
    RegExp(r'tasmota|shelly'),
    RegExp(r'tuya|smartlife'),
    RegExp(r'hue[- ]?bridge|philips[- ]?hue'),
    RegExp(r'wemo'),
    RegExp(r'smart[- ]?(plug|switch|bulb|light|lock|thermostat)'),
    RegExp(r'nest[- ]?(thermostat|protect)'),
    RegExp(r'ecobee'),
    RegExp(r'ring[- ]?alarm'),
    RegExp(r'august|yale[- ]?lock'),
    RegExp(r'roomba|irobot'),
    RegExp(r'dyson'),
    RegExp(r'raspberry[- ]?pi|raspberrypi'),
    RegExp(r'arduino'),
    RegExp(r'home[- ]?assistant'),
    RegExp(r'hubitat|smartthings'),
  ];

  // ── Wearable patterns ───────────────────────────────────────────────────────
  static final _wearablePatterns = [
    RegExp(r'apple[- ]?watch'),
    RegExp(r'galaxy[- ]?watch|gear[- ]?(s|fit|sport)'),
    RegExp(r'fitbit'),
    RegExp(r'garmin'),
    RegExp(r'amazfit'),
    RegExp(r'huawei[- ]?(watch|band)'),
    RegExp(r'xiaomi[- ]?(band|watch)'),
    RegExp(r'oura'),
    RegExp(r'whoop'),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // OUI-Based Vendor Inference
  // ═══════════════════════════════════════════════════════════════════════════

  static DeviceCategory? _inferFromVendor(String vendor) {
    // Try definitive first, then probable
    return _definitiveVendorCategory(vendor) ?? _probableVendorCategory(vendor);
  }

  /// Vendors that ONLY make one type of device.
  static DeviceCategory? _definitiveVendorCategory(String vendor) {
    final lower = vendor.toLowerCase();

    // ── Game Consoles (100% certain) ──────────────────────────────────────────
    if (lower.contains('nintendo')) return DeviceCategory.gameConsole;

    // ── Media Players (100% certain) ──────────────────────────────────────────
    if (lower.contains('roku')) return DeviceCategory.mediaPlayer;

    // ── Smart Speakers (100% certain) ─────────────────────────────────────────
    if (lower.contains('sonos')) return DeviceCategory.smartSpeaker;

    // ── IoT (100% certain) ────────────────────────────────────────────────────
    if (lower.contains('espressif')) return DeviceCategory.iot;
    if (lower.contains('tuya')) return DeviceCategory.iot;
    if (lower.contains('raspberry pi')) return DeviceCategory.iot;
    if (lower.contains('signify') || lower.contains('philips hue')) {
      return DeviceCategory.iot;
    }

    // ── Cameras (100% certain) ────────────────────────────────────────────────
    if (lower.contains('ring llc')) return DeviceCategory.camera;
    if (lower.contains('arlo')) return DeviceCategory.camera;

    // ── Network Devices (100% certain) ────────────────────────────────────────
    if (lower.contains('ubiquiti')) return DeviceCategory.networkDevice;
    if (lower.contains('netgear')) return DeviceCategory.networkDevice;
    if (lower.contains('tp-link')) return DeviceCategory.networkDevice;
    if (lower.contains('d-link')) return DeviceCategory.networkDevice;
    if (lower.contains('linksys')) return DeviceCategory.networkDevice;

    return null;
  }

  /// Vendors that make MOSTLY one type but could be others.
  static DeviceCategory? _probableVendorCategory(String vendor) {
    final lower = vendor.toLowerCase();

    // ── Mostly Phones ─────────────────────────────────────────────────────────
    if (lower.contains('oneplus')) return DeviceCategory.phone;
    if (lower.contains('oppo')) return DeviceCategory.phone;
    if (lower.contains('vivo')) return DeviceCategory.phone;
    if (lower.contains('realme')) return DeviceCategory.phone;
    if (lower.contains('xiaomi')) return DeviceCategory.phone;
    if (lower.contains('huawei')) return DeviceCategory.phone;

    // ── Mostly Game Consoles ──────────────────────────────────────────────────
    if (lower.contains('sony') && !lower.contains('mobile')) {
      // Sony makes PS, TVs, cameras, phones — hard to tell
      // Could return gameConsole with low confidence
      return null;
    }

    // ── Mostly Computers ──────────────────────────────────────────────────────
    if (lower.contains('dell')) return DeviceCategory.computer;
    if (lower.contains('lenovo')) return DeviceCategory.computer;
    if (lower.contains('hp inc')) return DeviceCategory.computer;
    if (lower.contains('asus') && !lower.contains('phone')) {
      return DeviceCategory.computer;
    }

    // ── Ambiguous vendors (Apple, Samsung, Google, Microsoft, LG, Sony) ───────
    // These make phones, tablets, computers, TVs, speakers, etc.
    // Return null to fall back to hostname or unknown

    return null;
  }
}

/// Confidence level for device classification.
enum ClassificationConfidence {
  high,
  medium,
  low,
  none,
}

/// Extension to get [IconData] for [DeviceCategory].
extension DeviceCategoryIcon on DeviceCategory {
  IconData get icon => switch (this) {
        DeviceCategory.phone => Icons.smartphone,
        DeviceCategory.tablet => Icons.tablet,
        DeviceCategory.computer => Icons.computer,
        DeviceCategory.tv => Icons.tv,
        DeviceCategory.gameConsole => Icons.sports_esports,
        DeviceCategory.mediaPlayer => Icons.cast,
        DeviceCategory.smartSpeaker => Icons.speaker,
        DeviceCategory.camera => Icons.videocam,
        DeviceCategory.printer => Icons.print,
        DeviceCategory.networkDevice => Icons.router,
        DeviceCategory.iot => Icons.lightbulb,
        DeviceCategory.wearable => Icons.watch,
        DeviceCategory.unknown => Icons.devices_other,
      };
}
