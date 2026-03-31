import 'package:privacy_gui/page/apps/models/app_event.dart';
import 'package:test/test.dart';

void main() {
  // -----------------------------------------------------------------------
  // fromJson
  // -----------------------------------------------------------------------
  group('fromJson', () {
    test('parses installed event', () {
      final event = AppEvent.fromJson({
        'event': 'installed',
        'app': {'name': 'wireguard'},
        'timestamp': 1711800000,
      });
      expect(event.type, AppEventType.installed);
      expect(event.appName, 'wireguard');
      expect(event.timestamp, 1711800000);
    });

    test('parses removed event', () {
      final event = AppEvent.fromJson({
        'event': 'removed',
        'app': {'name': 'adguard'},
        'timestamp': 1711800100,
      });
      expect(event.type, AppEventType.removed);
      expect(event.appName, 'adguard');
    });

    test('parses updated event', () {
      final event = AppEvent.fromJson({
        'event': 'updated',
        'app': {'name': 'pi-hole'},
        'timestamp': 1711800200,
      });
      expect(event.type, AppEventType.updated);
    });

    test('unknown event defaults to updated', () {
      final event = AppEvent.fromJson({
        'event': 'migrated',
        'app': {'name': 'test'},
        'timestamp': 0,
      });
      expect(event.type, AppEventType.updated);
    });

    test('null event defaults to updated', () {
      final event = AppEvent.fromJson({
        'app': {'name': 'test'},
        'timestamp': 0,
      });
      expect(event.type, AppEventType.updated);
    });

    test('extracts nested app.name', () {
      final event = AppEvent.fromJson({
        'event': 'installed',
        'app': {'name': 'wireguard', 'version': '1.0'},
        'timestamp': 0,
      });
      expect(event.appName, 'wireguard');
    });

    test('missing app object defaults to empty string', () {
      final event = AppEvent.fromJson({
        'event': 'installed',
        'timestamp': 100,
      });
      expect(event.appName, '');
    });

    test('missing timestamp defaults to 0', () {
      final event = AppEvent.fromJson({
        'event': 'installed',
        'app': {'name': 'test'},
      });
      expect(event.timestamp, 0);
    });
  });

  // -----------------------------------------------------------------------
  // Equatable
  // -----------------------------------------------------------------------
  group('Equatable', () {
    test('same type/appName/timestamp are equal', () {
      final a = AppEvent(
        type: AppEventType.installed,
        appName: 'wireguard',
        timestamp: 100,
      );
      final b = AppEvent(
        type: AppEventType.installed,
        appName: 'wireguard',
        timestamp: 100,
      );
      expect(a, equals(b));
    });

    test('different type makes objects unequal', () {
      final a = AppEvent(
        type: AppEventType.installed,
        appName: 'wireguard',
        timestamp: 100,
      );
      final b = AppEvent(
        type: AppEventType.removed,
        appName: 'wireguard',
        timestamp: 100,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
