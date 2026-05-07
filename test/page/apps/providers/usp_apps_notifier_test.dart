import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/apps/models/app_info_ui_model.dart';
import 'package:privacy_gui/page/apps/providers/usp_apps_notifier.dart';
import 'package:privacy_gui/page/apps/services/usp_apps_service.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _MockAppsService extends Mock implements UspAppsService {}

AppInfoUIModel _app(String name) => AppInfoUIModel(
      name: name,
      description: '',
      link: '',
      version: '1.0',
      iconData: Icons.apps,
      color: Colors.blueAccent,
      category: AppCategory.system,
    );

/// Create a container with the mock service overridden.
ProviderContainer _container(_MockAppsService mock) {
  return ProviderContainer(overrides: [
    uspAppsServiceProvider.overrideWithValue(mock),
  ]);
}

/// Force provider build and wait for it to settle inside fakeAsync.
ProviderSubscription<AsyncValue<UspAppsState>> _listen(
    ProviderContainer container, FakeAsync async) {
  final sub = container.listen(uspAppsProvider, (_, __) {});
  async.elapse(Duration.zero);
  return sub;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockAppsService mock;

  setUp(() {
    mock = _MockAppsService();
  });

  group('initial load', () {
    test('populates apps from service', () async {
      when(() => mock.fetchApps())
          .thenAnswer((_) async => [_app('app1'), _app('app2')]);

      final container = _container(mock);
      addTearDown(container.dispose);

      final state = await container.read(uspAppsProvider.future);
      expect(state.apps.length, 2);
      expect(state.apps[0].name, 'app1');
    });

    test('first load has no NEW badges', () async {
      when(() => mock.fetchApps()).thenAnswer((_) async => [_app('app1')]);

      final container = _container(mock);
      addTearDown(container.dispose);

      final state = await container.read(uspAppsProvider.future);
      expect(state.recentlyInstalledNames, isEmpty);
      expect(state.isNew('app1'), isFalse);
    });

    test('service failure → AsyncError', () async {
      when(() => mock.fetchApps()).thenThrow(Exception('boom'));

      final container = _container(mock);
      addTearDown(container.dispose);

      final sub = container.listen(uspAppsProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      expect(sub.read(), isA<AsyncError>());
    });
  });

  group('polling', () {
    test('detects added app after 5s poll', () {
      fakeAsync((async) {
        when(() => mock.fetchApps()).thenAnswer((_) async => [_app('app1')]);

        final container = _container(mock);
        _listen(container, async);

        // Now service returns a new app
        when(() => mock.fetchApps())
            .thenAnswer((_) async => [_app('app1'), _app('newApp')]);

        // Advance past the 5s poll interval
        async.elapse(Duration(seconds: 6));

        final state = container.read(uspAppsProvider).valueOrNull;
        expect(state, isNotNull);
        expect(state!.apps.length, 2);
        expect(state.isNew('newApp'), isTrue);

        container.dispose();
      });
    });

    test('detects removed app after poll', () {
      fakeAsync((async) {
        when(() => mock.fetchApps())
            .thenAnswer((_) async => [_app('app1'), _app('app2')]);

        final container = _container(mock);
        _listen(container, async);

        // app2 removed
        when(() => mock.fetchApps()).thenAnswer((_) async => [_app('app1')]);

        async.elapse(Duration(seconds: 6));

        final state = container.read(uspAppsProvider).valueOrNull;
        expect(state, isNotNull);
        expect(state!.apps.length, 1);
        expect(state.apps.first.name, 'app1');

        container.dispose();
      });
    });

    test('no change → no state update', () {
      fakeAsync((async) {
        final apps = [_app('app1')];
        when(() => mock.fetchApps()).thenAnswer((_) async => apps);

        final container = _container(mock);
        _listen(container, async);

        var updateCount = 0;
        container.listen(uspAppsProvider, (_, __) => updateCount++);

        // Poll with same data
        async.elapse(Duration(seconds: 6));

        // No extra state emissions expected (same app names)
        expect(updateCount, 0);

        container.dispose();
      });
    });

    test('poll failure is non-fatal', () {
      fakeAsync((async) {
        when(() => mock.fetchApps()).thenAnswer((_) async => [_app('app1')]);

        final container = _container(mock);
        _listen(container, async);

        // Service starts failing
        when(() => mock.fetchApps()).thenThrow(Exception('network'));

        async.elapse(Duration(seconds: 6));

        // State should still be the initial data — not an error
        final state = container.read(uspAppsProvider).valueOrNull;
        expect(state, isNotNull);
        expect(state!.apps.length, 1);

        container.dispose();
      });
    });
  });

  group('NEW badge auto-clear', () {
    test('badge clears after 60s', () {
      fakeAsync((async) {
        when(() => mock.fetchApps()).thenAnswer((_) async => [_app('app1')]);

        final container = _container(mock);
        _listen(container, async);

        // Add new app at first poll
        when(() => mock.fetchApps())
            .thenAnswer((_) async => [_app('app1'), _app('newApp')]);

        async.elapse(Duration(seconds: 6));

        // Badge should be set
        var state = container.read(uspAppsProvider).valueOrNull;
        expect(state!.isNew('newApp'), isTrue);

        // Advance 60 more seconds for auto-clear
        async.elapse(Duration(seconds: 60));

        state = container.read(uspAppsProvider).valueOrNull;
        expect(state!.isNew('newApp'), isFalse);

        container.dispose();
      });
    });
  });

  group('lifecycle', () {
    test('timer cancelled on dispose', () {
      fakeAsync((async) {
        when(() => mock.fetchApps()).thenAnswer((_) async => [_app('app1')]);

        final container = _container(mock);
        _listen(container, async);

        // fetchApps called once for initial build
        verify(() => mock.fetchApps()).called(1);

        container.dispose();

        // Advance time — timer should NOT fire after dispose
        async.elapse(Duration(seconds: 10));

        // Still only the 1 call from build — no poll calls after dispose
        verifyNever(() => mock.fetchApps());
      });
    });
  });
}
