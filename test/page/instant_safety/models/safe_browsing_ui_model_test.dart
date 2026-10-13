import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_safety/models/safe_browsing_ui_model.dart';

void main() {
  group('SafeBrowsingUIModel — isOpenDns', () {
    test('OpenDNS Family Shield as the first server is OpenDNS', () {
      expect(
        SafeBrowsingUIModel.isOpenDns('208.67.222.222,208.67.220.220'),
        isTrue,
      );
    });

    test('the first server alone decides, whitespace aside', () {
      expect(SafeBrowsingUIModel.isOpenDns(' 208.67.222.222 '), isTrue);
      expect(SafeBrowsingUIModel.isOpenDns('208.67.222.222,8.8.8.8'), isTrue);
    });

    test('OpenDNS in second place is not OpenDNS', () {
      expect(SafeBrowsingUIModel.isOpenDns('8.8.8.8,208.67.222.222'), isFalse);
    });

    test('no DNS servers is not OpenDNS', () {
      expect(SafeBrowsingUIModel.isOpenDns(''), isFalse);
    });
  });

  group('SafeBrowsingUIModel.fromDnsServers', () {
    test('OpenDNS servers read as OpenDNS, keeping the raw value', () {
      expect(
        SafeBrowsingUIModel.fromDnsServers('208.67.222.222,208.67.220.220'),
        const SafeBrowsingUIModel(
          type: SafeBrowsingType.openDNS,
          currentDnsServers: '208.67.222.222,208.67.220.220',
        ),
      );
    });

    test('any other servers read as off', () {
      expect(
        SafeBrowsingUIModel.fromDnsServers('8.8.8.8'),
        const SafeBrowsingUIModel(
          type: SafeBrowsingType.off,
          currentDnsServers: '8.8.8.8',
        ),
      );
    });
  });
}
