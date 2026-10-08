import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_page_state.dart';

void main() {
  test(
      'saving and error transitions notify consumers without changing settings',
      () {
    final idle = AutoIPoEPageStatus();
    final equivalent = AutoIPoEPageStatus();
    expect(idle, equals(equivalent));
    expect(idle, isNot(equals(const AutoIPoEPageStatus(saving: true))));
    expect(idle,
        isNot(equals(const AutoIPoEPageStatus(error: ConnectivityError()))));
  });

  test('settings edits become dirty and runtime updates preserve edits', () {
    final original = AutoIPoEPageState.initial();
    final edited = original.copyWith(
        settings: original.settings.update(const AutoIPoESettings(
            isEnabled: true, selectedMode: AutoIPoEMode.biglobeStaticIp)));
    expect(edited.isDirty, true);
    expect(edited.copyWith(status: const AutoIPoEPageStatus()).current,
        edited.current);
    expect(edited.toMap(), isEmpty);
    expect(original.isDirty, false);
  });
}
