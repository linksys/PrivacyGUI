import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';

void main() {
  group('FirewallStatus — lockedSwitches', () {
    // A save toggles isSaving twice. Dropping the locks there would unlock a
    // switch whose rule is not on the router once the save ends (#1611).
    test('survives a copyWith that changes something else', () {
      const status = FirewallStatus(
        isLoading: false,
        lockedSwitches: {FirewallSwitch.natRedirection},
      );

      expect(
        status
            .copyWith(isSaving: true)
            .copyWith(isSaving: false)
            .lockedSwitches,
        {FirewallSwitch.natRedirection},
      );
    });

    test('takes part in equality', () {
      expect(
        const FirewallStatus(lockedSwitches: {FirewallSwitch.ident}),
        isNot(const FirewallStatus()),
      );
    });
  });
}
