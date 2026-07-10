import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/local_network/models/local_network_ui_model.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/local_network/providers/usp_local_network_notifier.dart';
import 'package:privacy_gui/page/local_network/services/usp_local_network_service.dart';

class MockUspLocalNetworkService extends Mock
    implements UspLocalNetworkService {}

class MockSseManager extends Mock implements SseManager {}

class MockUspClient extends Mock implements UspClient {}

/// Test-only notifier that returns canned data and counts build() runs so
/// tests can assert whether save() triggered a post-save re-fetch.
class _TestLanDataNotifier extends LanDataNotifier {
  final LanData _testData;
  final ServiceError? errorToThrow;
  int buildCount = 0;
  _TestLanDataNotifier(this._testData, {this.errorToThrow});

  @override
  Future<LanData> build() async {
    buildCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return _testData;
  }
}

void main() {
  late MockUspLocalNetworkService mockService;
  late MockSseManager mockSseManager;

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
    mockSseManager = MockSseManager();
    when(() => mockService.validateAll(any())).thenReturn({});
    when(() => mockService.lockedOctetCount(any())).thenReturn(3);
    when(() => mockService.syncPrefix(any(), any(), any()))
        .thenAnswer((inv) => inv.positionalArguments[0] as String);
    when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
  });

  ProviderContainer createContainer({LanData? data}) {
    final container = ProviderContainer(
      overrides: [
        uspLocalNetworkServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        sseManagerProvider.overrideWithValue(mockSseManager),
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

    test('updateSetting mutates model without validation', () async {
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(hostName: 'NewName'));

      // updateSetting no longer calls validateAll — validation is separate
      verifyNever(() => mockService.validateAll(any()));
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

    test('validate propagates validation errors to status', () async {
      when(() => mockService.validateAll(any()))
          .thenReturn({'hostName': 'Too long'});
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(hostName: 'VeryLongHostNameX'));
      notifier.validate();

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
      notifier.validate();
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
                errorToThrow: const NetworkError(detail: 'timeout'),
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
          )).thenThrow(const NetworkError(detail: 'save failed'));
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(hostName: 'NewRouter'));

      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      expect(container.read(uspLocalNetworkProvider).status.isSaving, isFalse);
      container.dispose();
    });

    test('save on IP change disconnects SSE and skips the post-save re-fetch',
        () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
          )).thenAnswer((_) async {});
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final lanNotifier =
          container.read(lanDataProvider.notifier) as _TestLanDataNotifier;
      // build() ran once during initial fetch.
      expect(lanNotifier.buildCount, 1);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(ipAddress: '192.168.5.1'));
      await notifier.save();

      // SSE is dropped so the recovery flow never fires on top of the redirect
      // dialog.
      verify(() => mockSseManager.disconnect()).called(1);
      // No re-fetch: the router is unreachable at the old IP, so lanDataProvider
      // must NOT be invalidated/rebuilt (a re-fetch would time out).
      expect(lanNotifier.buildCount, 1);
      container.dispose();
    });

    test('save on non-network change re-fetches and does not disconnect SSE',
        () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
          )).thenAnswer((_) async {});
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final lanNotifier =
          container.read(lanDataProvider.notifier) as _TestLanDataNotifier;
      expect(lanNotifier.buildCount, 1);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      // Only a DHCP field changes — IP/subnet stay the same.
      notifier.updateSetting((m) => m.copyWith(dnsServer1: '9.9.9.9'));
      await notifier.save();
      await Future.delayed(Duration.zero);

      verifyNever(() => mockSseManager.disconnect());
      // lanDataProvider is invalidated → build() runs a second time.
      expect(lanNotifier.buildCount, 2);
      container.dispose();
    });
  });

  // Regression: pool prefix auto-sync must follow BOTH the router IP and the
  // subnet mask. Uses the REAL service so the pure lockedOctetCount/syncPrefix
  // logic runs, reproducing the dead-end from issue #1039 follow-up.
  group('UspLocalNetworkNotifier — pool prefix auto-sync (real service)', () {
    // Initial: ip=192.168.1.1, mask=255.255.0.0 (/16), pool=192.168.1.x
    final startLanData = LanData(
      model: LanInfoUIModel(
        hostName: 'MyRouter',
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.0.0',
        dhcpEnabled: true,
        minAddress: '192.168.1.100',
        maxAddress: '192.168.1.200',
        leaseTimeMinutes: 1440,
        dnsServers: '1.1.1.1',
      ),
    );

    ProviderContainer createRealContainer() {
      final container = ProviderContainer(
        overrides: [
          uspLocalNetworkServiceProvider
              .overrideWithValue(UspLocalNetworkService(MockUspClient())),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          sseManagerProvider.overrideWithValue(mockSseManager),
          lanDataProvider
              .overrideWith(() => _TestLanDataNotifier(startLanData)),
        ],
      );
      container.listen(uspLocalNetworkProvider, (_, __) {});
      return container;
    }

    test(
        'tightening the mask (/16 → /24) re-syncs pool prefix to the router IP '
        'so locked octets never go out-of-subnet', () async {
      final container = createRealContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);

      // 1. Change IP to 192.168.2.1 (mask still /16 → locks 2 octets, so the
      //    3rd octet of the pool stays .1 and is still in-subnet).
      notifier.updateSetting((m) => m.copyWith(ipAddress: '192.168.2.1'));
      var model =
          container.read(uspLocalNetworkProvider).settings.current.model;
      expect(model.minAddress, '192.168.1.100');
      expect(model.maxAddress, '192.168.1.200');

      // 2. Tighten the mask to /24. lockedOctetCount becomes 3, so the UI would
      //    lock the pool's 3rd octet read-only. The pool MUST be re-synced to
      //    the router's 3rd octet (2), otherwise it stays 192.168.1.x —
      //    out-of-subnet AND uneditable (the reported dead-end).
      notifier.updateSetting((m) => m.copyWith(subnetMask: '255.255.255.0'));
      model = container.read(uspLocalNetworkProvider).settings.current.model;
      expect(model.minAddress, '192.168.2.100');
      expect(model.maxAddress, '192.168.2.200');

      // Locked prefix and pool now agree → validation passes for the pool.
      notifier.validate();
      final errors =
          container.read(uspLocalNetworkProvider).status.validationErrors;
      expect(errors['minAddress'], isNull);
      expect(errors['maxAddress'], isNull);
      container.dispose();
    });
  });
}
