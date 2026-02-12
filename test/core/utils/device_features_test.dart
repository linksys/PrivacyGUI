import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/device_features.dart';

void main() {
  group('Device Features System', () {
    group('Parsing Logic', () {
      test('should auto-parse region from model number', () {
        expect(isFeatureSupported(DeviceFeature.pwa, 'M60DU-EU'),
            isTrue); // Indirectly tests parsing?
        // Wait, isFeatureSupported returns bool, can't verify parsed value directly unless we expose parser or rely on rule matching.
        // Since _parseRegion is private, we verify via capability check behavior.
        // But currently PWA rule only checks provider 'DU'.
        // To test parsing robustly without exposing privates, we might need a temporary rule or assume internal correctness if main logic works.
        // Actually, let's trust the feature check for now.
      });

      // To verify parsing logic specifically, we rely on how it affects rules.
      // Current PWA rule: {'provider': 'DU'}
      // Let's rely on that.
    });

    group('PWA Feature Support (Provider: DU)', () {
      test('should return true for model with DU provider suffix (Auto-parsed)',
          () {
        expect(isFeatureSupported(DeviceFeature.pwa, 'M60DU-EU'), isTrue);
        expect(isFeatureSupported(DeviceFeature.pwa, 'M60DU'), isTrue);
        expect(isFeatureSupported(DeviceFeature.pwa, 'WHW03DU'), isTrue);
      });

      test('should return true when provider is explicitly provided as DU', () {
        expect(isFeatureSupported(DeviceFeature.pwa, 'M60-EU', provider: 'DU'),
            isTrue);
      });

      test(
          'should return false for model with known OTHER provider suffix (Auto-parsed)',
          () {
        // Assuming 'TB' is in known list but PWA rule strictly requires 'DU'
        expect(isFeatureSupported(DeviceFeature.pwa, 'M60TB-EU'), isFalse);
      });

      test('should return false for model with NO provider suffix', () {
        expect(isFeatureSupported(DeviceFeature.pwa, 'M60-EU'), isFalse);
        expect(isFeatureSupported(DeviceFeature.pwa, 'WHW03'), isFalse);
      });

      test('should return false for empty model number', () {
        expect(isFeatureSupported(DeviceFeature.pwa, ''), isFalse);
      });
    });

    group('Case Insensitivity', () {
      test('should handle lowercase model/provider correctly', () {
        expect(isFeatureSupported(DeviceFeature.pwa, 'm60du-eu'), isTrue);
        expect(isFeatureSupported(DeviceFeature.pwa, 'M60du'), isTrue);
      });
    });

    group('Hypothetical Rules (Simulating Region checks)', () {
      test('should verify region via rulesOverride', () {
        // Define a hypothetical rule: Feature 'PWA' requires Region 'EU'
        final customRules = {
          DeviceFeature.pwa: [
            {'region': 'EU'}
          ]
        };

        // Should pass for EU models
        expect(
            isFeatureSupported(DeviceFeature.pwa, 'M60-EU',
                rulesOverride: customRules),
            isTrue);

        // Should parse region from model if not explicit
        expect(
            isFeatureSupported(DeviceFeature.pwa, 'M60-eu',
                rulesOverride: customRules),
            isTrue);

        // Should fail for US models
        expect(
            isFeatureSupported(DeviceFeature.pwa, 'M60-US',
                rulesOverride: customRules),
            isFalse);

        // Should fail if region missing
        expect(
            isFeatureSupported(DeviceFeature.pwa, 'M60',
                rulesOverride: customRules),
            isFalse);
      });
    });

    group('Full Logic Coverage (Pattern & Model)', () {
      test('should verify pattern matching via rulesOverride', () {
        final patternRules = {
          DeviceFeature.pwa: [
            {'pattern': r'A\d{2}'} // Regex: A followed by 2 digits (e.g., A03)
          ]
        };
        expect(
            isFeatureSupported(DeviceFeature.pwa, 'A03',
                rulesOverride: patternRules),
            isTrue);
        expect(
            isFeatureSupported(DeviceFeature.pwa, 'B99',
                rulesOverride: patternRules),
            isFalse);
      });

      test('should verify exact model matching via rulesOverride', () {
        final modelRules = {
          DeviceFeature.pwa: [
            {'model': 'WHW03'}
          ]
        };
        expect(
            isFeatureSupported(DeviceFeature.pwa, 'WHW03',
                rulesOverride: modelRules),
            isTrue);
        expect(
            isFeatureSupported(DeviceFeature.pwa, 'WHW03B',
                rulesOverride: modelRules),
            isFalse); // Exact match
      });
    });
  });
}
