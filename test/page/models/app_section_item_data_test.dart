import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/models/app_section_item_data.dart';
import 'package:privacy_gui/page/models/menu_badge.dart';

void main() {
  group('AppSectionItemData', () {
    test('creates with required title only', () {
      final item = AppSectionItemData(title: 'Test Item');

      expect(item.title, 'Test Item');
      expect(item.iconData, isNull);
      expect(item.description, isNull);
      expect(item.badges, isEmpty);
      expect(item.disabledOnBridge, false);
      expect(item.onTap, isNull);
      expect(item.semanticLabel, isNull);
    });

    test('creates with all parameters', () {
      var tapped = false;
      final item = AppSectionItemData(
        iconData: Icons.wifi,
        title: 'WiFi Settings',
        description: 'Configure wireless networks',
        badges: [MenuBadge.on, MenuBadge.beta],
        disabledOnBridge: true,
        onTap: () => tapped = true,
        semanticLabel: 'wifi-settings',
      );

      expect(item.iconData, Icons.wifi);
      expect(item.title, 'WiFi Settings');
      expect(item.description, 'Configure wireless networks');
      expect(item.badges, hasLength(2));
      expect(item.badges[0].label, 'On');
      expect(item.badges[1].label, 'BETA');
      expect(item.disabledOnBridge, true);
      expect(item.semanticLabel, 'wifi-settings');

      item.onTap!();
      expect(tapped, true);
    });

    test('badges defaults to empty list', () {
      final item = AppSectionItemData(title: 'No Badges');
      expect(item.badges, isA<List<MenuBadge>>());
      expect(item.badges, isEmpty);
    });

    test('disabledOnBridge defaults to false', () {
      final item = AppSectionItemData(title: 'Default');
      expect(item.disabledOnBridge, false);
    });
  });
}
