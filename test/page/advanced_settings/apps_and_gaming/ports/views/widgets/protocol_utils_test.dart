import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/widgets/protocol_utils.dart';

void main() {
  group('protocolIdentifierKey', () {
    // The JNAP value, never the translated title getProtocolTitle gives.
    test('is the protocol\'s JNAP value in lower case', () {
      expect(protocolIdentifierKey('TCP'), 'tcp');
      expect(protocolIdentifierKey('UDP'), 'udp');
      expect(protocolIdentifierKey('Both'), 'both');
    });
  });
}
