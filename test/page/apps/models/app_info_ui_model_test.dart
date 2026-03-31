import 'package:flutter/material.dart';
import 'package:privacy_gui/page/apps/models/app_info_ui_model.dart';
import 'package:test/test.dart';

void main() {
  // -----------------------------------------------------------------------
  // Constructor
  // -----------------------------------------------------------------------
  group('constructor', () {
    test('creates with all required fields', () {
      final model = AppInfoUIModel(
        name: 'WireGuard',
        description: 'VPN tunnel',
        link: 'http://192.168.1.1/wireguard',
        version: '1.0.0',
        iconData: Icons.vpn_key,
        color: Colors.blueAccent,
        category: AppCategory.user,
      );

      expect(model.name, 'WireGuard');
      expect(model.description, 'VPN tunnel');
      expect(model.link, 'http://192.168.1.1/wireguard');
      expect(model.version, '1.0.0');
      expect(model.iconData, Icons.vpn_key);
      expect(model.color, Colors.blueAccent);
      expect(model.category, AppCategory.user);
    });
  });

  // -----------------------------------------------------------------------
  // Equatable
  // -----------------------------------------------------------------------
  group('Equatable', () {
    final base = AppInfoUIModel(
      name: 'App',
      description: 'desc',
      link: '/app',
      version: '1.0',
      iconData: Icons.apps,
      color: Colors.blueAccent,
      category: AppCategory.system,
    );

    test('same name/link/version/category are equal', () {
      final other = AppInfoUIModel(
        name: 'App',
        description: 'desc',
        link: '/app',
        version: '1.0',
        iconData: Icons.apps,
        color: Colors.blueAccent,
        category: AppCategory.system,
      );
      expect(base, equals(other));
    });

    test('different name makes objects unequal', () {
      final other = AppInfoUIModel(
        name: 'Other',
        description: 'desc',
        link: '/app',
        version: '1.0',
        iconData: Icons.apps,
        color: Colors.blueAccent,
        category: AppCategory.system,
      );
      expect(base, isNot(equals(other)));
    });

    test('different description but same props are equal', () {
      final other = AppInfoUIModel(
        name: 'App',
        description: 'DIFFERENT',
        link: '/app',
        version: '1.0',
        iconData: Icons.apps,
        color: Colors.blueAccent,
        category: AppCategory.system,
      );
      expect(base, equals(other));
    });

    test('different iconData but same props are equal', () {
      final other = AppInfoUIModel(
        name: 'App',
        description: 'desc',
        link: '/app',
        version: '1.0',
        iconData: Icons.wifi,
        color: Colors.blueAccent,
        category: AppCategory.system,
      );
      expect(base, equals(other));
    });

    test('different color but same props are equal', () {
      final other = AppInfoUIModel(
        name: 'App',
        description: 'desc',
        link: '/app',
        version: '1.0',
        iconData: Icons.apps,
        color: Colors.redAccent,
        category: AppCategory.system,
      );
      expect(base, equals(other));
    });
  });
}
