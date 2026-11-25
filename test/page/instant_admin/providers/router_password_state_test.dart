import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_admin/providers/router_password_state.dart';

const _state = <String, dynamic>{
  'adminPassword': 'Current-Pass1',
  'hint': 'pet name',
  'isValid': true,
  'isDefault': false,
  'isSetByUser': true,
  'hasEdited': true,
  'error': null,
  'remainingErrorAttempts': 3,
};

void main() {
  group('RouterPasswordState', () {
    test('starts as a default password the user never set', () {
      final state = RouterPasswordState.init();

      expect(state.isDefault, isTrue);
      expect(state.isSetByUser, isFalse);
      expect(state.adminPassword, '');
      expect(state.hint, '');
      expect(state.remainingErrorAttempts, isNull);
    });

    test('reads and writes the same map', () {
      final state = RouterPasswordState.fromMap(_state);

      expect(state.adminPassword, 'Current-Pass1');
      expect(state.remainingErrorAttempts, 3);
      expect(state.toMap(), _state);
    });

    test('survives a JSON round trip', () {
      final state = RouterPasswordState.fromMap(_state);

      expect(RouterPasswordState.fromJson(state.toJson()), state);
    });

    test('copyWith changes what it is given and keeps the rest', () {
      final state = RouterPasswordState.fromMap(_state)
          .copyWith(remainingErrorAttempts: 1);

      expect(state.remainingErrorAttempts, 1);
      expect(state.hint, 'pet name');
      expect(state, isNot(RouterPasswordState.fromMap(_state)));
    });
  });
}
