import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// Connection detail for a WiFi client: band + SSID name.
class ClientConnectionDetail extends Equatable with DiagnosticLoggable {
  final String band; // "2.4GHz", "5GHz", "6GHz", or ""
  final String ssidName; // The network name

  const ClientConnectionDetail({required this.band, required this.ssidName});

  @override
  Map<String, Object?> get namedProps => {
        'band': band,
        'ssidName': ssidName,
      };
}
