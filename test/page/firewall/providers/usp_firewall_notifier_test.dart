import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/usp_firewall_notifier.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';

class MockUspFirewallService extends Mock implements UspFirewallService {}

/// Test-only notifier that returns canned data instead of real fetch.
class _TestFirewallDataNotifier extends FirewallDataNotifier {
  final FirewallData _testData;
  final ServiceError? errorToThrow;
  _TestFirewallDataNotifier(this._testData, {this.errorToThrow});

  @override
  Future<FirewallData> build() async {
    if (errorToThrow != null) throw errorToThrow!;
    return _testData;
  }
}

void main() {
  late MockUspFirewallService mockService;

  final testData = FirewallData(
    firewallModel: FirewallUIModel(
      isIPv4FirewallEnabled: true,
      isIPv6FirewallEnabled: false,
      blockIPSec: true,
    ),
    ruleContext: FirewallRuleContext.empty,
    ruleSummaries: const [],
    dmzModel: const DmzUIModel.disabled(),
    dmzSummaries: const [],
  );

  setUpAll(() {
    registerFallbackValue(const FirewallUIModel());
    registerFallbackValue(FirewallRuleContext.empty);
  });

  setUp(() {
    mockService = MockUspFirewallService();
  });

  ProviderContainer createContainer({FirewallData? data}) {
    final container = ProviderContainer(
      overrides: [
        uspFirewallServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        firewallDataProvider
            .overrideWith(() => _TestFirewallDataNotifier(data ?? testData)),
      ],
    );
    container.listen(uspFirewallProvider, (_, __) {});
    return container;
  }

  group('UspFirewallNotifier', () {
    test('build returns initial loading state', () async {
      final container = createContainer();

      final state = container.read(uspFirewallProvider);
      expect(state.status.isLoading, isTrue);

      await Future.delayed(Duration.zero);
      container.dispose();
    });

    test('fetch success populates settings from data provider', () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspFirewallProvider);
      expect(state.settings.current.model.isIPv4FirewallEnabled, isTrue);
      expect(state.settings.current.model.isIPv6FirewallEnabled, isFalse);
      expect(state.settings.current.model.blockIPSec, isTrue);
      expect(state.status.isLoading, isFalse);
      container.dispose();
    });

    test('performSave calls service.save with original and pending', () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
            context: any(named: 'context'),
          )).thenAnswer((_) async => 2);

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspFirewallProvider.notifier);
      // Mutate to make dirty.
      notifier.updateSetting((m) => m.copyWith(isIPv6FirewallEnabled: true));
      await notifier.save();

      verify(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
            context: any(named: 'context'),
          )).called(1);
      container.dispose();
    });

    test('updateSetting mutates current model', () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspFirewallProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(isIPv6FirewallEnabled: true));

      final state = container.read(uspFirewallProvider);
      expect(state.settings.current.model.isIPv6FirewallEnabled, isTrue);
      container.dispose();
    });

    test('isDirty after mutation, clean after revert', () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspFirewallProvider.notifier);
      expect(notifier.isDirty(), isFalse);

      notifier.updateSetting((m) => m.copyWith(blockMulticast: true));
      expect(notifier.isDirty(), isTrue);

      notifier.revert();
      expect(notifier.isDirty(), isFalse);
      container.dispose();
    });

    test('revert restores original settings', () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspFirewallProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(blockIPSec: false));
      expect(
          container.read(uspFirewallProvider).settings.current.model.blockIPSec,
          isFalse);

      notifier.revert();
      expect(
          container.read(uspFirewallProvider).settings.current.model.blockIPSec,
          isTrue);
      container.dispose();
    });

    test('fetch error sets error status', () async {
      final container = ProviderContainer(
        overrides: [
          uspFirewallServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          firewallDataProvider.overrideWith(() => _TestFirewallDataNotifier(
                testData,
                errorToThrow: const NetworkError(detail: 'timeout'),
              )),
        ],
      );
      container.listen(uspFirewallProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      final state = container.read(uspFirewallProvider);
      expect(state.status.error, isA<NetworkError>());
      container.dispose();
    });

    test('performSave rethrows ServiceError and clears isSaving', () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
            context: any(named: 'context'),
          )).thenThrow(const NetworkError(detail: 'save failed'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspFirewallProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(isIPv6FirewallEnabled: true));

      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      expect(container.read(uspFirewallProvider).status.isSaving, isFalse);
      container.dispose();
    });
  });

  group('FirewallData equality', () {
    FirewallData dataWith({
      List<FirewallRuleSummary> ruleSummaries = const [],
      FirewallRuleContext ruleContext = FirewallRuleContext.empty,
      List<DmzEntrySummary> dmzSummaries = const [],
    }) =>
        FirewallData(
          firewallModel: const FirewallUIModel(),
          ruleContext: ruleContext,
          ruleSummaries: ruleSummaries,
          dmzModel: const DmzUIModel.disabled(),
          dmzSummaries: dmzSummaries,
        );

    test('differs when rule content changes but count stays the same', () {
      // Regression: props must not narrow to ruleSummaries.length. Two rules of
      // equal length but different content are NOT equal, so the provider still
      // notifies listeners on a content-only change.
      final a = dataWith(ruleSummaries: const [
        FirewallRuleSummary(target: 'ACCEPT', enabled: true),
      ]);
      final b = dataWith(ruleSummaries: const [
        FirewallRuleSummary(target: 'DROP', enabled: true),
      ]);

      expect(a, isNot(equals(b)));
    });

    test('differs when only dmzSummaries changes', () {
      final a = dataWith(dmzSummaries: const []);
      final b = dataWith(dmzSummaries: const [
        DmzEntrySummary(enable: true, destIp: '192.168.1.5'),
      ]);

      expect(a, isNot(equals(b)));
    });

    test('namedProps stays lean for diagnostic output', () {
      final data = dataWith(ruleSummaries: const [
        FirewallRuleSummary(target: 'ACCEPT', enabled: true),
        FirewallRuleSummary(target: 'DROP', enabled: false),
      ]);

      expect(data.namedProps.keys,
          containsAll(<String>['firewallModel', 'ruleCount', 'dmzModel']));
      expect(data.namedProps['ruleCount'], 2);
    });
  });

  // -------------------------------------------------------------------------
  // The firewallDataProvider listener drives onSseInvalidation() once per
  // upstream settle, not once per notification.
  //
  // `hasValue` alone is not an edge trigger: re-running an AsyncNotifier that
  // already holds a value emits AsyncData(isLoading: true, value: prev) via
  // copyWithPrevious before the fresh value, and that frame has hasValue true
  // too. onSseInvalidation() calls unawaited(fetch(forceRemote: true)), which
  // does NOT coalesce the way invalidateSelf() does — so the unguarded listener
  // ran two full fetches per upstream refetch, the first of them against the
  // stale value. See doc/riverpod/listen_site_audit.md (#1502 AC-4).
  // -------------------------------------------------------------------------
  group('UspFirewallNotifier — data provider re-notification', () {
    test('an upstream refetch triggers exactly one forceRemote fetch',
        () async {
      final counting = _CountingFirewallNotifier();
      final container = ProviderContainer(
        overrides: [
          uspFirewallServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          firewallDataProvider
              .overrideWith(() => _TestFirewallDataNotifier(testData)),
          uspFirewallProvider.overrideWith(() => counting),
        ],
      );
      addTearDown(container.dispose);

      // A permanent subscription keeps the notifier — and therefore its
      // ref.listen on firewallDataProvider — alive, so the invalidate below
      // rebuilds eagerly instead of being deferred to the next read.
      container.listen(uspFirewallProvider, (_, __) {});
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // Boot already produces one: the data provider's first settle is a
      // loading→data transition, which the listener treats as an invalidation.
      // Measure the delta so this test is about the refetch, not about boot.
      final baseline = counting.forceRemoteFetches;

      container.invalidate(firewallDataProvider);
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      // Two listener firings (loading-with-previous, then the fresh value),
      // one fetch. Without the isLoading guard the delta is 2.
      expect(counting.forceRemoteFetches - baseline, 1);
    });
  });
}

/// Wraps the real notifier to count SSE-driven fetches. Only [performFetch] is
/// overridden — the `ref.listen` under test is the production one in `build()`.
class _CountingFirewallNotifier extends UspFirewallNotifier {
  int forceRemoteFetches = 0;

  @override
  Future<(FirewallSettings?, FirewallStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) {
    if (forceRemote) forceRemoteFetches++;
    return super.performFetch(
      forceRemote: forceRemote,
      updateStatusOnly: updateStatusOnly,
    );
  }
}
