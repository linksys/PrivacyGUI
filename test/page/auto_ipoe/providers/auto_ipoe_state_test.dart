// Unit tests for AutoIPoEState.
//
// The state is the shape the four AutoIPoE Get actions land in, and it is what
// the support gate returns unchanged when a router cannot do AutoIPoE — so
// `init` meaning "not supported" is a contract the rest of the code reads, not
// an incidental default. The round trip matters because the same map shape comes
// off the wire.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_state.dart';

import '../../../test_data/auto_ipoe_state_data.dart';

void main() {
  test('init reads as "this router cannot do AutoIPoE"', () {
    const state = AutoIPoEState.init();

    // This is what the notifier's support gate hands back, and what callers
    // check to decide whether to offer the feature at all.
    expect(state.capabilities.isSupported, isFalse);
    expect(state.capabilities.supportedModes, isEmpty);
    expect(state.settings.isEnabled, isFalse);
    expect(state.status.isEnabled, isFalse);
    expect(state.log.content, isEmpty);
  });

  test('copyWith replaces only the parts it is given', () {
    final populated = AutoIPoEState.fromMap(autoIPoEStateV6Plus);
    const init = AutoIPoEState.init();

    final onlyStatus = init.copyWith(status: populated.status);

    expect(onlyStatus.status, populated.status);
    expect(onlyStatus.capabilities, init.capabilities);
    expect(onlyStatus.settings, init.settings);
    expect(onlyStatus.log, init.log);
  });

  test('survives a map round trip', () {
    final state = AutoIPoEState.fromMap(autoIPoEStateV6Plus);

    expect(AutoIPoEState.fromMap(state.toMap()), state);
  });

  test('survives a json round trip', () {
    final state = AutoIPoEState.fromMap(autoIPoEStateAuto);

    expect(AutoIPoEState.fromJson(state.toJson()), state);
  });

  test('parses a static-IP mode with a stored-only password', () {
    final state = AutoIPoEState.fromMap(autoIPoEStateV6Plus);

    expect(state.settings.selectedMode, AutoIPoEMode.v6PlusStaticIp);
    expect(state.capabilities.isSupported, isTrue);
    // The router reports an already-configured secret as stored with no value,
    // and the state has to keep that distinction rather than inventing an empty
    // password.
    final secret = state.settings.v6PlusStaticIpSettings.userPassword;
    expect(secret.hasStoredValue, isTrue);
    expect(secret.value, isNull);
  });

  test('equality is by value across all four parts', () {
    final a = AutoIPoEState.fromMap(autoIPoEStateAuto);
    final b = AutoIPoEState.fromMap(autoIPoEStateAuto);

    expect(a, b);
    // A different mode in one part is enough to break equality. Not the log:
    // this fixture's log already equals the init value, so swapping it in would
    // compare equal and prove nothing.
    final otherSettings = AutoIPoEState.fromMap(autoIPoEStateV6Plus).settings;
    expect(a.copyWith(settings: otherSettings), isNot(b));
  });
}
