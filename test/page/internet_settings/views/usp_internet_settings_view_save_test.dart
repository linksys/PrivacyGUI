import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/views/usp_internet_settings_view.dart';

void main() {
  group('shouldRedirectToBridge', () {
    test('true when entering bridge with a hostname', () {
      expect(
        shouldRedirectToBridge(
          previousType: UspWanConnectionType.dhcp,
          newType: UspWanConnectionType.bridge,
          hostName: 'Community00080',
        ),
        isTrue,
      );
    });

    test('false when already in bridge (no transition)', () {
      expect(
        shouldRedirectToBridge(
          previousType: UspWanConnectionType.bridge,
          newType: UspWanConnectionType.bridge,
          hostName: 'Community00080',
        ),
        isFalse,
      );
    });

    test('false when leaving bridge', () {
      expect(
        shouldRedirectToBridge(
          previousType: UspWanConnectionType.bridge,
          newType: UspWanConnectionType.dhcp,
          hostName: 'Community00080',
        ),
        isFalse,
      );
    });

    test('false when entering bridge but hostname is empty', () {
      expect(
        shouldRedirectToBridge(
          previousType: UspWanConnectionType.dhcp,
          newType: UspWanConnectionType.bridge,
          hostName: '',
        ),
        isFalse,
      );
    });
  });
}
