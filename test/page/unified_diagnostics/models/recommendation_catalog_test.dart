import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/recommendation_catalog.dart';

void main() {
  group('RecommendationCatalog', () {
    test('title returns localized text for known keys', () {
      expect(
        RecommendationCatalog.title('diagnostics_rec_wan_down_title'),
        'WAN Connection Down',
      );
      expect(
        RecommendationCatalog.title('diagnostics_rec_dns_lookup_fail_title'),
        'DNS Resolution Failed',
      );
      expect(
        RecommendationCatalog.title('diagnostics_rec_bottleneck_title'),
        'Network Bottleneck Detected',
      );
    });

    test('title falls back to the key for unknown identifiers', () {
      expect(RecommendationCatalog.title('unknown_key'), 'unknown_key');
      expect(RecommendationCatalog.title(''), '');
    });

    test('description returns localized text for known keys', () {
      expect(
        RecommendationCatalog.description('diagnostics_rec_wan_down_desc'),
        contains('modem'),
      );
      expect(
        RecommendationCatalog.description(
            'diagnostics_rec_dns_lookup_fail_desc'),
        contains('8.8.8.8'),
      );
    });

    test('description falls back to the key for unknown identifiers', () {
      expect(RecommendationCatalog.description('unknown_desc'), 'unknown_desc');
    });

    test('the busy channel entry reads as the in-app card does (#1778)', () {
      // The report's English must match diagnosticsRecBusyChannelTitle /
      // Desc in app_en.arb, which write "WiFi".
      expect(RecommendationCatalog.title('diagnostics_rec_busy_channel_title'),
          'Busy WiFi Channel');
      expect(
          RecommendationCatalog.description(
              'diagnostics_rec_busy_channel_desc'),
          'The channel your WiFi is on is busy. Open Channel Finder to see how '
          'busy each channel is.');
    });

    test('every title key has a matching description key', () {
      const expectedTitleKeys = [
        'diagnostics_rec_wan_down_title',
        'diagnostics_rec_no_ip_title',
        'diagnostics_rec_dhcp_fail_title',
        'diagnostics_rec_gateway_title',
        'diagnostics_rec_dns_fail_title',
        'diagnostics_rec_dns_lookup_fail_title',
        'diagnostics_rec_internet_title',
        'diagnostics_rec_slow_download_title',
        'diagnostics_rec_slow_upload_title',
        'diagnostics_rec_weak_wifi_title',
        'diagnostics_rec_many_devices_title',
        'diagnostics_rec_bandwidth_hog_title',
        'diagnostics_rec_bottleneck_title',
        'diagnostics_rec_busy_channel_title',
      ];
      for (final titleKey in expectedTitleKeys) {
        // Title exists and is not the fallback (key itself).
        expect(RecommendationCatalog.title(titleKey), isNot(equals(titleKey)));
        // Companion description key exists.
        final descKey = titleKey.replaceFirst('_title', '_desc');
        expect(
          RecommendationCatalog.description(descKey),
          isNot(equals(descKey)),
          reason: 'Missing description for $descKey',
        );
      }
    });
  });
}
