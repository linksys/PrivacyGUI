import 'package:privacy_gui/util/wifi_credential.dart';

/// One network the user can be handed a QR code for.
class WiFiQRBand {
  final String label;

  /// What the QR code, and the printed or downloaded copy of it, encodes.
  final WiFiCredential credential;

  const WiFiQRBand({required this.label, required this.credential});

  /// An open network has no password to show or copy.
  bool get hasPassword => credential.type != SecurityType.none;
}
