import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_status.dart';

void main() {
  group('Ipv6PortServiceStatus — hiddenRuleDescriptions', () {
    // A save toggles isSaving twice. Dropping the descriptions there would let
    // the next dialog accept a name FW refuses (ErrorDescriptionInUse).
    test('survives a copyWith that changes something else', () {
      const status = Ipv6PortServiceStatus(
        hiddenRuleDescriptions: {'RULE_IDENT'},
      );

      expect(
        status
            .copyWith(isSaving: true)
            .copyWith(isSaving: false)
            .copyWith(error: const NetworkError())
            .copyWith(clearError: true)
            .hiddenRuleDescriptions,
        {'RULE_IDENT'},
      );
    });

    test('takes part in equality', () {
      expect(
        const Ipv6PortServiceStatus(hiddenRuleDescriptions: {'RULE_IDENT'}),
        isNot(const Ipv6PortServiceStatus()),
      );
    });
  });
}
