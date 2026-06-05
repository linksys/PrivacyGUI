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
                errorToThrow: const NetworkError(message: 'timeout'),
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
          )).thenThrow(const NetworkError(message: 'save failed'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspFirewallProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(isIPv6FirewallEnabled: true));

      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      expect(container.read(uspFirewallProvider).status.isSaving, isFalse);
      container.dispose();
    });
  });
}
