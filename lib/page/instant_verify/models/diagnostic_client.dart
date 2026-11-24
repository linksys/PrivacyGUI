import 'package:equatable/equatable.dart';

enum SignalStrength { excellent, fair, weak, veryWeak, unknown }

class DiagnosticClient extends Equatable {
  final String macAddress;
  final String? hostname;
  final String? ipAddress;
  final String band;
  final int? signalDecibels;
  final int? txRateMbps;
  final int? rxRateMbps;
  final bool isWireless;
  final String? deviceType;

  /// Whether the router reports this client as connected to the guest network
  /// (from the JNAP `isGuest` flag). Null when the field is absent.
  final bool? isGuest;

  const DiagnosticClient({
    required this.macAddress,
    this.hostname,
    this.ipAddress,
    required this.band,
    this.signalDecibels,
    this.txRateMbps,
    this.rxRateMbps,
    required this.isWireless,
    this.deviceType,
    this.isGuest,
  });

  String get displayName => cleanHostname ?? macAddress;

  /// Hostname with mDNS/Bonjour service suffixes stripped, so a buried friendly
  /// name surfaces cleanly. e.g. "Anita's MacBook Pro._device-info._tcp.local"
  /// -> "Anita's MacBook Pro". Returns null when nothing usable remains. Raw
  /// identifiers without a service suffix (RINCON_…, wiz_…, a UUID) pass through
  /// unchanged — there's no better name to recover.
  String? get cleanHostname => _cleanHostname(hostname);

  static String? _cleanHostname(String? raw) {
    if (raw == null) return null;
    var n = raw.trim();
    // Drop a DNS-SD service segment: "Name._device-info._tcp.local" (or _udp).
    n = n.replaceFirst(
        RegExp(r'\._[A-Za-z0-9-]+\._(?:tcp|udp)\.local\.?$'), '');
    // Drop a bare trailing ".local".
    n = n.replaceFirst(RegExp(r'\.local\.?$'), '');
    // Some devices report "IP - Friendly Name - SERIAL" as the hostname, e.g.
    // Sonos: "192.168.1.185 - Sonos One - RINCON_38420B6505D20140". When the
    // name is " - "-delimited, drop the segments that are an IP address or a
    // raw serial token and keep the human-readable remainder ("Sonos One").
    // Names without such junk segments are left untouched.
    if (n.contains(' - ')) {
      final ip = RegExp(r'^\d{1,3}(?:\.\d{1,3}){3}$');
      final serial = RegExp(r'^[A-Z0-9]+_[0-9A-Fa-f]{6,}$');
      final parts = n.split(' - ').map((s) => s.trim()).toList();
      final kept = parts
          .where((p) => p.isNotEmpty && !ip.hasMatch(p) && !serial.hasMatch(p))
          .toList();
      if (kept.isNotEmpty && kept.length < parts.length) {
        n = kept.join(' - ');
      }
    }
    n = n.trim();
    return n.isEmpty ? null : n;
  }

  /// OUI manufacturer lookup from the first 3 octets of MAC address.
  String? get manufacturer {
    if (macAddress.length < 8) return null;
    final prefix = macAddress.substring(0, 8).toUpperCase();
    return _ouiMap[prefix];
  }

  /// Display name with manufacturer hint when hostname is absent.
  String get displayNameWithOui {
    final clean = cleanHostname;
    if (clean != null) return clean;
    final mfr = manufacturer;
    return mfr != null ? '$mfr ($macAddress)' : macAddress;
  }

  SignalStrength get signalStrength {
    if (!isWireless || signalDecibels == null) return SignalStrength.unknown;
    final s = signalDecibels!;
    if (s >= -65) return SignalStrength.excellent;
    if (s >= -75) return SignalStrength.fair;
    if (s >= -85) return SignalStrength.weak;
    return SignalStrength.veryWeak;
  }

  bool get isFlagged {
    if (!isWireless) return false;
    if (signalDecibels != null && signalDecibels! < -75) return true;
    if (txRateMbps != null && txRateMbps! < 10) return true;
    if (rxRateMbps != null && rxRateMbps! < 10) return true;
    return false;
  }

  @override
  List<Object?> get props => [macAddress, hostname, ipAddress, band, signalDecibels, txRateMbps, rxRateMbps, isWireless, deviceType, isGuest];
}

/// Common OUI prefixes (MAC first 3 octets) → manufacturer.
/// Format: "XX:XX:XX" uppercase with colons.
const _ouiMap = <String, String>{
  // Apple
  'AC:DE:48': 'Apple', '00:1C:B3': 'Apple', '3C:06:30': 'Apple',
  'A4:83:E7': 'Apple', 'F0:18:98': 'Apple', '14:98:77': 'Apple',
  '78:7B:8A': 'Apple', 'D0:03:4B': 'Apple', '88:66:A5': 'Apple',
  'DC:A9:04': 'Apple', 'F8:FF:C2': 'Apple', '7C:D1:C3': 'Apple',
  'A8:51:AB': 'Apple', 'BC:EC:5D': 'Apple', '84:FC:FE': 'Apple',
  '28:6A:BA': 'Apple', 'C8:69:CD': 'Apple', 'E0:5F:45': 'Apple',
  '38:F9:D3': 'Apple', '4C:57:CA': 'Apple', 'A0:78:17': 'Apple',
  // Samsung
  '00:1A:8A': 'Samsung', 'B4:79:A7': 'Samsung', '84:38:35': 'Samsung',
  'E4:7C:F9': 'Samsung', '00:21:19': 'Samsung', 'A8:7C:01': 'Samsung',
  'CC:07:AB': 'Samsung', '50:01:D9': 'Samsung', 'C0:BD:D1': 'Samsung',
  '94:51:03': 'Samsung', 'FC:A1:83': 'Samsung',
  // Google / Nest
  'F4:F5:D8': 'Google', '54:60:09': 'Google', 'A4:77:33': 'Google',
  '30:FD:38': 'Google', '48:D6:D5': 'Google', '6C:AD:F8': 'Google',
  '18:D6:C7': 'Google/Nest', '64:16:66': 'Google/Nest',
  // Amazon / Ring
  'F0:F0:A4': 'Amazon', '68:54:FD': 'Amazon', '40:B4:CD': 'Amazon',
  '74:C2:46': 'Amazon', 'A4:08:EA': 'Amazon', 'FC:65:DE': 'Amazon',
  '34:D2:70': 'Amazon/Ring',
  // Microsoft / Xbox
  '7C:1E:52': 'Microsoft', '60:45:BD': 'Microsoft', '28:18:78': 'Microsoft',
  '00:50:F2': 'Microsoft', 'C8:3F:26': 'Xbox',
  // Sony / PlayStation
  '00:04:1F': 'Sony', 'A8:E3:EE': 'Sony', '00:24:8D': 'Sony',
  '70:66:55': 'Sony/PS', 'F8:46:1C': 'Sony/PS',
  // Intel
  '00:1B:21': 'Intel', '3C:97:0E': 'Intel', '68:17:29': 'Intel',
  '8C:8D:28': 'Intel', 'AC:67:5D': 'Intel', '48:51:B7': 'Intel',
  // TP-Link
  'C0:06:C3': 'TP-Link', '50:C7:BF': 'TP-Link', '60:A4:B7': 'TP-Link',
  // Linksys / Belkin
  '00:1A:70': 'Linksys', 'C0:56:27': 'Linksys', '58:6D:8F': 'Linksys',
  '20:AA:4B': 'Linksys', 'E8:9F:80': 'Belkin',
  // Roku
  'DC:3A:5E': 'Roku', 'B0:A7:37': 'Roku', 'AC:3A:7A': 'Roku',
  // LG
  '00:1C:62': 'LG', 'A8:23:FE': 'LG', 'C4:36:6C': 'LG',
  // HP
  '3C:D9:2B': 'HP', '00:1A:4B': 'HP', '94:57:A5': 'HP',
  // Dell
  '00:14:22': 'Dell', 'F8:DB:88': 'Dell', 'B0:83:FE': 'Dell',
  // Sonos
  '00:0E:58': 'Sonos', 'B8:E9:37': 'Sonos', '48:A6:B8': 'Sonos',
  // Espressif (IoT / ESP32)
  '24:6F:28': 'Espressif/IoT', '30:AE:A4': 'Espressif/IoT',
  'AC:67:B2': 'Espressif/IoT', 'E8:68:E7': 'Espressif/IoT',
  // Raspberry Pi
  'B8:27:EB': 'Raspberry Pi', 'DC:A6:32': 'Raspberry Pi',
  'E4:5F:01': 'Raspberry Pi',
  // Tuya / Smart Home
  'D8:1F:12': 'Tuya/Smart', '7C:F6:66': 'Tuya/Smart',
  // Wyze
  '2C:AA:8E': 'Wyze',
  // Nvidia (Shield)
  '00:04:4B': 'Nvidia',
  // Nintendo
  '00:1F:C5': 'Nintendo', '00:22:D7': 'Nintendo', '34:AF:2C': 'Nintendo',
  '58:2F:40': 'Nintendo', '98:B6:E9': 'Nintendo',
  // Qualcomm (reference devices)
  '00:03:7F': 'Qualcomm',
};
