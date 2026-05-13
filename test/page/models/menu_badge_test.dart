import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/models/menu_badge.dart';

void main() {
  group('MenuBadge', () {
    group('predefined constants', () {
      test('beta has correct label', () {
        expect(MenuBadge.beta.label, 'BETA');
        expect(MenuBadge.beta.color, isNull);
        expect(MenuBadge.beta.textColor, isNull);
      });

      test('on has correct label', () {
        expect(MenuBadge.on.label, 'On');
        expect(MenuBadge.on.color, isNull);
        expect(MenuBadge.on.textColor, isNull);
      });

      test('off has correct label', () {
        expect(MenuBadge.off.label, 'Off');
        expect(MenuBadge.off.color, isNull);
        expect(MenuBadge.off.textColor, isNull);
      });
    });

    group('factory constructors', () {
      test('success creates green badge', () {
        final badge = MenuBadge.success('Done');
        expect(badge.label, 'Done');
        expect(badge.color, Colors.green);
        expect(badge.textColor, isNull);
      });

      test('warning creates orange badge', () {
        final badge = MenuBadge.warning('Caution');
        expect(badge.label, 'Caution');
        expect(badge.color, Colors.orange);
        expect(badge.textColor, isNull);
      });

      test('info creates blue badge', () {
        final badge = MenuBadge.info('Note');
        expect(badge.label, 'Note');
        expect(badge.color, Colors.blue);
        expect(badge.textColor, isNull);
      });

      test('count creates badge with number label', () {
        final badge = MenuBadge.count(42);
        expect(badge.label, '42');
        expect(badge.color, isNull);
      });

      test('count handles zero', () {
        final badge = MenuBadge.count(0);
        expect(badge.label, '0');
      });
    });

    group('custom constructor', () {
      test('creates badge with all parameters', () {
        final badge = MenuBadge(
          label: 'Custom',
          color: Colors.purple,
          textColor: Colors.white,
        );
        expect(badge.label, 'Custom');
        expect(badge.color, Colors.purple);
        expect(badge.textColor, Colors.white);
      });

      test('creates badge with only required label', () {
        final badge = MenuBadge(label: 'Simple');
        expect(badge.label, 'Simple');
        expect(badge.color, isNull);
        expect(badge.textColor, isNull);
      });
    });
  });
}
