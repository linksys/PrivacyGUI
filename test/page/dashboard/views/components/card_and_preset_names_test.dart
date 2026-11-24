import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/views/components/card_and_preset_names.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ja = lookupAppLocalizations(const Locale('ja'));

  group('a card name', () {
    test('comes from a key for every built-in card, not from displayName', () {
      expect(UspWidgetSpecs.all, hasLength(18));
      for (final spec in UspWidgetSpecs.all) {
        // Same id, different displayName: only a lookup keyed by id can still
        // produce the card's real name.
        final decoy = WidgetSpec(
          id: spec.id,
          displayName: 'decoy',
          constraints: spec.constraints,
        );
        expect(decoy.resolveName(en), spec.displayName,
            reason: '${spec.id} has no key, or its English differs from '
                'the registry');
      }
    });

    test('is in the user language for a built-in card', () {
      expect(
          UspWidgetSpecs.getById('topology')!.resolveName(ja), 'ネットワークトポロジー');
    });

    test('is the template displayName for a package widget, which has no key',
        () {
      const package = WidgetSpec(
        id: 'pkg_weather',
        displayName: 'Weather Now',
        constraints: {},
      );
      expect(package.resolveName(ja), 'Weather Now');
    });
  });

  test('a preset keeps its English name and description, from keys', () {
    // The strings the enum held before #1312 moved them into app_en.arb.
    const english = {
      UspDashboardPreset.essential: (
        'Essential',
        'Core network info — ideal for everyday users'
      ),
      UspDashboardPreset.standard: (
        'Standard',
        'Common features at a glance — recommended'
      ),
      UspDashboardPreset.professional: (
        'Professional',
        'All cards enabled — for power users'
      ),
      UspDashboardPreset.monitoring: (
        'Monitoring',
        'Performance & analytics focused — for network admins'
      ),
      UspDashboardPreset.remote: (
        'Remote Support',
        'View-only mode for remote assistance sessions'
      ),
    };
    expect(english.keys, UspDashboardPreset.values);
    for (final MapEntry(key: preset, value: (name, description))
        in english.entries) {
      expect(preset.resolveName(en), name);
      expect(preset.resolveDescription(en), description);
    }
  });
}
