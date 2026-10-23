import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/usp_firewall_notifier.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';

import '../../../mocks/test_data/firewall_test_data.dart';

class MockUspFirewallService extends Mock implements UspFirewallService {}

/// Test-only notifier that returns canned data instead of real fetch.
class _TestFirewallDataNotifier extends FirewallDataNotifier {
  final FirewallData _testData;
  final ServiceError? errorToThrow;

  /// When set, every read from this build onwards fails, so the post-save read
  /// can fail after a good initial load.
  final int? failFromBuild;
  int _builds = 0;
  _TestFirewallDataNotifier(this._testData,
      {this.errorToThrow, this.failFromBuild});

  @override
  Future<FirewallData> build() async {
    _builds++;
    if (errorToThrow != null) throw errorToThrow!;
    final from = failFromBuild;
    if (from != null && _builds >= from) {
      throw const NetworkError(detail: 'read failed');
    }
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
    ruleContext: FirewallTestData.createNamedRuleContext(),
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

  ProviderContainer createContainer({FirewallData? data, int? failFromBuild}) {
    final container = ProviderContainer(
      overrides: [
        uspFirewallServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        firewallDataProvider.overrideWith(() => _TestFirewallDataNotifier(
            data ?? testData,
            failFromBuild: failFromBuild)),
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

    // #1212 / #1279: the write invalidates firewallDataProvider and the
    // post-save read rebuilds it; when that read fails the page must not turn
    // into an error page under the "saved" toast.
    test(
        'a failed post-save read throws saved-but-unconfirmed and keeps the '
        'page on what was written', () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
            context: any(named: 'context'),
          )).thenAnswer((_) async => 1);

      final container = createContainer(failFromBuild: 2);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspFirewallProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(isIPv6FirewallEnabled: true));

      await expectLater(
          notifier.save(), throwsA(isA<SavedButUnconfirmedError>()));

      final state = container.read(uspFirewallProvider);
      expect(state.status.error, isNull);
      expect(state.settings.current.model.isIPv6FirewallEnabled, isTrue);
      expect(state.isDirty, isFalse);
      container.dispose();
    });

    test('performSave writes against the rules the router reported', () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
            context: any(named: 'context'),
          )).thenAnswer((_) async => 1);

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspFirewallProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(isIPv6FirewallEnabled: true));
      await notifier.save();

      final sent = verify(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
            context: captureAny(named: 'context'),
          )).captured.single;
      expect(sent, testData.ruleContext);
      container.dispose();
    });

    // The locks on screen and the rules a save writes against come from the
    // same read. Taking the rules again at save time let a refresh in between
    // unlock-and-skip a switch, which is the #1611 partial write.
    test('performSave uses the rules the page loaded with, not a later refresh',
        () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
            context: any(named: 'context'),
          )).thenAnswer((_) async => 1);

      final container = createContainer();
      await Future.delayed(Duration.zero);

      container.read(firewallDataProvider.notifier).state = AsyncData(
        FirewallTestData.createFirewallData(
          ruleContext: FirewallTestData.createNamedRuleContext(
            without: const {'RULE_NAT_REDIRECTION'},
          ),
        ),
      );

      final notifier = container.read(uspFirewallProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(isIPv6FirewallEnabled: true));
      await notifier.save();

      final sent = verify(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
            context: captureAny(named: 'context'),
          )).captured.first;
      expect(sent, testData.ruleContext);
      container.dispose();
    });

    test('performSave does not depend on the shared data being readable',
        () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
            context: any(named: 'context'),
          )).thenAnswer((_) async => 1);

      final container = createContainer();
      await Future.delayed(Duration.zero);

      container.read(firewallDataProvider.notifier).state = AsyncError(
          const NetworkError(detail: 'refresh failed'), StackTrace.empty);

      final notifier = container.read(uspFirewallProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(isIPv6FirewallEnabled: true));
      await notifier.save();

      verify(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
            context: any(named: 'context'),
          )).called(1);
      container.dispose();
    });

    test('a switch whose rule is not on the router is locked', () async {
      final container = createContainer(
        data: FirewallTestData.createFirewallData(
          ruleContext: FirewallTestData.createNamedRuleContext(
            without: const {'RULE_NAT_REDIRECTION'},
          ),
        ),
      );
      await Future.delayed(Duration.zero);

      expect(container.read(uspFirewallProvider).status.lockedSwitches,
          {FirewallSwitch.natRedirection});
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

    // FW 2.0.2 carried none of the named rules. The page rendered fixed,
    // fabricated toggle positions instead of saying it could not read them
    // (#1611).
    test('fetch with no recognised firewall rule sets error status', () async {
      final container = createContainer(
        data: FirewallTestData.createFirewallData(
          ruleContext: FirewallRuleContext.empty,
        ),
      );
      await Future.delayed(Duration.zero);

      final state = container.read(uspFirewallProvider);
      expect(state.status.error, isA<ResourceNotFoundError>());
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
}
