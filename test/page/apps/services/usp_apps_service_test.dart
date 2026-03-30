import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:privacy_gui/page/apps/models/app_event.dart';
import 'package:privacy_gui/page/apps/models/app_info_ui_model.dart';
import 'package:privacy_gui/page/apps/services/usp_apps_service.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _base = 'http://test.local';

UspAppsService _svc(MockClient client) =>
    UspAppsService(client: client, baseUrl: _base);

http.Response _json200(Object body) =>
    http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json'});

http.Response _status(int code) => http.Response('', code);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -----------------------------------------------------------------------
  // fetchApps
  // -----------------------------------------------------------------------
  group('fetchApps', () {
    test('parses system and user apps', () async {
      final client = MockClient((_) async => _json200({
            'apps': [
              {
                'name': 'sys1',
                'description': 'System app',
                'link': '',
                'version': '1.0',
                'icon': 'settings',
                'color': 'blueAccent',
              }
            ],
            'userApps': [
              {
                'name': 'usr1',
                'description': 'User app',
                'link': '',
                'version': '2.0',
                'icon': 'wifi',
                'color': 'redAccent',
              }
            ],
          }));

      final apps = await _svc(client).fetchApps();

      expect(apps.length, 2);
      expect(apps[0].name, 'sys1');
      expect(apps[0].category, AppCategory.system);
      expect(apps[1].name, 'usr1');
      expect(apps[1].category, AppCategory.user);
    });

    test('empty apps array returns empty list', () async {
      final client =
          MockClient((_) async => _json200({'apps': [], 'userApps': []}));

      final apps = await _svc(client).fetchApps();
      expect(apps, isEmpty);
    });

    test('missing apps key returns empty list', () async {
      final client = MockClient((_) async => _json200({}));

      final apps = await _svc(client).fetchApps();
      expect(apps, isEmpty);
    });

    test('server returns object instead of array — treated as empty', () async {
      // lua edge case: empty list serialized as {}
      final client = MockClient(
          (_) async => _json200({'apps': {}, 'userApps': {}}));

      final apps = await _svc(client).fetchApps();
      expect(apps, isEmpty);
    });

    test('non-200 throws exception', () async {
      final client = MockClient((_) async => _status(404));

      expect(
        () => _svc(client).fetchApps(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('404'),
        )),
      );
    });

    test('requests correct URL', () async {
      Uri? captured;
      final client = MockClient((req) async {
        captured = req.url;
        return _json200({'apps': [], 'userApps': []});
      });

      await _svc(client).fetchApps();
      expect(captured.toString(), '$_base/api/apps.json');
    });
  });

  // -----------------------------------------------------------------------
  // _toModel (exercised via fetchApps)
  // -----------------------------------------------------------------------
  group('_toModel mapping', () {
    test('known icon name maps correctly', () async {
      final client = MockClient((_) async => _json200({
            'apps': [
              {
                'name': 'a',
                'description': '',
                'link': '',
                'version': '',
                'icon': 'security',
                'color': 'tealAccent',
              }
            ],
          }));

      final apps = await _svc(client).fetchApps();
      expect(apps.first.iconData, Icons.security);
      expect(apps.first.color, Colors.tealAccent);
    });

    test('unknown icon/color fall back to defaults', () async {
      final client = MockClient((_) async => _json200({
            'apps': [
              {
                'name': 'a',
                'description': '',
                'link': '',
                'version': '',
                'icon': 'nonexistent',
                'color': 'nonexistent',
              }
            ],
          }));

      final apps = await _svc(client).fetchApps();
      expect(apps.first.iconData, Icons.apps);
      expect(apps.first.color, Colors.blueAccent);
    });

    test('missing name defaults to Unknown', () async {
      final client = MockClient((_) async => _json200({
            'apps': [
              {
                'description': '',
                'link': '',
                'version': '',
                'icon': '',
                'color': '',
              }
            ],
          }));

      final apps = await _svc(client).fetchApps();
      expect(apps.first.name, 'Unknown');
    });

    test('missing optional fields default to empty string', () async {
      final client = MockClient((_) async => _json200({
            'apps': [
              {'name': 'a'}
            ],
          }));

      final apps = await _svc(client).fetchApps();
      expect(apps.first.description, '');
      expect(apps.first.version, '');
    });
  });

  // -----------------------------------------------------------------------
  // _normalizeLink (exercised via fetchApps)
  // -----------------------------------------------------------------------
  group('_normalizeLink', () {
    test('rebases IP link on baseUrl', () async {
      final client = MockClient((_) async => _json200({
            'apps': [
              {
                'name': 'a',
                'description': '',
                'link': '192.168.1.1/files/',
                'version': '',
                'icon': '',
                'color': '',
              }
            ],
          }));

      final apps = await _svc(client).fetchApps();
      expect(apps.first.link, '$_base/files/');
    });

    test('rebases full URL on baseUrl', () async {
      final client = MockClient((_) async => _json200({
            'apps': [
              {
                'name': 'a',
                'description': '',
                'link': 'http://192.168.1.1/admin',
                'version': '',
                'icon': '',
                'color': '',
              }
            ],
          }));

      final apps = await _svc(client).fetchApps();
      expect(apps.first.link, '$_base/admin');
    });

    test('empty link preserved as empty', () async {
      final client = MockClient((_) async => _json200({
            'apps': [
              {
                'name': 'a',
                'description': '',
                'link': '',
                'version': '',
                'icon': '',
                'color': '',
              }
            ],
          }));

      final apps = await _svc(client).fetchApps();
      expect(apps.first.link, '');
    });
  });

  // -----------------------------------------------------------------------
  // fetchLatestEvent
  // -----------------------------------------------------------------------
  group('fetchLatestEvent', () {
    test('parses valid event JSON', () async {
      final client = MockClient((_) async => _json200({
            'event': 'installed',
            'app': {'name': 'wireguard'},
            'timestamp': 1711800000,
          }));

      final event = await _svc(client).fetchLatestEvent();
      expect(event, isNotNull);
      expect(event!.type, AppEventType.installed);
      expect(event.appName, 'wireguard');
    });

    test('non-200 returns null', () async {
      final client = MockClient((_) async => _status(404));

      final event = await _svc(client).fetchLatestEvent();
      expect(event, isNull);
    });

    test('empty body returns null', () async {
      final client = MockClient(
          (_) async => http.Response('', 200));

      final event = await _svc(client).fetchLatestEvent();
      expect(event, isNull);
    });

    test('empty JSON object returns null', () async {
      final client = MockClient((_) async => _json200({}));

      final event = await _svc(client).fetchLatestEvent();
      expect(event, isNull);
    });

    test('network error returns null', () async {
      final client = MockClient((_) async => throw Exception('network'));

      final event = await _svc(client).fetchLatestEvent();
      expect(event, isNull);
    });
  });
}
