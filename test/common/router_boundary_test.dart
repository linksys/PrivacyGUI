import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

import 'router_boundary.dart';

void main() {
  test('holdsInTurn needs an answer, and says for which action', () {
    expect(
      () => RouterBoundary().holdsInTurn(JNAPAction.getDevices, []),
      throwsA(isA<ArgumentError>()
          .having((error) => error.message, 'message', contains('getDevices'))),
    );
  });
}
