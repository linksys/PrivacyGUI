import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:test/test.dart';

void main() {
  // The page's dirty check is `original != current`, and `props` comes from
  // `namedProps` (DiagnosticLoggable). A field left out of `namedProps` makes
  // two models with different values equal, so a change to that switch never
  // enables Save.
  group('Equatable', () {
    const base = FirewallUIModel();

    final changed = <String, FirewallUIModel>{
      'isIPv4FirewallEnabled':
          base.copyWith(isIPv4FirewallEnabled: !base.isIPv4FirewallEnabled),
      'isIPv6FirewallEnabled':
          base.copyWith(isIPv6FirewallEnabled: !base.isIPv6FirewallEnabled),
      'blockIPSec': base.copyWith(blockIPSec: !base.blockIPSec),
      'blockPPTP': base.copyWith(blockPPTP: !base.blockPPTP),
      'blockL2TP': base.copyWith(blockL2TP: !base.blockL2TP),
      'blockAnonymousRequests':
          base.copyWith(blockAnonymousRequests: !base.blockAnonymousRequests),
      'blockMulticast': base.copyWith(blockMulticast: !base.blockMulticast),
      'blockIDENT': base.copyWith(blockIDENT: !base.blockIDENT),
      'blockNATRedirection':
          base.copyWith(blockNATRedirection: !base.blockNATRedirection),
    };

    for (final MapEntry(key: field, value: model) in changed.entries) {
      test('a change to $field makes the models unequal', () {
        expect(model, isNot(base));
      });
    }

    test('every field is covered above', () {
      expect(changed.keys.toSet(), base.namedProps.keys.toSet());
    });

    test('the same values are equal', () {
      expect(const FirewallUIModel(blockNATRedirection: true),
          const FirewallUIModel(blockNATRedirection: true));
    });
  });

  group('copyWith', () {
    test('keeps every field it is not given', () {
      const all = FirewallUIModel(
        isIPv4FirewallEnabled: false,
        isIPv6FirewallEnabled: false,
        blockIPSec: true,
        blockPPTP: true,
        blockL2TP: true,
        blockAnonymousRequests: true,
        blockMulticast: true,
        blockIDENT: true,
        blockNATRedirection: true,
      );

      expect(all.copyWith(), all);
    });

    test('sets blockNATRedirection', () {
      expect(
        const FirewallUIModel()
            .copyWith(blockNATRedirection: true)
            .blockNATRedirection,
        isTrue,
      );
    });
  });

  group('FirewallSwitch', () {
    // One switch per row on the page, so a new row needs a member here and a
    // rule-key entry in the service's table.
    test('names the nine switches the page draws', () {
      expect(FirewallSwitch.values, hasLength(9));
    });
  });
}
