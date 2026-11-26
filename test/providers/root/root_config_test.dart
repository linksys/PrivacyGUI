// AppRootConfig: the root container's full-screen spinner state
// (root_container.dart reads spinnerTag and singleMessage).

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/providers/root/root_config.dart';

// Values compared with one built as const are built at run time: two equal
// const values are one instance, so == would hold whatever props says.
void main() {
  test('starts with no spinner, not forced, and no messages', () {
    const config = AppRootConfig();

    expect(config.spinnerTag, isNull);
    expect(config.force, isFalse);
    expect(config.messages, isNull);
    expect(config.singleMessage, isNull);
  });

  group('copyWith', () {
    final showing = AppRootConfig(
      spinnerTag: 'general',
      force: true,
      messages: const {0: 'Saving', 5: 'Restarting'},
      singleMessage: 'Saving',
    );

    test('keeps every field it is not given', () {
      final copy = showing.copyWith();

      expect(copy.spinnerTag, 'general');
      expect(copy.force, isTrue);
      expect(copy.messages, {0: 'Saving', 5: 'Restarting'});
      expect(copy.singleMessage, 'Saving');
    });

    test('replaces each field it is given', () {
      final copy = showing.copyWith(
        spinnerTag: 'pnp',
        force: false,
        messages: {0: 'Checking'},
        singleMessage: 'Checking',
      );

      expect(copy.spinnerTag, 'pnp');
      expect(copy.force, isFalse);
      expect(copy.messages, {0: 'Checking'});
      expect(copy.singleMessage, 'Checking');
    });
  });

  group('equality', () {
    test('holds for the same spinner, force and messages', () {
      expect(
          AppRootConfig(
              spinnerTag: 'general',
              force: true,
              messages: const {0: 'Saving'}),
          // A map of its own, so the messages are compared by value.
          AppRootConfig(
              spinnerTag: 'general',
              force: true,
              messages: Map.of(const {0: 'Saving'})));
      expect(AppRootConfig(), const AppRootConfig());
    });

    test('fails when any of them differs', () {
      final config = AppRootConfig(
          spinnerTag: 'general',
          singleMessage: 'Saving',
          messages: const {0: 'a'});

      expect(config, isNot(config.copyWith(spinnerTag: 'pnp')));
      expect(config, isNot(config.copyWith(force: true)));
      expect(config, isNot(config.copyWith(singleMessage: 'Done')));
      expect(config, isNot(config.copyWith(messages: {0: 'b'})));
    });
  });
}
