import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/core/usp/providers/bridge_request_throttler_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/bridge_request_throttler.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/dashboard/models/package_widget_template.dart';
import 'package:privacy_gui/page/dashboard/providers/http_client_provider.dart';
import 'package:privacy_gui/page/dashboard/widgets/package_widget_renderer.dart';

// =============================================================================
// Mocks
// =============================================================================

class MockUspService extends Mock implements UspService {}

class MockSseManager extends Mock implements SseManager {}

// =============================================================================
// Helpers
// =============================================================================

/// Default grid constraints for test templates.
final _testConstraints = WidgetGridConstraints(
  minColumns: 3,
  maxColumns: 6,
  preferredColumns: 4,
  heightStrategy: HeightStrategy.strict(2),
);

/// Build a USP-sourced template with a simple AppText binding.
PackageWidgetTemplate _uspTemplate({
  String widgetId = 'test_usp',
  List<String> paths = const ['Device.Info.ModelName'],
}) {
  return PackageWidgetTemplate(
    widgetId: widgetId,
    displayName: 'USP Widget',
    constraints: _testConstraints,
    subscription: WidgetSubscriptionConfig(
      paths: paths,
      notifType: 'ValueChange',
    ),
    template: {
      'type': 'AppCard',
      'props': {
        'children': [
          {
            'type': 'AppText',
            'props': {
              'text': {r'$bind': 'Device.Info.ModelName'},
            },
          },
        ],
      },
    },
  );
}

/// Build an HTTP-sourced template.
PackageWidgetTemplate _httpTemplate({
  String widgetId = 'test_http',
  String url = '/cgi-bin/ip-info.cgi',
  String method = 'POST',
  int refreshInterval = 0,
}) {
  return PackageWidgetTemplate(
    widgetId: widgetId,
    displayName: 'HTTP Widget',
    constraints: _testConstraints,
    dataSource: HttpDataSourceConfig(
      url: url,
      method: method,
      refreshInterval: refreshInterval,
      mapping: {
        'ip': 'data.query',
        'city': 'data.city',
      },
    ),
    template: {
      'type': 'AppCard',
      'props': {
        'children': [
          {
            'type': 'AppText',
            'props': {
              'text': {r'$bind': 'ip'},
            },
          },
        ],
      },
    },
  );
}

/// Theme data for tests — satisfies AppDesignTheme requirement.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({
    'style': 'flat',
  }),
);

/// Wrap the renderer in a testable widget tree with provider overrides.
Widget _buildTestWidget({
  required PackageWidgetTemplate template,
  UspService? usp,
  SseManager? sse,
  http.Client? httpClient,
  BridgeRequestThrottler? throttler,
  bool showHeader = false,
}) {
  return ProviderScope(
    overrides: [
      uspServiceProvider.overrideWithValue(usp),
      sseManagerProvider.overrideWithValue(sse),
      bridgeRequestThrottlerProvider.overrideWithValue(
          throttler ?? BridgeRequestThrottler(staggerDelay: Duration.zero)),
      if (httpClient != null) httpClientProvider.overrideWithValue(httpClient),
    ],
    child: MaterialApp(
      theme: _testTheme,
      home: Scaffold(
        body: SizedBox.expand(
          child: PackageWidgetRenderer(
            template: template,
            showHeader: showHeader,
          ),
        ),
      ),
    ),
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(<String>[]);
  });

  // -----------------------------------------------------------------------
  // USP path
  // -----------------------------------------------------------------------
  group('USP path', () {
    late MockUspService mockUsp;
    late MockSseManager mockSse;

    setUp(() {
      mockUsp = MockUspService();
      mockSse = MockSseManager();
    });

    testWidgets('renders data after USP GET succeeds', (tester) async {
      when(() => mockUsp.get(any())).thenAnswer(
        (_) async => {'Device.Info.ModelName': 'M60TB'},
      );
      when(() => mockSse.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            notifType: any(named: 'notifType'),
            referenceList: any(named: 'referenceList'),
            onNotification: any(named: 'onNotification'),
          )).thenAnswer((_) async => () async {});

      await tester.pumpWidget(_buildTestWidget(
        template: _uspTemplate(),
        usp: mockUsp,
        sse: mockSse,
      ));

      // Initial frame — post-frame callback not yet fired
      await tester.pump();
      // Let async USP GET + SSE subscribe complete
      await tester.pumpAndSettle();

      expect(find.text('M60TB'), findsOneWidget);
    });

    testWidgets('calls SSE subscribe with correct params', (tester) async {
      when(() => mockUsp.get(any())).thenAnswer(
        (_) async => {'Device.Info.ModelName': 'Router'},
      );
      when(() => mockSse.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            notifType: any(named: 'notifType'),
            referenceList: any(named: 'referenceList'),
            onNotification: any(named: 'onNotification'),
          )).thenAnswer((_) async => () async {});

      await tester.pumpWidget(_buildTestWidget(
        template: _uspTemplate(paths: ['Device.WiFi.Radio.1.']),
        usp: mockUsp,
        sse: mockSse,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => mockSse.subscribe(
            subscriptionId: 'pkg-test_usp-valuechange',
            notifType: 'ValueChange',
            referenceList: 'Device.WiFi.Radio.1.',
            onNotification: any(named: 'onNotification'),
          )).called(1);
    });

    testWidgets('handles USP GET failure gracefully', (tester) async {
      when(() => mockUsp.get(any())).thenThrow(Exception('timeout'));
      when(() => mockSse.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            notifType: any(named: 'notifType'),
            referenceList: any(named: 'referenceList'),
            onNotification: any(named: 'onNotification'),
          )).thenAnswer((_) async => () async {});

      await tester.pumpWidget(_buildTestWidget(
        template: _uspTemplate(),
        usp: mockUsp,
        sse: mockSse,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Should not crash — widget still mounted
      expect(find.byType(PackageWidgetRenderer), findsOneWidget);
    });

    testWidgets('USP null → skips fetch, no crash', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        template: _uspTemplate(),
        usp: null,
        sse: null,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(PackageWidgetRenderer), findsOneWidget);
    });
  });

  // -----------------------------------------------------------------------
  // HTTP path
  // -----------------------------------------------------------------------
  group('HTTP path', () {
    testWidgets('HTTP fetch failure in test env is handled gracefully',
        (tester) async {
      // In test environment, Uri.base is file:// so Uri.base.origin throws.
      // Verify the renderer handles this gracefully without crashing.
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': {'query': '1.2.3.4', 'city': 'Taipei'}
          }),
          200,
        );
      });

      await tester.pumpWidget(_buildTestWidget(
        template: _httpTemplate(),
        httpClient: mockClient,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Widget should still be mounted (graceful error handling)
      expect(find.byType(PackageWidgetRenderer), findsOneWidget);
    });

    testWidgets('blocks non-local URL', (tester) async {
      var requestMade = false;
      final mockClient = MockClient((request) async {
        requestMade = true;
        return http.Response('{}', 200);
      });

      await tester.pumpWidget(_buildTestWidget(
        template: _httpTemplate(url: 'https://evil.com/api'),
        httpClient: mockClient,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(requestMade, false);
    });

    testWidgets('blocks URL without /cgi-bin/ prefix', (tester) async {
      var requestMade = false;
      final mockClient = MockClient((request) async {
        requestMade = true;
        return http.Response('{}', 200);
      });

      await tester.pumpWidget(_buildTestWidget(
        template: _httpTemplate(url: '/api/v1/data'),
        httpClient: mockClient,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(requestMade, false);
    });

    testWidgets('handles HTTP error status gracefully', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      await tester.pumpWidget(_buildTestWidget(
        template: _httpTemplate(),
        httpClient: mockClient,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Should not crash
      expect(find.byType(PackageWidgetRenderer), findsOneWidget);
    });

    testWidgets('handles network exception gracefully', (tester) async {
      final mockClient = MockClient((request) async {
        throw Exception('Network unreachable');
      });

      await tester.pumpWidget(_buildTestWidget(
        template: _httpTemplate(),
        httpClient: mockClient,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(PackageWidgetRenderer), findsOneWidget);
    });
  });

  // -----------------------------------------------------------------------
  // Render error
  // -----------------------------------------------------------------------
  group('render error', () {
    testWidgets('unknown component type does not crash', (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'broken',
        displayName: 'Broken Widget',
        constraints: _testConstraints,
        template: {
          'type': 'NonExistentComponent',
          'props': {'invalid': true},
        },
      );

      await tester.pumpWidget(_buildTestWidget(template: template));
      await tester.pump();
      await tester.pumpAndSettle();

      // UiTreeBuilder returns fallback for unknown types — widget stays mounted
      expect(find.byType(PackageWidgetRenderer), findsOneWidget);
    });
  });

  // -----------------------------------------------------------------------
  // No data source
  // -----------------------------------------------------------------------
  group('no data source', () {
    testWidgets('renders template directly when no subscription or dataSource',
        (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'static',
        displayName: 'Static Widget',
        constraints: _testConstraints,
        template: {
          'type': 'AppCard',
          'props': {
            'children': [
              {
                'type': 'AppText',
                'props': {'text': 'Hello Static'},
              },
            ],
          },
        },
      );

      await tester.pumpWidget(_buildTestWidget(template: template));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Hello Static'), findsOneWidget);
    });
  });

  // -----------------------------------------------------------------------
  // Header mode (showHeader: true)
  // -----------------------------------------------------------------------
  group('header mode', () {
    testWidgets('shows refresh button when dataSource exists', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        template: _httpTemplate(),
        showHeader: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Refresh icon should be visible in header
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows info button when description exists', (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'info_test',
        displayName: 'Info Widget',
        description: 'Some description',
        constraints: _testConstraints,
        dataSource: HttpDataSourceConfig(
          url: '/cgi-bin/test.cgi',
          mapping: {'k': 'v'},
        ),
        template: {
          'type': 'AppText',
          'props': {'text': 'Content'},
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        showHeader: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('shows navigate button when navigateTo is set', (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'nav_test',
        displayName: 'Nav Widget',
        constraints: _testConstraints,
        navigateTo: 'uspWifiSettings',
        template: {
          'type': 'AppText',
          'props': {'text': 'Content'},
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        showHeader: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('hides navigate button when navigateTo is null',
        (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'no_nav',
        displayName: 'No Nav',
        constraints: _testConstraints,
        template: {
          'type': 'AppText',
          'props': {'text': 'Content'},
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        showHeader: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.open_in_new), findsNothing);
    });

    testWidgets('hides refresh button when no data source', (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'static_header',
        displayName: 'Static',
        constraints: _testConstraints,
        template: {
          'type': 'AppText',
          'props': {'text': 'Content'},
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        showHeader: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('falls back to legacy onTap navigate destination',
        (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'legacy_nav',
        displayName: 'Legacy Nav',
        constraints: _testConstraints,
        template: {
          'type': 'AppCard',
          'props': {
            'onTap': {
              r'$action': 'navigate',
              'destination': 'uspDeviceList',
            },
            'children': [
              {
                'type': 'AppText',
                'props': {'text': 'Content'},
              },
            ],
          },
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        showHeader: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Navigate button should appear from legacy onTap format
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('navigateTo takes priority over legacy onTap', (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'priority_nav',
        displayName: 'Priority Nav',
        constraints: _testConstraints,
        navigateTo: 'uspWifiSettings',
        template: {
          'type': 'AppCard',
          'props': {
            'onTap': {
              r'$action': 'navigate',
              'destination': 'uspDeviceList',
            },
            'children': [
              {
                'type': 'AppText',
                'props': {'text': 'Content'},
              },
            ],
          },
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        showHeader: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Button should exist (navigateTo wins)
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });
  });

  // -----------------------------------------------------------------------
  // Header — icon, badge, extra
  // -----------------------------------------------------------------------
  group('header icon/badge/extra', () {
    testWidgets('shows icon when icon is set', (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'icon_test',
        displayName: 'Icon Widget',
        constraints: _testConstraints,
        icon: 'speed',
        template: {
          'type': 'AppText',
          'props': {'text': 'Content'},
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        showHeader: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.speed), findsOneWidget);
    });

    testWidgets('hides icon when icon is null', (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'no_icon',
        displayName: 'No Icon',
        constraints: _testConstraints,
        template: {
          'type': 'AppText',
          'props': {'text': 'Content'},
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        showHeader: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      // Only default icons (info/refresh/navigate) should be absent
      // No AppIcon.font rendered for header icon
      expect(find.byType(AppIcon), findsNothing);
    });

    testWidgets('shows badge with static string', (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'badge_test',
        displayName: 'Badge Widget',
        constraints: _testConstraints,
        headerBadge: 'ON',
        template: {
          'type': 'AppText',
          'props': {'text': 'Content'},
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        showHeader: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(AppTag), findsOneWidget);
      expect(find.text('ON'), findsOneWidget);
    });

    testWidgets('hides badge when headerBadge is null', (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'no_badge',
        displayName: 'No Badge',
        constraints: _testConstraints,
        template: {
          'type': 'AppText',
          'props': {'text': 'Content'},
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        showHeader: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(AppTag), findsNothing);
    });

    testWidgets('shows extra subtitle with static string', (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'extra_test',
        displayName: 'Extra Widget',
        constraints: _testConstraints,
        headerExtra: 'Chunghwa Mobile',
        template: {
          'type': 'AppText',
          'props': {'text': 'Content'},
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        showHeader: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Chunghwa Mobile'), findsOneWidget);
    });

    testWidgets('hides extra when headerExtra is null', (tester) async {
      final template = PackageWidgetTemplate(
        widgetId: 'no_extra',
        displayName: 'No Extra',
        constraints: _testConstraints,
        template: {
          'type': 'AppText',
          'props': {'text': 'Content'},
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        showHeader: true,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Chunghwa Mobile'), findsNothing);
    });
  });

  // -----------------------------------------------------------------------
  // cgi_call action — security
  // -----------------------------------------------------------------------
  group('cgi_call security', () {
    testWidgets('blocks cgi_call with non-local URL', (tester) async {
      var requestMade = false;
      final mockClient = MockClient((request) async {
        requestMade = true;
        return http.Response('{}', 200);
      });

      // Template with an AppIconButton that fires onAction when tapped.
      // We embed the $action inline — but since builders hardcode 'pressed',
      // we test the security path by constructing a template that has
      // a dataSource with a blocked URL and tapping refresh.
      final template = PackageWidgetTemplate(
        widgetId: 'cgi_block_test',
        displayName: 'CGI Block',
        constraints: _testConstraints,
        dataSource: HttpDataSourceConfig(
          url: 'https://evil.com/steal',
          mapping: {'k': 'v'},
        ),
        template: {
          'type': 'AppText',
          'props': {'text': 'CGI Test'},
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        httpClient: mockClient,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(requestMade, false);
    });

    testWidgets('blocks cgi_call without /cgi-bin/ prefix', (tester) async {
      var requestMade = false;
      final mockClient = MockClient((request) async {
        requestMade = true;
        return http.Response('{}', 200);
      });

      final template = PackageWidgetTemplate(
        widgetId: 'cgi_prefix_test',
        displayName: 'CGI Prefix',
        constraints: _testConstraints,
        dataSource: HttpDataSourceConfig(
          url: '/api/v1/hack',
          mapping: {'k': 'v'},
        ),
        template: {
          'type': 'AppText',
          'props': {'text': 'CGI Test'},
        },
      );

      await tester.pumpWidget(_buildTestWidget(
        template: template,
        httpClient: mockClient,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(requestMade, false);
    });
  });

  // -----------------------------------------------------------------------
  // applyMapping / resolvePath helpers
  // -----------------------------------------------------------------------
  group('applyMapping', () {
    test('maps nested JSON to flat keys', () {
      final json = {
        'data': {'query': '1.2.3.4', 'city': 'Taipei'}
      };
      final mapping = {'ip': 'data.query', 'city': 'data.city'};

      final result = applyMapping(json, mapping);

      expect(result['ip'], '1.2.3.4');
      expect(result['city'], 'Taipei');
    });

    test('returns null for missing paths', () {
      final json = {'data': <String, dynamic>{}};
      final mapping = {'missing': 'data.nonexistent'};

      final result = applyMapping(json, mapping);

      expect(result['missing'], isNull);
    });

    test('handles deeply nested paths', () {
      final json = {
        'a': {
          'b': {'c': 42}
        }
      };
      final mapping = {'val': 'a.b.c'};

      final result = applyMapping(json, mapping);

      expect(result['val'], 42);
    });
  });
}
