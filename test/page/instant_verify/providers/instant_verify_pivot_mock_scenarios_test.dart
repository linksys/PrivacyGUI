// Tests for InstantVerifyPivotNotifier.loadMockScenario()
//
// Each scenario must produce state with the expected primary finding type
// and the right VerdictPriority. These tests catch a scenario silently
// producing the wrong (or null) verdict — e.g. after a VerdictEngine refactor.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import '../../../mocks/router_repository_mocks.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';

// Minimal real notifier — build() has no deps, loadMockScenario() is pure.
class _TestNotifier extends InstantVerifyPivotNotifier {
  _TestNotifier({this.initial = const InstantVerifyPivotState()});
  final InstantVerifyPivotState initial;
  @override
  InstantVerifyPivotState build() => initial;
}

ProviderContainer _container() => ProviderContainer(
      overrides: [
        instantVerifyPivotProvider.overrideWith(() => _TestNotifier()),
      ],
    );

void main() {
  test('required router read failure ends checking and permits a new run', () async {
    final repo = MockRouterRepository();
    when(repo.send(any, data: anyNamed('data'), fetchRemote: true,
        cacheLevel: CacheLevel.noCache, auth: anyNamed('auth')))
        .thenThrow(StateError('read unavailable'));
    final c = ProviderContainer(overrides: [routerRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    final notifier = c.read(instantVerifyPivotProvider.notifier);
    for (var attempt = 0; attempt < 2; attempt++) {
      await notifier.fetch();
      final state = c.read(instantVerifyPivotProvider);
      expect(state.phase, PivotLoadPhase.complete);
      expect(state.browserTestStep, 'error');
      expect(state.errorMessage, isNotNull);
      expect(state.verdict, isNull);
    }
  });

  test('privacy background initialization handles rejected credentials', () async {
    final repo = MockRouterRepository();
    when(repo.send(JNAPAction.getMACFilterSettings, fetchRemote: true, auth: true))
        .thenThrow(const JNAPError(result: '_ErrorUnauthorized'));
    final c = ProviderContainer(overrides: [routerRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    c.read(instantPrivacyProvider);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(instantPrivacyProvider), isNotNull);
    await expectLater(c.read(instantPrivacyProvider.notifier).fetch(fetchRemote: true),
        throwsA(isA<JNAPError>()), reason: 'Explicit callers still receive their errors');
  });

  test('rejected device reconnect reports failure', () async {
    final repo = MockRouterRepository();
    when(repo.send(JNAPAction.clientDeauth, data: {'macAddress': 'AA:BB:CC:DD:EE:01'},
        fetchRemote: true, cacheLevel: CacheLevel.noCache, auth: true))
        .thenThrow(StateError('reconnect rejected'));
    final c = ProviderContainer(overrides: [routerRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    await expectLater(c.read(instantVerifyPivotProvider.notifier).deauthClient('AA:BB:CC:DD:EE:01'),
        throwsStateError);
  });

  test('HTTP-200 unauthorized JNAP result reaches authentication owner once', () async {
    final repo = MockRouterRepository();
    when(repo.send(JNAPAction.reboot, data: {}, fetchRemote: true,
        cacheLevel: CacheLevel.noCache, auth: true))
        .thenThrow(const JNAPError(result: '_ErrorUnauthorized'));
    final previous = LinksysHttpClient.onError;
    final errors = <dynamic>[];
    LinksysHttpClient.onError = errors.add;
    addTearDown(() => LinksysHttpClient.onError = previous);
    final c = ProviderContainer(overrides: [routerRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    for (var i = 0; i < 2; i++) {
      await expectLater(c.read(instantVerifyPivotProvider.notifier).restartRouter(),
          throwsA(isA<JNAPError>()));
    }
    expect(errors, hasLength(1));
    when(repo.send(JNAPAction.reboot, data: {}, fetchRemote: true,
        cacheLevel: CacheLevel.noCache, auth: true))
        .thenAnswer((_) async => const JNAPSuccess(result: 'OK'));
    await c.read(instantVerifyPivotProvider.notifier).restartRouter();
    when(repo.send(JNAPAction.reboot, data: {}, fetchRemote: true,
        cacheLevel: CacheLevel.noCache, auth: true))
        .thenThrow(const JNAPError(result: '_ErrorUnauthorized'));
    await expectLater(c.read(instantVerifyPivotProvider.notifier).restartRouter(),
        throwsA(isA<JNAPError>()));
    expect(errors, hasLength(2), reason: 'A later authenticated session must still handle rejection');
  });

  test('rejected restart clears progress and reports failure', () async {
    final repo = MockRouterRepository();
    when(repo.send(JNAPAction.reboot, data: {}, fetchRemote: true,
        cacheLevel: CacheLevel.noCache, auth: true))
        .thenThrow(StateError('restart rejected'));
    final c = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    await expectLater(c.read(instantVerifyPivotProvider.notifier).restartRouter(),
        throwsStateError);
    expect(c.read(instantVerifyPivotProvider).isRestarting, isFalse);
    expect(c.read(instantVerifyPivotProvider).hasRestartedThisSession, isFalse);
  });

  test('unsupported optional checks are excluded from the pass count', () {
    int count(InstantVerifyPivotState initial) {
      final c = ProviderContainer(overrides: [
        instantVerifyPivotProvider.overrideWith(() => _TestNotifier(initial: initial)),
      ]);
      addTearDown(c.dispose);
      c.read(instantVerifyPivotProvider.notifier).setPlanSpeed(null);
      return c.read(instantVerifyPivotProvider).verdict!.checksRun;
    }
    final unavailable = count(const InstantVerifyPivotState());
    final available = count(const InstantVerifyPivotState(
      wirelessSchedule: {'isEnabled': false},
      parentalControls: {'isParentalControlEnabled': false},
      networkSecurity: {'pmfMode': 'Optional'},
      macFilter: {'macFilterMode': 'disabled'},
    ));
    expect(available - unavailable, 4,
        reason: 'Unsupported firmware APIs are untested, not successful checks');
  });

  group('loadMockScenario — state shape', () {
    test('all 5 scenarios reach phase=complete', () {
      for (var i = 0; i < 5; i++) {
        final c = _container();
        addTearDown(c.dispose);
        c.read(instantVerifyPivotProvider.notifier).loadMockScenario(i);
        final state = c.read(instantVerifyPivotProvider);
        expect(state.phase, PivotLoadPhase.complete,
            reason: 'Scenario $i must set phase=complete');
        expect(state.verdictIsPreliminary, isFalse,
            reason: 'Scenario $i must be finalized (not preliminary)');
      }
    });

    test('all 5 scenarios produce a non-null verdict', () {
      for (var i = 0; i < 5; i++) {
        final c = _container();
        addTearDown(c.dispose);
        c.read(instantVerifyPivotProvider.notifier).loadMockScenario(i);
        final verdict = c.read(instantVerifyPivotProvider).verdict;
        expect(verdict, isNotNull, reason: 'Scenario $i must have a verdict');
      }
    });
  });

  group('loadMockScenario — Scenario 0: No internet (WAN disconnected)', () {
    late ProviderContainer c;
    setUp(() {
      c = _container();
      c.read(instantVerifyPivotProvider.notifier).loadMockScenario(0);
    });
    tearDown(() => c.dispose());

    test('WAN is disconnected', () {
      expect(c.read(instantVerifyPivotProvider).wanConnected, isFalse);
    });

    test('primary finding is critical', () {
      final primary = c.read(instantVerifyPivotProvider).verdict!.primaryFinding!;
      expect(primary.priority, VerdictPriority.critical);
    });

    test('primary finding mentions internet/connection', () {
      final headline = c.read(instantVerifyPivotProvider).verdict!.primaryFinding!.headline;
      expect(headline.toLowerCase(), contains('internet'));
    });
  });

  group('loadMockScenario — Scenario 1: DNS failure', () {
    late ProviderContainer c;
    setUp(() {
      c = _container();
      c.read(instantVerifyPivotProvider.notifier).loadMockScenario(1);
    });
    tearDown(() => c.dispose());

    test('WAN is connected but DNS failed', () {
      final state = c.read(instantVerifyPivotProvider);
      expect(state.wanConnected, isTrue);
      expect(state.dnsCheck?.resolved, isFalse);
    });

    test('primary finding is critical', () {
      final primary = c.read(instantVerifyPivotProvider).verdict!.primaryFinding!;
      expect(primary.priority, VerdictPriority.critical);
    });

    test('primary finding has restart CTA', () {
      final primary = c.read(instantVerifyPivotProvider).verdict!.primaryFinding!;
      expect(primary.actionKey, VerdictEngine.actionRestartRouter);
    });
  });

  group('loadMockScenario — Scenario 2: Slow internet + weak devices', () {
    late ProviderContainer c;
    setUp(() {
      c = _container();
      c.read(instantVerifyPivotProvider.notifier).loadMockScenario(2);
    });
    tearDown(() => c.dispose());

    test('speed test shows low download', () {
      final state = c.read(instantVerifyPivotProvider);
      expect(state.speedTest, isNotNull);
      expect(state.speedTest!.downloadMbps, lessThan(10));
    });

    test('has weak-signal devices', () {
      final state = c.read(instantVerifyPivotProvider);
      expect(state.issueDevices, isNotEmpty);
    });

    test('verdict has multiple findings (speed + latency + devices + firmware + uptime)', () {
      final findings = c.read(instantVerifyPivotProvider).verdict!.findings;
      expect(findings.length, greaterThanOrEqualTo(3));
    });

    test('firmware update is flagged', () {
      expect(c.read(instantVerifyPivotProvider).firmwareUpdateAvailable, isTrue);
    });
  });

  group('loadMockScenario — Scenario 3: Router overloaded + mesh', () {
    late ProviderContainer c;
    setUp(() {
      c = _container();
      c.read(instantVerifyPivotProvider.notifier).loadMockScenario(3);
    });
    tearDown(() => c.dispose());

    test('has 3 mesh nodes', () {
      expect(c.read(instantVerifyPivotProvider).meshNodes.length, equals(3));
    });

    test('internet is working (speed is fine)', () {
      final state = c.read(instantVerifyPivotProvider);
      expect(state.dnsCheck?.resolved, isTrue);
      expect(state.speedTest!.downloadMbps, greaterThan(50));
    });

    test('verdict contains CPU or memory finding', () {
      final findings = c.read(instantVerifyPivotProvider).verdict!.findings;
      final hasHealthFinding = findings.any((f) =>
          f.headline.toLowerCase().contains('cpu') ||
          f.headline.toLowerCase().contains('memory') ||
          f.headline.toLowerCase().contains('load'));
      expect(hasHealthFinding, isTrue);
    });

    test('verdict contains ethernet or mesh finding', () {
      final findings = c.read(instantVerifyPivotProvider).verdict!.findings;
      final hasMeshOrEthernet = findings.any((f) =>
          f.headline.toLowerCase().contains('child') ||
          f.headline.toLowerCase().contains('wired') ||
          f.headline.toLowerCase().contains('ethernet') ||
          f.headline.toLowerCase().contains('node'));
      expect(hasMeshOrEthernet, isTrue);
    });
  });

  group('loadMockScenario — Scenario 4: Config blocks', () {
    late ProviderContainer c;
    setUp(() {
      c = _container();
      c.read(instantVerifyPivotProvider.notifier).loadMockScenario(4);
    });
    tearDown(() => c.dispose());

    test('DHCP pool is nearly full (92%)', () {
      final state = c.read(instantVerifyPivotProvider);
      expect(state.dhcpLeasesCount, equals(138));
      expect(state.dhcpPoolLimit, equals(150));
    });

    test('Instant Privacy is active', () {
      expect(c.read(instantVerifyPivotProvider).isMacFilterEnabled, isTrue);
    });

    test('verdict has config-related findings', () {
      final findings = c.read(instantVerifyPivotProvider).verdict!.findings;
      expect(findings, isNotEmpty);
      // At minimum: schedule, privacy, band steering, PMF, DHCP, 2.4GHz crowd
      expect(findings.length, greaterThanOrEqualTo(4));
    });

    test('at least one finding mentions WiFi or network configuration', () {
      final findings = c.read(instantVerifyPivotProvider).verdict!.findings;
      final hasConfigFinding = findings.any((f) =>
          f.headline.toLowerCase().contains('wifi') ||
          f.headline.toLowerCase().contains('schedule') ||
          f.headline.toLowerCase().contains('privacy') ||
          f.headline.toLowerCase().contains('band') ||
          f.headline.toLowerCase().contains('network') ||
          f.headline.toLowerCase().contains('address pool'));
      expect(hasConfigFinding, isTrue);
    });
  });

  group('loadMockScenario — out-of-range index falls back gracefully', () {
    test('index 99 produces a non-null verdict', () {
      final c = _container();
      addTearDown(c.dispose);
      c.read(instantVerifyPivotProvider.notifier).loadMockScenario(99);
      expect(c.read(instantVerifyPivotProvider).verdict, isNotNull);
    });
  });
}
