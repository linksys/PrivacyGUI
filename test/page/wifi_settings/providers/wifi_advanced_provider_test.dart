// Wi-Fi Settings' Advanced tab: the settings it reads and writes, each only
// on a router that supports it, against the router behind RouterRepository.
// What its save reports when the router drops off the network after the write
// is in wifi_save_side_effect_test.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';

import '../../../common/di.dart';
import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';

void main() {
  mockDependencyRegister();
  final services = serviceHelper as MockServiceHelper;

  late RouterBoundary router;
  late RecordingPolling polling;
  late ProviderContainer container;

  WifiAdvancedSettingsNotifier notifier() =>
      container.read(wifiAdvancedProvider.notifier);
  WifiAdvancedSettingsState page() => container.read(wifiAdvancedProvider);

  /// The router supports every Advanced setting unless told otherwise.
  void supports({
    bool topology = true,
    bool iptv = true,
    bool mlo = true,
    bool dfs = true,
    bool airtimeFairness = true,
  }) {
    when(services.isSupportTopologyOptimization()).thenReturn(topology);
    when(services.isSupportIPTv()).thenReturn(iptv);
    when(services.isSupportMLO()).thenReturn(mlo);
    when(services.isSupportDFS()).thenReturn(dfs);
    when(services.isSupportAirtimeFairness()).thenReturn(airtimeFairness);
  }

  setUp(() {
    supports();
    router = RouterBoundary()
      ..holds(JNAPAction.getTopologyOptimizationSettings, {
        'isClientSteeringEnabled': true,
        'isNodeSteeringEnabled': false,
      })
      ..holds(JNAPAction.getIptvSettings, {'isEnabled': false})
      ..holds(JNAPAction.getMLOSettings,
          {'isMLOSupported': true, 'isMLOEnabled': true})
      ..holds(JNAPAction.getDFSSettings,
          {'isDFSSupported': true, 'isDFSEnabled': false})
      ..holds(JNAPAction.getAirtimeFairnessSettings, {
        'isAirtimeFairnessSupported': true,
        'isAirtimeFairnessEnabled': true
      });
    polling = RecordingPolling();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => polling),
    ]);
  });

  tearDown(() {
    container.dispose();
    reset(services);
  });

  group('fetch', () {
    test('reads every setting the router supports, in one transaction',
        () async {
      await notifier().fetch();

      expect(router.transactions.single.map((command) => command.key), [
        JNAPAction.getTopologyOptimizationSettings,
        JNAPAction.getIptvSettings,
        JNAPAction.getMLOSettings,
        JNAPAction.getDFSSettings,
        JNAPAction.getAirtimeFairnessSettings,
      ]);
    });

    test('asks for none the router does not support', () async {
      supports(
          topology: false, iptv: false, mlo: false, airtimeFairness: false);

      await notifier().fetch();

      expect(router.actions, [JNAPAction.getDFSSettings]);
      expect(page(), const WifiAdvancedSettingsState(isDFSEnabled: false));
    });

    test('shows each setting as the router holds it', () async {
      final fetched = await notifier().fetch();

      expect(
        fetched,
        const WifiAdvancedSettingsState(
          isClientSteeringEnabled: true,
          isNodesSteeringEnabled: false,
          isIptvEnabled: false,
          isMLOEnabled: true,
          isDFSEnabled: false,
          isAirtimeFairnessEnabled: true,
        ),
      );
      expect(page(), same(fetched));
    });

    test('shows no MLO, DFS or airtime fairness the router says it lacks',
        () async {
      router
        ..holds(JNAPAction.getMLOSettings,
            {'isMLOSupported': false, 'isMLOEnabled': true})
        ..holds(JNAPAction.getDFSSettings,
            {'isDFSSupported': false, 'isDFSEnabled': true})
        ..holds(JNAPAction.getAirtimeFairnessSettings, {
          'isAirtimeFairnessSupported': false,
          'isAirtimeFairnessEnabled': true,
        });

      await notifier().fetch();

      expect(page().isMLOEnabled, isNull);
      expect(page().isDFSEnabled, isNull);
      expect(page().isAirtimeFairnessEnabled, isNull);
      expect(page().isClientSteeringEnabled, isTrue);
    });

    test('a forced fetch skips the cache', () async {
      await notifier().fetch(true);

      verify(router.repo.transaction(any, fetchRemote: true)).called(1);
    });

    test('a refused read reaches the caller and leaves the page as it was',
        () async {
      final before = page();
      router.refuses(JNAPAction.getDFSSettings);

      await expectLater(notifier().fetch(), throwsA(isA<JNAPError>()));

      expect(page(), same(before));
    });
  });

  group('save', () {
    setUp(() => notifier().fetch());

    test('writes each setting the page holds, in one transaction', () async {
      notifier()
        ..setClientSteeringEnabled(false)
        ..setNodesSteeringEnabled(true)
        ..setIptvEnabled(true)
        ..setMLOEnabled(false)
        ..setDFSEnabled(true)
        ..setAirtimeFairnessEnabled(false);
      router.transactions.clear();

      await notifier().save();

      expect(
          router.transactions.first,
          [
            const MapEntry(JNAPAction.setTopologyOptimizationSettings, {
              'isClientSteeringEnabled': false,
              'isNodeSteeringEnabled': true
            }),
            const MapEntry(JNAPAction.setIptvSettings, {'isEnabled': true}),
            const MapEntry(JNAPAction.setMLOSettings, {'isMLOEnabled': false}),
            const MapEntry(JNAPAction.setDFSSettings, {'isDFSEnabled': true}),
            const MapEntry(JNAPAction.setAirtimeFairnessSettings,
                {'isAirtimeFairnessEnabled': false}),
          ].map((entry) => isA<MapEntry>()
              .having((e) => e.key, 'action', entry.key)
              .having((e) => e.value, 'payload', entry.value)));
    });

    test('writes nothing for a setting the router does not support', () async {
      supports(
          topology: false, iptv: false, mlo: false, airtimeFairness: false);
      router.transactions.clear();

      await notifier().save();

      expect(router.transactions.first.map((command) => command.key),
          [JNAPAction.setDFSSettings]);
    });

    test('writes no MLO, DFS or airtime fairness it never read', () async {
      router
        ..holds(JNAPAction.getMLOSettings, {'isMLOSupported': false})
        ..holds(JNAPAction.getDFSSettings, {'isDFSSupported': false})
        ..holds(JNAPAction.getAirtimeFairnessSettings,
            {'isAirtimeFairnessSupported': false});
      final fresh = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(router.repo),
        pollingProvider.overrideWith(() => RecordingPolling()),
      ]);
      addTearDown(fresh.dispose);
      await fresh.read(wifiAdvancedProvider.notifier).fetch();
      router.transactions.clear();

      await fresh.read(wifiAdvancedProvider.notifier).save();

      expect(router.transactions.first.map((command) => command.key), [
        JNAPAction.setTopologyOptimizationSettings,
        JNAPAction.setIptvSettings,
      ]);
    });

    test('reads the settings back fresh after the save', () async {
      notifier().setDFSEnabled(true);
      router.holds(JNAPAction.getDFSSettings,
          {'isDFSSupported': true, 'isDFSEnabled': true});
      clearInteractions(router.repo);

      final saved = await notifier().save();

      expect(saved.isDFSEnabled, isTrue);
      verify(router.repo.transaction(any, fetchRemote: true)).called(1);
    });

    test('starts polling again once the save is over', () async {
      await notifier().save();

      expect(polling.paused, isFalse);
      expect(polling.started, 1);
    });

    test('a refused write reaches the caller, and nothing is read back',
        () async {
      router.refuses(JNAPAction.setDFSSettings);
      router.sent.clear();

      await expectLater(notifier().save(), throwsA(isA<JNAPError>()));

      expect(router.actions.where((a) => a.name.startsWith('get')), isEmpty);
      expect(polling.paused, isFalse);
    });
  });
}
