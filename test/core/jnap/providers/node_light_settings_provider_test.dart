// The node light (LED night mode) settings: the read, and the save the node
// detail page and the dashboard's quick panel make.
//
// What is pinned is what the read and the save end in (#1834 P0): what reaches
// the router and the settings they leave. Polling's own call to the read is
// not pinned here, as #1834 may remove it.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

import '../../../common/router_boundary.dart';

void main() {
  late RouterBoundary router;
  late ProviderContainer container;

  NodeLightSettingsNotifier notifier() =>
      container.read(nodeLightSettingsProvider.notifier);
  NodeLightSettings settings() => container.read(nodeLightSettingsProvider);

  /// Whether each read of the LED setting asked the router itself rather
  /// than the cache, oldest first.
  List<Object?> readsFromRouter() => verify(router.repo.send(
        JNAPAction.getLedNightModeSetting,
        data: anyNamed('data'),
        extraHeaders: anyNamed('extraHeaders'),
        auth: anyNamed('auth'),
        type: anyNamed('type'),
        fetchRemote: captureAnyNamed('fetchRemote'),
        cacheLevel: anyNamed('cacheLevel'),
        timeoutMs: anyNamed('timeoutMs'),
        retries: anyNamed('retries'),
        sideEffectOverrides: anyNamed('sideEffectOverrides'),
      )).captured;

  setUp(() {
    router = RouterBoundary();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  test('starts with the light on, before anything is read', () {
    expect(settings(), NodeLightSettings.on());
  });

  group('fetch', () {
    test('reads the night mode and its hours', () async {
      router.holds(JNAPAction.getLedNightModeSetting,
          {'Enable': true, 'StartingTime': 20, 'EndingTime': 8});

      final read = await notifier().fetch();

      expect(read, NodeLightSettings.night());
      expect(settings().isNightModeEnable, isTrue);
      expect((settings().startHour, settings().endHour), (20, 8));
      expect(readsFromRouter(), [false]);
    });

    test('reads a router that keeps the light off all day', () async {
      router.holds(JNAPAction.getLedNightModeSetting, {
        'Enable': true,
        'StartingTime': 0,
        'EndingTime': 24,
        'AllDayOff': true,
      });

      await notifier().fetch(true);

      expect(settings().allDayOff, isTrue);
      expect(settings().startHour, 0);
      expect(readsFromRouter(), [true]);
    });

    test('keeps the settings it had when the router refuses', () async {
      router.refuses(JNAPAction.getLedNightModeSetting);

      await expectLater(notifier().fetch(), throwsA(isA<JNAPError>()));

      expect(settings(), NodeLightSettings.on());
    });
  });

  group('save', () {
    test('writes night mode with its hours, then rereads the router', () async {
      router.holds(JNAPAction.getLedNightModeSetting,
          {'Enable': true, 'StartingTime': 20, 'EndingTime': 8});
      notifier().setSettings(NodeLightSettings.night());

      final saved = await notifier().save();

      expect(router.payloadsOf(JNAPAction.setLedNightModeSetting), [
        {'Enable': true, 'StartingTime': 20, 'EndingTime': 8}
      ]);
      expect(router.actions, [
        JNAPAction.setLedNightModeSetting,
        JNAPAction.getLedNightModeSetting,
      ]);
      expect(readsFromRouter(), [true]);
      expect(saved, NodeLightSettings.night());
    });

    test('writes the light on without hours', () async {
      router.holds(JNAPAction.getLedNightModeSetting, {'Enable': false});
      notifier().setSettings(NodeLightSettings.on());

      await notifier().save();

      expect(router.payloadsOf(JNAPAction.setLedNightModeSetting), [
        {'Enable': false}
      ]);
      expect(settings().isNightModeEnable, isFalse);
    });

    test('ends in what the router holds after the save', () async {
      // The router keeps its own hours for night mode.
      router.holds(JNAPAction.getLedNightModeSetting,
          {'Enable': true, 'StartingTime': 22, 'EndingTime': 6});
      notifier().setSettings(NodeLightSettings.night());

      await notifier().save();

      expect((settings().startHour, settings().endHour), (22, 6));
    });

    test('does not reread, and keeps the choice, when the router refuses',
        () async {
      router.refuses(JNAPAction.setLedNightModeSetting);
      notifier().setSettings(NodeLightSettings.off());

      await expectLater(notifier().save(), throwsA(isA<JNAPError>()));

      expect(router.actions, [JNAPAction.setLedNightModeSetting]);
      expect(settings(), NodeLightSettings.off());
    });
  });
}
