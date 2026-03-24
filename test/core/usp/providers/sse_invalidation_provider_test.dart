import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/models/sse_notification.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';

import '../mocks.dart';

void main() {
  late MockSseManager mockManager;
  late SseNotificationHandler capturedHandler;

  /// Sets up a [ProviderContainer] that overrides [sseManagerProvider] with
  /// [mockManager] and captures the wildcard handler callback.
  ProviderContainer createContainer() {
    when(() => mockManager.addWildcardHandler(any())).thenAnswer((invocation) {
      capturedHandler =
          invocation.positionalArguments[0] as SseNotificationHandler;
      return () {}; // cleanup function
    });

    final container = ProviderContainer(
      overrides: [
        sseManagerProvider.overrideWithValue(mockManager),
      ],
    );
    // Force the provider to build
    container.listen(sseInvalidationProvider, (_, __) {});
    return container;
  }

  /// Helper: builds a notification with the given type and path payload.
  SseNotification notification({
    required String type,
    String? paramPath,
    String? objPath,
  }) {
    final payload = <String, dynamic>{
      'subscription_id': 'cpe-1',
      'type': type,
    };
    if (type == 'ValueChange' && paramPath != null) {
      payload['value_change'] = {'param_path': paramPath};
    }
    if (type == 'ObjectCreation' && objPath != null) {
      payload['obj_creation'] = {'obj_path': objPath};
    }
    if (type == 'ObjectDeletion' && objPath != null) {
      payload['obj_deletion'] = {'obj_path': objPath};
    }
    return SseNotification(
      subscriptionId: 'cpe-1',
      type: type,
      payload: payload,
    );
  }

  setUp(() {
    mockManager = MockSseManager();
  });

  // ---------------------------------------------------------------------------
  // _extractPath (tested indirectly via provider)
  // ---------------------------------------------------------------------------
  group('_extractPath', () {
    test('ValueChange → value_change.param_path', () async {
      final container = createContainer();
      final domains = <InvalidationDomain>[];
      container.listen(sseInvalidationProvider, (_, next) {
        if (next.hasValue) domains.add(next.value!);
      });

      capturedHandler(notification(
        type: 'ValueChange',
        paramPath: 'Device.Hosts.Host.1.Active',
      ));
      await Future.delayed(Duration.zero);

      expect(domains, [InvalidationDomain.connectedDevices]);
      container.dispose();
    });

    test('ObjectCreation → obj_creation.obj_path', () async {
      final container = createContainer();
      final domains = <InvalidationDomain>[];
      container.listen(sseInvalidationProvider, (_, next) {
        if (next.hasValue) domains.add(next.value!);
      });

      capturedHandler(notification(
        type: 'ObjectCreation',
        objPath: 'Device.Hosts.Host.5.',
      ));
      await Future.delayed(Duration.zero);

      expect(domains, [InvalidationDomain.connectedDevices]);
      container.dispose();
    });

    test('ObjectDeletion → obj_deletion.obj_path', () async {
      final container = createContainer();
      final domains = <InvalidationDomain>[];
      container.listen(sseInvalidationProvider, (_, next) {
        if (next.hasValue) domains.add(next.value!);
      });

      capturedHandler(notification(
        type: 'ObjectDeletion',
        objPath: 'Device.Hosts.Host.3.',
      ));
      await Future.delayed(Duration.zero);

      expect(domains, [InvalidationDomain.connectedDevices]);
      container.dispose();
    });

    test('unknown type → null (no domain emitted)', () async {
      final container = createContainer();
      final domains = <InvalidationDomain>[];
      container.listen(sseInvalidationProvider, (_, next) {
        if (next.hasValue) domains.add(next.value!);
      });

      capturedHandler(notification(type: 'OperationComplete'));
      await Future.delayed(Duration.zero);

      expect(domains, isEmpty);
      container.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // _mapToDomain path matching
  // ---------------------------------------------------------------------------
  group('_mapToDomain path matching', () {
    late ProviderContainer container;
    late List<InvalidationDomain> domains;

    setUp(() {
      container = createContainer();
      domains = [];
      container.listen(sseInvalidationProvider, (_, next) {
        if (next.hasValue) domains.add(next.value!);
      });
    });

    tearDown(() => container.dispose());

    Future<void> sendAndExpect(
      String path,
      InvalidationDomain expected, {
      String type = 'ValueChange',
    }) async {
      domains.clear();
      if (type == 'ValueChange') {
        capturedHandler(notification(type: type, paramPath: path));
      } else {
        capturedHandler(notification(type: type, objPath: path));
      }
      await Future.delayed(Duration.zero);
      expect(domains, [expected], reason: 'path: $path');
    }

    Future<void> sendAndExpectEmpty(
      String path, {
      String type = 'ValueChange',
    }) async {
      domains.clear();
      if (type == 'ValueChange') {
        capturedHandler(notification(type: type, paramPath: path));
      } else {
        capturedHandler(notification(type: type, objPath: path));
      }
      await Future.delayed(Duration.zero);
      expect(domains, isEmpty, reason: 'path: $path');
    }

    test('Device.Hosts.Host.* → connectedDevices', () async {
      await sendAndExpect(
          'Device.Hosts.Host.1.Active', InvalidationDomain.connectedDevices);
    });

    test('Device.WiFi.SSID.* → wifiSsids', () async {
      await sendAndExpect(
          'Device.WiFi.SSID.2.SSID', InvalidationDomain.wifiSsids);
    });

    test('Device.WiFi.Radio.* → wifiRadios', () async {
      await sendAndExpect(
          'Device.WiFi.Radio.1.Channel', InvalidationDomain.wifiRadios);
    });

    test('Device.WiFi.AccessPoint.*.AssociatedDevice.* → wifiClients',
        () async {
      await sendAndExpect(
        'Device.WiFi.AccessPoint.1.AssociatedDevice.3.MACAddress',
        InvalidationDomain.wifiClients,
      );
    });

    test('Device.WiFi.AccessPoint.* (no AssociatedDevice) → wifiAccessPoints',
        () async {
      await sendAndExpect(
        'Device.WiFi.AccessPoint.1.SSIDReference',
        InvalidationDomain.wifiAccessPoints,
      );
    });

    test('Device.NAT.PortMapping.* → portForwarding', () async {
      await sendAndExpect(
        'Device.NAT.PortMapping.1.ExternalPort',
        InvalidationDomain.portForwarding,
      );
    });

    test('Device.Firewall.DMZ.* → dmz', () async {
      await sendAndExpect('Device.Firewall.DMZ.Enable', InvalidationDomain.dmz);
    });

    test('Device.Firewall.Chain.* → firewallRules', () async {
      await sendAndExpect(
        'Device.Firewall.Chain.1.Rule.1.SourceIP',
        InvalidationDomain.firewallRules,
      );
    });

    test('Device.DHCPv4.*.Client.* (not StaticAddress) → dhcpClients',
        () async {
      await sendAndExpect(
        'Device.DHCPv4.Server.Pool.1.Client.2.IPAddress',
        InvalidationDomain.dhcpClients,
      );
    });

    test('Device.DHCPv4.*.StaticAddress.* → dhcpReservations', () async {
      await sendAndExpect(
        'Device.DHCPv4.Server.Pool.1.StaticAddress.1.Chaddr',
        InvalidationDomain.dhcpReservations,
      );
    });

    test('Device.Routing.Router.*.IPv4Forwarding.* → staticRouting', () async {
      await sendAndExpect(
        'Device.Routing.Router.1.IPv4Forwarding.1.DestIPAddress',
        InvalidationDomain.staticRouting,
      );
    });

    test('path with .Stats. → filtered out (null)', () async {
      await sendAndExpectEmpty(
          'Device.WiFi.SSID.2.Stats.UnicastPacketsReceived');
    });

    test('unrecognized path → null', () async {
      await sendAndExpectEmpty('Device.SomethingUnknown.Foo.Bar');
    });

    test('empty path → null', () async {
      await sendAndExpectEmpty('');
    });
  });

  // ---------------------------------------------------------------------------
  // Provider behavior
  // ---------------------------------------------------------------------------
  group('Provider behavior', () {
    test('manager null → Stream.empty()', () async {
      final container = ProviderContainer(
        overrides: [
          sseManagerProvider.overrideWithValue(null),
        ],
      );

      final sub = container.listen(sseInvalidationProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      // Provider should build without error; no events emitted
      expect(sub.read(), isA<AsyncValue<InvalidationDomain>>());
      container.dispose();
    });

    test('adds wildcard handler on creation', () {
      final container = createContainer();
      // Force build
      container.read(sseInvalidationProvider);

      verify(() => mockManager.addWildcardHandler(any())).called(1);
      container.dispose();
    });

    test('dispose removes handler', () {
      bool cleanupCalled = false;
      when(() => mockManager.addWildcardHandler(any())).thenAnswer((_) {
        return () => cleanupCalled = true;
      });

      final container = ProviderContainer(
        overrides: [
          sseManagerProvider.overrideWithValue(mockManager),
        ],
      );
      container.listen(sseInvalidationProvider, (_, __) {});
      container.dispose();

      expect(cleanupCalled, isTrue);
    });

    test('multiple notifications → multiple domain events', () async {
      final container = createContainer();
      final domains = <InvalidationDomain>[];
      container.listen(sseInvalidationProvider, (_, next) {
        if (next.hasValue) domains.add(next.value!);
      });

      capturedHandler(notification(
        type: 'ValueChange',
        paramPath: 'Device.Hosts.Host.1.Active',
      ));
      capturedHandler(notification(
        type: 'ObjectCreation',
        objPath: 'Device.WiFi.SSID.1.',
      ));
      capturedHandler(notification(
        type: 'ValueChange',
        paramPath: 'Device.NAT.PortMapping.1.Enable',
      ));
      await Future.delayed(Duration.zero);

      expect(domains, [
        InvalidationDomain.connectedDevices,
        InvalidationDomain.wifiSsids,
        InvalidationDomain.portForwarding,
      ]);
      container.dispose();
    });
  });
}
