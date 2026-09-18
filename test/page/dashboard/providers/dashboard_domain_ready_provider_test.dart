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

  // ---------------------------------------------------------------------------
  // Characterization: notification delivery on re-run.
  //
  // The tests above only assert that the future RESOLVES. None of them asserts
  // that listeners are notified, which is the property three call sites depend
  // on:
  //
  //   lib/page/_shared/providers/usp_system_monitor_notifier.dart:43
  //     if (next is AsyncData) -> starts the 30s polling timer
  //   lib/page/_shared/providers/usp_traffic_analysis_notifier.dart:44
  //     if (next is AsyncData) -> starts the 10s polling timer
  //   lib/page/remote_assistance/views/remote_assistance_session_guard.dart:42
  //     if (prev?.isLoading == true && next.hasValue) -> restores the session
  //
  // This is a `FutureProvider<void>`, so every successful completion is
  // `AsyncData<void>(null)` — the most collapsible value shape there is. Two
  // consecutive completions are `==`. Today the notification arrives regardless,
  // because riverpod 2.6.1 notifies unconditionally for data -> data
  // (`riverpod-2.6.1/lib/src/async_notifier/base.dart:177`).
  //
  // MEASURED, and not what one would guess: the frame between two completions
  // is NOT `AsyncLoading`. Refreshing a provider that already holds data yields
  // `AsyncData<void>(isLoading: true, value: null)` — still an `AsyncData`, via
  // `copyWithPrevious`. Two consequences:
  //
  //   * `next is AsyncData` is TRUE for that middle frame, so the two polling
  //     notifiers above fire on the refresh frame as well as the completion —
  //     twice per invalidate, the first while the domain fetch is still in
  //     flight. That is a live defect, not a migration risk: each firing runs
  //     `setRefreshInterval`, which calls `_fetchAndAppend()` unconditionally,
  //     and `isFetching` is written but never read as a re-entrancy guard — so
  //     it costs one redundant USP round-trip per notifier per invalidate. It is
  //     not a timer leak (`setRefreshInterval` cancels first). Verdicted
  //     `redundant-today` and owned by #1502; deliberately NOT fixed here,
  //     because these tests characterize the provider, not its listeners.
  //     The RA guard is immune — it latches on `_checkDone`.
  //   * The only thing distinguishing the middle frame from its neighbours is
  //     the `isLoading` flag. That flag, not a runtimeType change, is what
  //     would keep an `==`-based predicate from collapsing the sequence.
  //
  // The tests below pin the exact three-frame sequence rather than a count, so
  // a change to either the value shape or the loading transition breaks loudly.
  // Failure mode if it regresses: neither dashboard polling timer ever starts
  // and the Network Health / traffic cards stay silently empty. See #1501.
  // ---------------------------------------------------------------------------
  group('dashboardDomainReadyProvider — notification contract', () {
    /// Compact label for an `AsyncValue<void>`.
    ///
    /// Reports `isLoading` separately from the state class, because a refreshing
    /// `AsyncData` sets the flag without changing the class — the distinction
    /// these tests exist to record.
    String label(AsyncValue<void> v) {
      final kind = switch (v) {
        AsyncError() => 'error',
        AsyncLoading() => 'loading',
        _ => 'data',
      };
      return '$kind(hasValue=${v.hasValue},isLoading=${v.isLoading})';
    }

    ProviderContainer okContainer() => ProviderContainer(overrides: [
          systemInfoDataProvider.overrideWith(_OkSystemInfoNotifier.new),
          devicesDataProvider.overrideWith(_OkDevicesNotifier.new),
          ethernetDataProvider.overrideWith(_OkEthernetNotifier.new),
        ]);

    test('first completion notifies with data', () async {
      final container = okContainer();
      addTearDown(container.dispose);

      final seen = <String>[];
      container.listen(
          dashboardDomainReadyProvider, (_, next) => seen.add(label(next)));

      await container.read(dashboardDomainReadyProvider.future);
      await Future.delayed(Duration.zero);

      expect(seen, ['data(hasValue=true,isLoading=false)'],
          reason: 'the polling timers start on this single notification');
    });

    test('re-run after invalidate notifies twice: refreshing data, then data',
        () async {
      final container = okContainer();
      addTearDown(container.dispose);

      final seen = <String>[];
      container.listen(
          dashboardDomainReadyProvider, (_, next) => seen.add(label(next)));

      await container.read(dashboardDomainReadyProvider.future);
      await Future.delayed(Duration.zero);
      seen.clear();

      container.invalidate(dashboardDomainReadyProvider);
      await container.read(dashboardDomainReadyProvider.future);
      await Future.delayed(Duration.zero);

      // Both frames are AsyncData. The first is the refresh frame carrying the
      // previous value forward with isLoading set — which is what makes the RA
      // guard's `prev?.isLoading == true && next.hasValue` transition fire on
      // the second, and what makes the two polling notifiers' bare
      // `next is AsyncData` check fire on BOTH.
      expect(
        seen,
        [
          'data(hasValue=true,isLoading=true)',
          'data(hasValue=true,isLoading=false)',
        ],
        reason: 'a second identical AsyncData<void>(null) must still be '
            'delivered; the isLoading flag on the refresh frame is the only '
            'thing separating the two completions',
      );
    });

    test('two settled completions are == but both notify', () async {
      final container = okContainer();
      addTearDown(container.dispose);

      final values = <AsyncValue<void>>[];
      container.listen(dashboardDomainReadyProvider, (_, next) {
        // Settled data frames only — skip the refreshing AsyncData in between.
        if (next.hasValue && !next.isLoading) values.add(next);
      });

      await container.read(dashboardDomainReadyProvider.future);
      container.invalidate(dashboardDomainReadyProvider);
      await container.read(dashboardDomainReadyProvider.future);
      await Future.delayed(Duration.zero);

      expect(values, hasLength(2));
      // Spelled out so the reason the delivery is fragile is testable, not just
      // asserted in a comment.
      expect(values[0], values[1],
          reason: 'both completions are AsyncData<void>(null), so an '
              '==-based updateShouldNotify would drop the second');
    });
  });
}
