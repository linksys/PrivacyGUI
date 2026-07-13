import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Fake notifiers — override build() to avoid real USP dependencies
// ---------------------------------------------------------------------------

const _stubSystemInfo = SystemInfoUIModel(
  manufacturer: 'Test',
  modelName: 'TestRouter',
  serialNumber: 'SN123',
  hardwareVersion: '1.0',
  softwareVersion: '1.0.0',
  uptime: 0,
  totalMemory: 0,
  freeMemory: 0,
  cpuUsage: 0,
);

class _OkSystemInfoNotifier extends SystemInfoDataNotifier {
  @override
  Future<SystemInfoData> build() async =>
      SystemInfoData(model: _stubSystemInfo);
}

class _FailSystemInfoNotifier extends SystemInfoDataNotifier {
  @override
  Future<SystemInfoData> build() async => throw Exception('sysinfo fail');
}

class _OkDevicesNotifier extends DevicesDataNotifier {
  @override
  Future<DevicesData> build() async => DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(deviceId: 'GATEWAY', model: 'TestRouter'),
        ),
      );
}

class _FailDevicesNotifier extends DevicesDataNotifier {
  @override
  Future<DevicesData> build() async => throw Exception('devices fail');
}

class _OkEthernetNotifier extends EthernetDataNotifier {
  @override
  Future<EthernetData> build() async => EthernetData();
}

class _FailEthernetNotifier extends EthernetDataNotifier {
  @override
  Future<EthernetData> build() async => throw Exception('ethernet fail');
}

class _SlowDevicesNotifier extends DevicesDataNotifier {
  final Completer<void> _gate;
  _SlowDevicesNotifier(this._gate);
  @override
  Future<DevicesData> build() async {
    await _gate.future;
    return DevicesData(
      meshNetwork: MeshNetwork(
        master: MasterNode(deviceId: 'GATEWAY', model: 'TestRouter'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('dashboardDomainReadyProvider', () {
    test('resolves when all three succeed', () async {
      final container = ProviderContainer(overrides: [
        systemInfoDataProvider.overrideWith(_OkSystemInfoNotifier.new),
        devicesDataProvider.overrideWith(_OkDevicesNotifier.new),
        ethernetDataProvider.overrideWith(_OkEthernetNotifier.new),
      ]);
      addTearDown(container.dispose);

      await container.read(dashboardDomainReadyProvider.future);
      // No error → passed
    });

    test('resolves when one domain fails', () async {
      final container = ProviderContainer(overrides: [
        systemInfoDataProvider.overrideWith(_FailSystemInfoNotifier.new),
        devicesDataProvider.overrideWith(_OkDevicesNotifier.new),
        ethernetDataProvider.overrideWith(_OkEthernetNotifier.new),
      ]);
      addTearDown(container.dispose);

      // Should still resolve — individual errors are caught
      await container.read(dashboardDomainReadyProvider.future);
    });

    test('resolves when all domains fail', () async {
      final container = ProviderContainer(overrides: [
        systemInfoDataProvider.overrideWith(_FailSystemInfoNotifier.new),
        devicesDataProvider.overrideWith(_FailDevicesNotifier.new),
        ethernetDataProvider.overrideWith(_FailEthernetNotifier.new),
      ]);
      addTearDown(container.dispose);

      // Should still resolve (not error) — all errors individually caught
      await container.read(dashboardDomainReadyProvider.future);
    });

    test('waits for slowest domain', () async {
      final gate = Completer<void>();

      final container = ProviderContainer(overrides: [
        systemInfoDataProvider.overrideWith(_OkSystemInfoNotifier.new),
        devicesDataProvider.overrideWith(() => _SlowDevicesNotifier(gate)),
        ethernetDataProvider.overrideWith(_OkEthernetNotifier.new),
      ]);
      addTearDown(container.dispose);

      var resolved = false;
      final future = container
          .read(dashboardDomainReadyProvider.future)
          .then((_) => resolved = true);

      // Give microtasks a chance to settle
      await Future.delayed(Duration.zero);
      expect(resolved, isFalse);

      // Complete the slow domain
      gate.complete();
      await future;
      expect(resolved, isTrue);
    });
  });
}
