import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/login/auto_parent/providers/auto_parent_first_login_state.dart';

void main() {
  // ===========================================================================
  // User Story 3 - AutoParentFirstLoginState Tests (T029-T030)
  // ===========================================================================

  group('AutoParentFirstLoginState', () {
    test('equality - two instances are equal', () {
      // Arrange
      final state1 = AutoParentFirstLoginState();
      final state2 = AutoParentFirstLoginState();

      // Assert
      expect(state1, equals(state2));
    });

    test('props returns empty list', () {
      // Arrange
      final state = AutoParentFirstLoginState();

      // Assert
      expect(state.props, isEmpty);
    });

    test('hashCode is consistent for equal objects', () {
      // Arrange
      final state1 = AutoParentFirstLoginState();
      final state2 = AutoParentFirstLoginState();

      // Assert
      expect(state1.hashCode, equals(state2.hashCode));
    });
  });
}
