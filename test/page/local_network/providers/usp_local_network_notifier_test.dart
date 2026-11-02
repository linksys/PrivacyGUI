import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/models/local_network_ui_model.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/local_network/providers/usp_local_network_notifier.dart';
import 'package:privacy_gui/page/local_network/services/usp_local_network_service.dart';

import '../../../mocks/test_data/system_info_test_data.dart';

class MockUspLocalNetworkService extends Mock
    implements UspLocalNetworkService {}

class MockSseManager extends Mock implements SseManager {}

class MockUspClient extends Mock implements UspClient {}

/// Test-only notifier that returns canned data and counts build() runs so
/// tests can assert whether save() triggered a post-save re-fetch.
class _TestLanDataNotifier extends LanDataNotifier {
  final LanData _testData;
  final ServiceError? errorToThrow;

  /// When set, every read from this build onwards fails — the first reads
  /// succeed, so a post-save read can fail on its own.
  final int? failFromBuild;
  int buildCount = 0;
  _TestLanDataNotifier(this._testData, {this.errorToThrow, this.failFromBuild});

  @override
  Future<LanData> build() async {
    buildCount++;
    if (errorToThrow != null) throw errorToThrow!;
    final from = failFromBuild;
    if (from != null && buildCount >= from) {
      throw const NetworkError(detail: 'read failed');
    }
    return _testData;
  }
}

/// Counts system-info reads, so a test can tell whether a save refreshed it.
class _CountingSystemInfoNotifier extends SystemInfoDataNotifier {
  int buildCount = 0;

  @override
  Future<SystemInfoData> build() async {
    buildCount++;
    return SystemInfoData(model: SystemInfoTestData.create());
  }
}

/// Counts device refetches, the read that rebuilds the master node's name.
class _CountingDevicesNotifier extends DevicesDataNotifier {
  int refetchCount = 0;

  @override
  Future<DevicesData> build() async => DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(deviceId: 'GATEWAY', model: 'M60'),
        ),
      );

  @override
  Future<void> refetch() async => refetchCount++;
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

  ProviderContainer createContainer({LanData? data, int? failFromBuild}) {
    final container = ProviderContainer(
      overrides: [
        uspLocalNetworkServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        sseManagerProvider.overrideWithValue(mockSseManager),
        lanDataProvider.overrideWith(() => _TestLanDataNotifier(
            data ?? testLanData,
            failFromBuild: failFromBuild)),
        systemInfoDataProvider.overrideWith(_CountingSystemInfoNotifier.new),
        devicesDataProvider.overrideWith(_CountingDevicesNotifier.new),
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

    // PrivacyGUI#1729: a mask change makes the router take the LAN down and
    // back up after SetResp, and the pool settles only once it is back. A read
    // inside that window holds the old or a half-converted range, or fails.
    // So the save does not read back: the page stays on what was sent.
    test('save on mask change shows what was sent and does not read back',
        () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
          )).thenAnswer((_) async {});
      final container = createContainer();
      await Future.delayed(Duration.zero);
      final lanNotifier =
          container.read(lanDataProvider.notifier) as _TestLanDataNotifier;

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(
            subnetMask: '255.255.0.0',
            minAddress: '192.168.2.100',
            maxAddress: '192.168.2.249',
          ));
      await notifier.save();
      await Future.delayed(Duration.zero);

      // A read would have put the router's pre-save /24 back on the page.
      final state = container.read(uspLocalNetworkProvider);
      final shown = state.settings.current.model;
      expect((shown.subnetMask, shown.minAddress, shown.maxAddress),
          ('255.255.0.0', '192.168.2.100', '192.168.2.249'));
      expect(state.isDirty, isFalse);
      // L1 is left for the router's pool push: re-read now, it would hold the
      // half-converted range for every page that reads it.
      expect(lanNotifier.buildCount, 1);
      // The connection comes back after the LAN does, so SSE stays up.
      verifyNever(() => mockSseManager.disconnect());
      container.dispose();
    });

    test('a mask change saved with other fields shows all of them as sent',
        () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
          )).thenAnswer((_) async {});
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(
            subnetMask: '255.255.0.0',
            hostName: 'NewRouter',
            dnsServer1: '9.9.9.9',
          ));
      final lanNotifier =
          container.read(lanDataProvider.notifier) as _TestLanDataNotifier;
      await notifier.save();
      await Future.delayed(Duration.zero);

      final state = container.read(uspLocalNetworkProvider);
      final shown = state.settings.current.model;
      expect((shown.subnetMask, shown.hostName, shown.dnsServer1),
          ('255.255.0.0', 'NewRouter', '9.9.9.9'));
      expect(state.isDirty, isFalse);
      expect(lanNotifier.buildCount, 1);
      verifyNever(() => mockSseManager.disconnect());
      container.dispose();
    });

    test('a mask change the router refuses outright keeps the edits too',
        () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
          )).thenThrow(const UspCompleteFailureError(
        summary: 'mask rejected',
        failures: [],
      ));
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(subnetMask: '255.255.0.0'));
      await expectLater(
          notifier.save(), throwsA(isA<UspCompleteFailureError>()));

      final state = container.read(uspLocalNetworkProvider);
      expect(state.isDirty, isTrue);
      expect(state.settings.current.model.subnetMask, '255.255.0.0');
      container.dispose();
    });

    test('a refused mask change keeps the edits and stays dirty', () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
          )).thenThrow(const UspPartialFailureError(
        summary: 'DNS rejected',
        successPaths: ['Device.IP.Interface.1.IPv4Address.1.SubnetMask'],
        failures: [],
      ));
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(
            subnetMask: '255.255.0.0',
            dnsServer1: 'bad',
          ));
      await expectLater(
          notifier.save(), throwsA(isA<UspPartialFailureError>()));

      final state = container.read(uspLocalNetworkProvider);
      expect(state.isDirty, isTrue);
      expect(state.settings.current.model.subnetMask, '255.255.0.0');
      container.dispose();
    });

    // #1751: DeviceInfo.HostName is also the controller's name when nobody has
    // named it, and that name reaches the master node through system info, not
    // through this page's LAN read.
    group('a host-name change refreshes the controller\'s name (#1751)', () {
      Future<(int systemInfoReads, int deviceRefetches)> saveWith(
          LocalNetworkUIModel Function(LocalNetworkUIModel) edit) async {
        when(() => mockService.save(
              original: any(named: 'original'),
              pending: any(named: 'pending'),
            )).thenAnswer((_) async {});
        final container = createContainer();
        addTearDown(container.dispose);
        // Read once so the counters start from a settled provider.
        await container.read(systemInfoDataProvider.future);
        await container.read(devicesDataProvider.future);
        await Future.delayed(Duration.zero);
        final systemInfo = container.read(systemInfoDataProvider.notifier)
            as _CountingSystemInfoNotifier;
        final devices = container.read(devicesDataProvider.notifier)
            as _CountingDevicesNotifier;
        final before = systemInfo.buildCount;

        final notifier = container.read(uspLocalNetworkProvider.notifier);
        notifier.updateSetting(edit);
        await notifier.save();
        await container.read(systemInfoDataProvider.future);
        await Future.delayed(Duration.zero);

        return (systemInfo.buildCount - before, devices.refetchCount);
      }

      test('saving a new host name re-reads system info and the devices',
          () async {
        final (systemInfoReads, deviceRefetches) =
            await saveWith((m) => m.copyWith(hostName: 'Linksys12345'));

        expect(systemInfoReads, 1);
        expect(deviceRefetches, 1);
      });

      test('a save that leaves the host name alone does not', () async {
        final (systemInfoReads, deviceRefetches) =
            await saveWith((m) => m.copyWith(dnsServer1: '9.9.9.9'));

        expect(systemInfoReads, 0);
        expect(deviceRefetches, 0);
      });

      test('a mask change saved with a new host name refreshes them too',
          () async {
        // The mask branch keeps what was sent and reads no LAN back, but the
        // host name the SET stored still has to reach the controller's name.
        final (systemInfoReads, deviceRefetches) = await saveWith((m) =>
            m.copyWith(subnetMask: '255.255.0.0', hostName: 'Linksys12345'));

        expect(systemInfoReads, 1);
        expect(deviceRefetches, 1);
      });
    });

    // #1212 / #1279: this page sequences its own save, so it must still hand
    // the read-back to the framework's rule rather than call fetch() itself.
    test(
        'a failed post-save read reports saved-but-unconfirmed, not an error '
        'page', () async {
      when(() => mockService.save(
            original: any(named: 'original'),
            pending: any(named: 'pending'),
          )).thenAnswer((_) async {});
      final container = createContainer(failFromBuild: 2);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspLocalNetworkProvider.notifier);
      notifier.updateSetting((m) => m.copyWith(dnsServer1: '9.9.9.9'));

      await expectLater(
          notifier.save(), throwsA(isA<SavedButUnconfirmedError>()));

      final state = container.read(uspLocalNetworkProvider);
      expect(state.status.error, isNull);
      expect(state.settings.current.model.dnsServer1, '9.9.9.9');
      expect(state.isDirty, isFalse);
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
