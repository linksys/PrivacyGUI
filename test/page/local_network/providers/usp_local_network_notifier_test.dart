import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/local_network/models/local_network_ui_model.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/usp_local_network_notifier.dart';
import 'package:privacy_gui/page/local_network/services/usp_local_network_service.dart';

class MockUspLocalNetworkService extends Mock
    implements UspLocalNetworkService {}

/// Test-only notifier that returns canned data.
class _TestLanDataNotifier extends LanDataNotifier {
  final LanData _testData;
  final ServiceError? errorToThrow;
  _TestLanDataNotifier(this._testData, {this.errorToThrow});

  @override
  Future<LanData> build() async {
    if (errorToThrow != null) throw errorToThrow!;
    return _testData;
  }
}

void main() {
  late MockUspLocalNetworkService mockService;

  final testLanData = LanData(
    model: LanInfoUIModel(
      hostName: 'MyRouter',
      ipAddress: '192.168.1.1',
      subnetMask: '255.255.255.0',
      dhcpEnabled: true,
      minAddress: '192.168.1.100',
      maxAddress: '192.168.1.200',
      leaseTimeMinutes: 1440,
      dnsServers: '1.1.1.1,8.8.8.8',
    ),
  );

  setUpAll(() {
    registerFallbackValue(const LocalNetworkUIModel.initial());
  });

  setUp(() {
    mockService = MockUspLocalNetworkService();
    when(() => mockService.validateAll(any())).thenReturn({});
    when(() => mockService.lockedOctetCount(any())).thenReturn(3);
    when(() => mockService.syncPrefix(any(), any(), any()))
        .thenAnswer((inv) => inv.positionalArguments[0] as String);
  });

  ProviderContainer createContainer({LanData? data}) {
    final container = ProviderContainer(
      overrides: [
        uspLocalNetworkServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        lanDataProvider
            .overrideWith(() => _TestLanDataNotifier(data ?? testLanData)),
      ],
    );
    container.listen(uspLocalNetworkProvider, (_, __) {});
    return container;
  }

  group('UspLocalNetworkNotifier', () {
    test('build returns initial loading state', () async {
      final container = createContainer();

      final state = container.read(uspLocalNetworkProvider);
      expect(state.status.isLoading, isTrue);

      // Let microtask (Future.microtask in build) complete before disposing.
      await Future.delayed(Duration.zero);
      container.dispose();
    });

    test('fetch success parses DNS and populates model', () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspLocalNetworkProvider);
      final model = state.settings.current.model;
      expect(model.hostName, 'MyRouter');
      expect(model.ipAddress, '192.168.1.1');
      expect(model.dhcpEnabled, isTrue);
      expect(model.dnsServer1, '1.1.1.1');
      expect(model.dnsServer2, '8.8.8.8');
      expect(model.dnsServer3, '');
      expect(state.status.isLoading, isFalse);
      container.dispose();
    });

    test('updateSetting triggers validation', () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(hostName: 'NewName'));

      verify(() => mockService.validateAll(any())).called(1);
      final state = container.read(uspLocalNetworkProvider);
      expect(state.settings.current.model.hostName, 'NewName');
      container.dispose();
    });

    test('updateSetting syncs prefix when IP changes', () async {
      when(() => mockService.syncPrefix(any(), any(), any()))
          .thenReturn('192.168.2.100');
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(ipAddress: '192.168.2.1'));

      // lockedOctetCount called: once in performFetch, once in auto-sync,
      // once to update status.lockedOctetCount.
      verify(() => mockService.lockedOctetCount('255.255.255.0')).called(3);
      // syncPrefix called for both min and max addresses.
      verify(() => mockService.syncPrefix(any(), '192.168.2.1', 3)).called(2);
      container.dispose();
    });

    test('updateSetting propagates validation errors to status', () async {
      when(() => mockService.validateAll(any()))
          .thenReturn({'hostName': 'Too long'});
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(hostName: 'VeryLongHostNameX'));

      final state = container.read(uspLocalNetworkProvider);
      expect(state.status.validationErrors['hostName'], 'Too long');
      container.dispose();
    });

    test('revert clears validation errors and restores settings', () async {
      when(() => mockService.validateAll(any()))
          .thenReturn({'hostName': 'error'});
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(hostName: 'X'));
      expect(
          container
              .read(uspLocalNetworkProvider)
              .status
              .validationErrors['hostName'],
          'error');

      notifier.revert();

      final state = container.read(uspLocalNetworkProvider);
      expect(state.settings.current.model.hostName, 'MyRouter');
      expect(state.status.validationErrors, isEmpty);
      container.dispose();
    });

    test('isDirty after mutation, clean after revert', () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      expect(notifier.isDirty(), isFalse);

      notifier.updateSetting((m) => m.copyWith(hostName: 'Changed'));
      expect(notifier.isDirty(), isTrue);

      notifier.revert();
      expect(notifier.isDirty(), isFalse);
      container.dispose();
    });

    test('fetch error sets error status', () async {
      final container = ProviderContainer(
        overrides: [
          uspLocalNetworkServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          lanDataProvider.overrideWith(() => _TestLanDataNotifier(
                testLanData,
                errorToThrow: const NetworkError(message: 'timeout'),
              )),
        ],
      );
      container.listen(uspLocalNetworkProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      final state = container.read(uspLocalNetworkProvider);
      expect(state.status.error, isA<NetworkError>());
      container.dispose();
    });

    test('performSave calls service.save with original and pending', () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
          )).thenAnswer((_) async {});
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(hostName: 'NewRouter'));
      await notifier.save();

      verify(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
          )).called(1);
      container.dispose();
    });

    test('performSave rethrows ServiceError and clears isSaving', () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
          )).thenThrow(const NetworkError(message: 'save failed'));
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(hostName: 'NewRouter'));

      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      expect(container.read(uspLocalNetworkProvider).status.isSaving, isFalse);
      container.dispose();
    });
  });
}
