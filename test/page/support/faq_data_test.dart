import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/support/faq_data.dart';

/// Lower-case words and digits joined by single hyphens (constitution 11.3).
final _kebabCase = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

// The FAQ page builds its identifiers on these keys (constitution 11.3): they
// come from the items' names, never from their translated text.
void main() {
  final categories = <FaqCategory>[
    FaqSetupCategory(),
    FaqConnectivityCategory(),
    FaqSpeedCategory(),
    FaqPasswordCategory(),
    FaqHardwareCategory(),
  ];

  group('FaqItem.identifierKey', () {
    test('is the name without its faq or faqList prefix, in kebab case', () {
      expect(
        {
          for (final item in [
            FaqItem.faqVisitLinksysSupport,
            FaqItem.faqListDeviceNoWiFi,
            FaqItem.faqListMyInternetSlowOrSpecificDeviceSlow,
            FaqItem.noInternetConnectionTitle,
          ])
            item: item.identifierKey,
        },
        {
          FaqItem.faqVisitLinksysSupport: 'visit-linksys-support',
          FaqItem.faqListDeviceNoWiFi: 'device-no-wi-fi',
          FaqItem.faqListMyInternetSlowOrSpecificDeviceSlow:
              'my-internet-slow-or-specific-device-slow',
          FaqItem.noInternetConnectionTitle: 'no-internet-connection-title',
        },
      );
    });

    test('is kebab case and different for every item', () {
      final keys = FaqItem.values.map((item) => item.identifierKey).toList();

      expect(keys, everyElement(matches(_kebabCase)));
      expect(keys.toSet(), hasLength(keys.length));
    });
  });

  group('FaqCategory.identifierKey', () {
    test('is the title key in kebab case', () {
      expect(FaqPasswordCategory().identifierKey, 'password-and-access');
      expect(FaqSetupCategory().identifierKey, 'setup');
    });

    test('is kebab case and different for every category', () {
      final keys = categories.map((category) => category.identifierKey);

      expect(keys, everyElement(matches(_kebabCase)));
      expect(keys.toSet(), hasLength(categories.length));
    });
  });
}
