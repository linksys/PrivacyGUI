import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';

void main() {
  group('describePnpSaveError', () {
    test('shows the JNAP error payload instead of its minified runtime type',
        () {
      const error = JNAPError(
        result: 'Error',
        error: 'ErrorDeviceNotInMasterMode',
      );

      expect(describePnpSaveError(error), 'ErrorDeviceNotInMasterMode');
    });

    test('falls back to the JNAP result when the payload is empty', () {
      const error = JNAPError(result: 'ErrorUnknownAction', error: '  ');

      expect(describePnpSaveError(error), 'ErrorUnknownAction');
    });
  });
}
