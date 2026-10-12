import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/services/port_rule_limits.dart';

import '../../../mocks/test_data/port_forwarding_test_data.dart';

/// A forwarding rule on [start]..[end]; only the external ports, protocol and
/// enabled flag matter to the checks under test.
PortForwardingRuleUIModel _fwd(
  int start, {
  int end = 0,
  String protocol = 'TCP',
  bool enabled = true,
}) =>
    PortForwardingTestData.createRule(
      externalPort: start,
      externalPortEndRange: end,
      protocol: protocol,
      enabled: enabled,
    );

void main() {
  // The rules are FLWRT 2.0.3's own (feed_usp#47, `ls_port_mapping_overlaps`),
  // which are JNAP 1.0's: closed external ranges, single and range rules
  // compared together, disabled rules included, and only protocols that share
  // TCP or UDP collide.
  group('forwardingOverlaps', () {
    test('the same single port on the same protocol collides', () {
      expect(
        forwardingOverlaps(
          externalPort: 8080,
          externalPortEndRange: 0,
          protocol: 'TCP',
          others: [_fwd(8080)],
        ),
        isTrue,
      );
    });

    // The bench case FW 2.0.3 stores without refusing (fwdev204_run2.log B2).
    test('a range covering an existing single port collides', () {
      expect(
        forwardingOverlaps(
          externalPort: 18070,
          externalPortEndRange: 18090,
          protocol: 'TCP',
          others: [_fwd(18080)],
        ),
        isTrue,
      );
    });

    test('Both collides with TCP and with UDP', () {
      for (final existing in ['TCP', 'UDP']) {
        expect(
          forwardingOverlaps(
            externalPort: 8080,
            externalPortEndRange: 0,
            protocol: 'Both',
            others: [_fwd(8080, protocol: existing)],
          ),
          isTrue,
          reason: 'Both vs $existing',
        );
      }
      expect(
        forwardingOverlaps(
          externalPort: 8080,
          externalPortEndRange: 0,
          protocol: 'UDP',
          others: [_fwd(8080, protocol: 'Both')],
        ),
        isTrue,
        reason: 'UDP vs Both',
      );
    });

    test('TCP and UDP on the same port do not collide', () {
      expect(
        forwardingOverlaps(
          externalPort: 8080,
          externalPortEndRange: 0,
          protocol: 'UDP',
          others: [_fwd(8080, protocol: 'TCP')],
        ),
        isFalse,
      );
    });

    test('a disabled rule still holds its ports', () {
      expect(
        forwardingOverlaps(
          externalPort: 8080,
          externalPortEndRange: 0,
          protocol: 'TCP',
          others: [_fwd(8080, enabled: false)],
        ),
        isTrue,
      );
    });

    test('ranges that only touch end to end collide; adjacent ones do not', () {
      final existing = [_fwd(3000, end: 3010)];
      expect(
        forwardingOverlaps(
          externalPort: 3010,
          externalPortEndRange: 3020,
          protocol: 'TCP',
          others: existing,
        ),
        isTrue,
        reason: '3010 is in both',
      );
      expect(
        forwardingOverlaps(
          externalPort: 3011,
          externalPortEndRange: 3020,
          protocol: 'TCP',
          others: existing,
        ),
        isFalse,
        reason: '3011-3020 starts after 3000-3010 ends',
      );
    });

    test('no other rule means no collision', () {
      expect(
        forwardingOverlaps(
          externalPort: 8080,
          externalPortEndRange: 0,
          protocol: 'TCP',
          others: const [],
        ),
        isFalse,
      );
    });
  });

  group('othersThan', () {
    // Two unsaved rules can be equal field for field, so `==` would drop both.
    test('drops the rule being edited by identity, not by equality', () {
      final a = _fwd(8080);
      final b = _fwd(8080);
      final c = _fwd(9090);

      expect(othersThan([a, b, c], a), [b, c]);
      expect(identical(othersThan([a, b, c], a).first, b), isTrue);
    });

    test('a new rule (none being edited) keeps the whole list', () {
      final rules = [_fwd(8080), _fwd(9090)];
      expect(othersThan(rules, null), rules);
    });
  });

  // FW counts bytes (`strlen` against 32), not characters: a CJK character is
  // three bytes in UTF-8, so eleven of them is 33.
  group('descriptionTooLong', () {
    test('32 ASCII bytes fit, 33 do not', () {
      expect(descriptionTooLong('a' * 32), isFalse);
      expect(descriptionTooLong('a' * 33), isTrue);
    });

    test('counts UTF-8 bytes, not characters', () {
      expect(descriptionTooLong('網' * 10), isFalse, reason: '30 bytes');
      expect(descriptionTooLong('網' * 11), isTrue, reason: '33 bytes');
    });
  });

  // FW 2.0.3's `ls_trigger_overlaps`, which is JNAP 1.0's: a trigger range may
  // not overlap another rule's trigger range, nor a forwarded range another
  // rule's forwarded range. Protocol is not compared — 1.0 stores every trigger
  // as TCP and UDP.
  group('trigger and forward range overlaps', () {
    PortTriggeringRuleUIModel trig(int t, int f, {int fEnd = 0}) =>
        PortTriggeringRuleUIModel(
          enabled: true,
          description: '',
          triggerPort: t,
          triggerProtocol: 'Both',
          forwardRules: [
            PortTriggerForwardRuleUIModel(
              forwardPort: f,
              forwardPortEndRange: fEnd,
              forwardProtocol: 'Both',
            ),
          ],
        );

    test('a trigger range covering another rule\'s trigger collides', () {
      expect(
        triggerRangeOverlaps(
          port: 9000,
          portEndRange: 9010,
          others: [trig(9005, 30000)],
        ),
        isTrue,
      );
    });

    test('a forwarded range covering another rule\'s forward collides', () {
      expect(
        forwardRangeOverlaps(
          port: 30000,
          portEndRange: 30010,
          others: [trig(9000, 30005)],
        ),
        isTrue,
      );
    });

    test('triggers are compared with triggers, forwards with forwards', () {
      final others = [trig(9000, 30000)];
      expect(
        triggerRangeOverlaps(port: 30000, portEndRange: 0, others: others),
        isFalse,
        reason: '30000 is that rule\'s forward, not its trigger',
      );
      expect(
        forwardRangeOverlaps(port: 9000, portEndRange: 0, others: others),
        isFalse,
        reason: '9000 is that rule\'s trigger, not its forward',
      );
    });
  });
}
