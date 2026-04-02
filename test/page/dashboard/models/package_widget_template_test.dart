import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/package_widget_template.dart';
import 'package:test/test.dart';

void main() {
  // -----------------------------------------------------------------------
  // PackageWidgetTemplate.fromJson
  // -----------------------------------------------------------------------
  group('PackageWidgetTemplate.fromJson', () {
    test('parses full JSON with subscription', () {
      final json = {
        'widgetId': 'mem_usage',
        'displayName': 'Memory Usage',
        'description': 'Shows memory stats',
        'constraints': {
          'minColumns': 2,
          'maxColumns': 8,
          'preferredColumns': 4,
          'preferredRows': 3,
          'minRows': 1,
          'maxRows': 4,
        },
        'subscription': {
          'paths': [
            'Device.DeviceInfo.MemoryStatus.Total',
            'Device.DeviceInfo.MemoryStatus.Free',
          ],
          'notifType': 'ValueChange',
        },
        'template': {
          'type': 'AppCard',
          'props': {'children': []},
        },
      };

      final t = PackageWidgetTemplate.fromJson(json);

      expect(t.widgetId, 'mem_usage');
      expect(t.displayName, 'Memory Usage');
      expect(t.description, 'Shows memory stats');
      expect(t.constraints.minColumns, 2);
      expect(t.constraints.maxColumns, 8);
      expect(t.constraints.preferredColumns, 4);
      expect(t.constraints.minHeightRows, 1);
      expect(t.constraints.maxHeightRows, 4);
      expect(t.constraints.heightStrategy, isA<ColumnBasedHeightStrategy>());
      expect(t.subscription, isNotNull);
      expect(t.subscription!.paths.length, 2);
      expect(t.subscription!.notifType, 'ValueChange');
      expect(t.dataSource, isNull);
      expect(t.template['type'], 'AppCard');
    });

    test('parses full JSON with dataSource', () {
      final json = {
        'widgetId': 'ip_card',
        'displayName': 'My IP',
        'constraints': {
          'minColumns': 3,
          'maxColumns': 6,
          'preferredColumns': 4,
        },
        'dataSource': {
          'type': 'http',
          'url': '/cgi-bin/ip-info.cgi',
          'method': 'POST',
          'body': {'action': 'getInfo'},
          'refreshInterval': 60,
          'mapping': {
            'ip': 'data.query',
            'city': 'data.city',
          },
        },
        'template': {'type': 'AppText'},
      };

      final t = PackageWidgetTemplate.fromJson(json);

      expect(t.widgetId, 'ip_card');
      expect(t.subscription, isNull);
      expect(t.dataSource, isNotNull);
      expect(t.dataSource!.type, 'http');
      expect(t.dataSource!.url, '/cgi-bin/ip-info.cgi');
      expect(t.dataSource!.method, 'POST');
      expect(t.dataSource!.body, {'action': 'getInfo'});
      expect(t.dataSource!.refreshInterval, 60);
      expect(t.dataSource!.mapping, {'ip': 'data.query', 'city': 'data.city'});
    });

    test('applies defaults for minimal JSON', () {
      final json = {
        'widgetId': 'minimal',
        'template': {'type': 'AppCard'},
      };

      final t = PackageWidgetTemplate.fromJson(json);

      expect(t.widgetId, 'minimal');
      expect(t.displayName, 'Package Widget'); // default
      expect(t.description, isNull);
      expect(t.constraints.minColumns, 3); // default
      expect(t.constraints.maxColumns, 6); // default
      expect(t.constraints.preferredColumns, 4); // default
      expect(t.constraints.minHeightRows, 1); // default
      expect(t.constraints.maxHeightRows, 6); // default
      expect(t.subscription, isNull);
      expect(t.dataSource, isNull);
    });

    test('handles missing constraints with defaults', () {
      final json = {
        'widgetId': 'no_constraints',
        'template': <String, dynamic>{},
      };

      final t = PackageWidgetTemplate.fromJson(json);

      expect(t.constraints.minColumns, 3);
      expect(t.constraints.maxColumns, 6);
      expect(t.constraints.preferredColumns, 4);
    });

    test('parses both subscription and dataSource when present', () {
      final json = {
        'widgetId': 'both',
        'subscription': {
          'paths': ['Device.Info.X'],
          'notifType': 'ObjectCreation',
        },
        'dataSource': {
          'url': '/cgi-bin/test.cgi',
          'mapping': {'k': 'v'},
        },
        'template': <String, dynamic>{},
      };

      final t = PackageWidgetTemplate.fromJson(json);

      expect(t.subscription, isNotNull);
      expect(t.dataSource, isNotNull);
    });

    test('handles null template gracefully', () {
      final json = {
        'widgetId': 'no_tpl',
      };

      final t = PackageWidgetTemplate.fromJson(json);
      expect(t.template, isEmpty);
    });

    test('parses navigateTo field', () {
      final json = {
        'widgetId': 'nav_widget',
        'displayName': 'Nav Widget',
        'navigateTo': 'uspWifiSettings',
        'template': {'type': 'AppCard'},
      };

      final t = PackageWidgetTemplate.fromJson(json);
      expect(t.navigateTo, 'uspWifiSettings');
    });

    test('navigateTo defaults to null when absent', () {
      final json = {
        'widgetId': 'no_nav',
        'template': {'type': 'AppCard'},
      };

      final t = PackageWidgetTemplate.fromJson(json);
      expect(t.navigateTo, isNull);
    });

    test('parses icon and iconColor', () {
      final json = {
        'widgetId': 'icon_widget',
        'icon': 'speed',
        'iconColor': '#4FC3F7',
        'template': {'type': 'AppCard'},
      };

      final t = PackageWidgetTemplate.fromJson(json);
      expect(t.icon, 'speed');
      expect(t.iconColor, '#4FC3F7');
    });

    test('parses headerBadge as String', () {
      final json = {
        'widgetId': 'badge_str',
        'headerBadge': 'ON',
        'template': {'type': 'AppCard'},
      };

      final t = PackageWidgetTemplate.fromJson(json);
      expect(t.headerBadge, 'ON');
    });

    test('parses headerBadge as Map (\$bind)', () {
      final json = {
        'widgetId': 'badge_bind',
        'headerBadge': {r'$bind': 'status'},
        'template': {'type': 'AppCard'},
      };

      final t = PackageWidgetTemplate.fromJson(json);
      expect(t.headerBadge, isA<Map>());
      expect((t.headerBadge as Map)[r'$bind'], 'status');
    });

    test('parses headerExtra as String', () {
      final json = {
        'widgetId': 'extra_str',
        'headerExtra': 'Chunghwa Mobile',
        'template': {'type': 'AppCard'},
      };

      final t = PackageWidgetTemplate.fromJson(json);
      expect(t.headerExtra, 'Chunghwa Mobile');
    });

    test('parses headerExtra as Map (\$bind)', () {
      final json = {
        'widgetId': 'extra_bind',
        'headerExtra': {r'$bind': 'isp'},
        'template': {'type': 'AppCard'},
      };

      final t = PackageWidgetTemplate.fromJson(json);
      expect(t.headerExtra, isA<Map>());
    });

    test('icon/iconColor/headerBadge/headerExtra default to null', () {
      final json = {
        'widgetId': 'defaults',
        'template': {'type': 'AppCard'},
      };

      final t = PackageWidgetTemplate.fromJson(json);
      expect(t.icon, isNull);
      expect(t.iconColor, isNull);
      expect(t.headerBadge, isNull);
      expect(t.headerExtra, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // HttpDataSourceConfig.fromJson
  // -----------------------------------------------------------------------
  group('HttpDataSourceConfig.fromJson', () {
    test('parses full JSON', () {
      final json = {
        'type': 'http',
        'url': '/cgi-bin/speed.cgi',
        'method': 'GET',
        'body': {'test': true},
        'refreshInterval': 30,
        'mapping': {'speed': 'result.download'},
      };

      final ds = HttpDataSourceConfig.fromJson(json);

      expect(ds.type, 'http');
      expect(ds.url, '/cgi-bin/speed.cgi');
      expect(ds.method, 'GET');
      expect(ds.body, {'test': true});
      expect(ds.refreshInterval, 30);
      expect(ds.mapping, {'speed': 'result.download'});
    });

    test('applies defaults', () {
      final json = {
        'url': '/cgi-bin/info.cgi',
        'mapping': {'ip': 'data.ip'},
      };

      final ds = HttpDataSourceConfig.fromJson(json);

      expect(ds.type, 'http'); // default
      expect(ds.method, 'POST'); // default
      expect(ds.refreshInterval, 0); // default
      expect(ds.body, isNull);
    });

    test('parses GET with no body', () {
      final json = {
        'url': '/cgi-bin/status.cgi',
        'method': 'GET',
        'mapping': {'status': 'ok'},
      };

      final ds = HttpDataSourceConfig.fromJson(json);

      expect(ds.method, 'GET');
      expect(ds.body, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // WidgetSubscriptionConfig.fromJson
  // -----------------------------------------------------------------------
  group('WidgetSubscriptionConfig.fromJson', () {
    test('parses paths and notifType', () {
      final json = {
        'paths': ['Device.WiFi.Radio.1.Status', 'Device.WiFi.Radio.2.Status'],
        'notifType': 'ObjectCreation',
      };

      final sub = WidgetSubscriptionConfig.fromJson(json);

      expect(sub.paths, [
        'Device.WiFi.Radio.1.Status',
        'Device.WiFi.Radio.2.Status',
      ]);
      expect(sub.notifType, 'ObjectCreation');
    });

    test('defaults notifType to ValueChange', () {
      final json = {
        'paths': ['Device.Info.X'],
      };

      final sub = WidgetSubscriptionConfig.fromJson(json);

      expect(sub.notifType, 'ValueChange');
    });
  });

  // -----------------------------------------------------------------------
  // toWidgetSpec
  // -----------------------------------------------------------------------
  group('toWidgetSpec', () {
    test('converts to WidgetSpec correctly', () {
      final template = PackageWidgetTemplate(
        widgetId: 'test_widget',
        displayName: 'Test Widget',
        description: 'A test',
        constraints: WidgetGridConstraints(
          minColumns: 3,
          maxColumns: 6,
          preferredColumns: 4,
          heightStrategy: HeightStrategy.strict(2),
        ),
        template: {},
      );

      final spec = template.toWidgetSpec();

      expect(spec.id, 'test_widget');
      expect(spec.displayName, 'Test Widget');
      expect(spec.description, 'A test');
      expect(spec.canHide, true);
      expect(spec.constraints.containsKey(DisplayMode.normal), true);
      expect(spec.constraints[DisplayMode.normal]!.preferredColumns, 4);
    });

    test('defaultConstraints matches template constraints', () {
      final template = PackageWidgetTemplate(
        widgetId: 'w',
        displayName: 'W',
        constraints: WidgetGridConstraints(
          minColumns: 2,
          maxColumns: 12,
          preferredColumns: 6,
          heightStrategy: HeightStrategy.intrinsic(),
        ),
        template: {},
      );

      final spec = template.toWidgetSpec();

      expect(spec.defaultConstraints, template.constraints);
    });
  });

  // -----------------------------------------------------------------------
  // Equatable
  // -----------------------------------------------------------------------
  group('Equatable', () {
    test('same fields are equal', () {
      final a = PackageWidgetTemplate(
        widgetId: 'eq',
        displayName: 'Eq',
        constraints: WidgetGridConstraints(
          minColumns: 3,
          maxColumns: 6,
          preferredColumns: 4,
          heightStrategy: HeightStrategy.strict(2),
        ),
        template: {'type': 'AppCard'},
      );
      final b = PackageWidgetTemplate(
        widgetId: 'eq',
        displayName: 'Eq',
        constraints: WidgetGridConstraints(
          minColumns: 3,
          maxColumns: 6,
          preferredColumns: 4,
          heightStrategy: HeightStrategy.strict(2),
        ),
        template: {'type': 'AppCard'},
      );

      expect(a, equals(b));
    });

    test('different widgetId are not equal', () {
      final a = PackageWidgetTemplate(
        widgetId: 'a',
        displayName: 'X',
        constraints: WidgetGridConstraints(
          minColumns: 3,
          maxColumns: 6,
          preferredColumns: 4,
          heightStrategy: HeightStrategy.strict(2),
        ),
        template: {},
      );
      final b = PackageWidgetTemplate(
        widgetId: 'b',
        displayName: 'X',
        constraints: WidgetGridConstraints(
          minColumns: 3,
          maxColumns: 6,
          preferredColumns: 4,
          heightStrategy: HeightStrategy.strict(2),
        ),
        template: {},
      );

      expect(a, isNot(equals(b)));
    });

    test('HttpDataSourceConfig equality', () {
      final a = HttpDataSourceConfig(
        url: '/cgi-bin/test.cgi',
        mapping: {'k': 'v'},
      );
      final b = HttpDataSourceConfig(
        url: '/cgi-bin/test.cgi',
        mapping: {'k': 'v'},
      );

      expect(a, equals(b));
    });

    test('WidgetSubscriptionConfig equality', () {
      final a = WidgetSubscriptionConfig(
        paths: ['Device.X'],
        notifType: 'ValueChange',
      );
      final b = WidgetSubscriptionConfig(
        paths: ['Device.X'],
        notifType: 'ValueChange',
      );

      expect(a, equals(b));
    });
  });
}
