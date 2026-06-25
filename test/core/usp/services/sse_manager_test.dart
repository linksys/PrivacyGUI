import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/sse_connection_manager.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

import '../helpers.dart';
import '../mocks.dart';

/// Mock that captures injected callbacks instead of swallowing them.
///
/// SseManager injects `_handleSseSubscribe` and `_onTokenRefreshed` via
/// setters. The standard [MockUspClient] mocks the setters to no-op,
/// losing the references. This class stores them for direct invocation.
class _CapturingUspClient extends Mock implements UspClient {
  SseSubscribeDelegate? capturedSseSubscribe;
  VoidCallback? capturedTokenRefreshed;

  @override
  set onSseSubscribe(SseSubscribeDelegate? value) =>
      capturedSseSubscribe = value;

  @override
  SseSubscribeDelegate? get onSseSubscribe => capturedSseSubscribe;

  @override
  set onTokenRefreshed(VoidCallback? value) => capturedTokenRefreshed = value;

  @override
  VoidCallback? get onTokenRefreshed => capturedTokenRefreshed;
}

void main() {
  late MockUspBridgeClient mockBridge;
  late MockUspClient mockUsp;
  late StreamController<SseEvent> streamController;

  setUp(() {
    mockBridge = MockUspBridgeClient();
    mockUsp = MockUspClient();
    streamController = StreamController<SseEvent>();

    when(() => mockBridge.notifications())
        .thenAnswer((_) => streamController.stream);
    when(() => mockBridge.subscribe(
          subscriptionId: any(named: 'subscriptionId'),
          path: any(named: 'path'),
          notifType: any(named: 'notifType'),
        )).thenAnswer((_) async => {});
    when(() => mockBridge.unsubscribe(
          subscriptionId: any(named: 'subscriptionId'),
        )).thenAnswer((_) async => {});
    when(() => mockBridge.abortSse()).thenReturn(null);

    // UspClient property setters
    when(() => mockUsp.onSseSubscribe = any(that: anything)).thenReturn(null);
    when(() => mockUsp.onTokenRefreshed = any(that: anything)).thenReturn(null);
  });

  tearDown(() {
    if (!streamController.isClosed) {
      streamController.close();
    }
  });

  SseManager createManager() => SseManager(
        usp: mockUsp,
        bridge: mockBridge,
        strategy: FakeSseOperationStrategy(mockBridge),
      );

  // ---------------------------------------------------------------------------
  // Construction / wiring
  // ---------------------------------------------------------------------------
  group('Construction / wiring', () {
    test('creates connection, registry, router', () {
      final manager = createManager();

      expect(manager.connection, isNotNull);
      expect(manager.registry, isNotNull);
      expect(manager.router, isNotNull);

      manager.dispose();
    });

    test('connection.onEvent wired to router.routeEvent', () async {
      final manager = createManager();

      // Add a handler to router and verify it receives events through
      // the connection → router wiring
      int handlerCalled = 0;
      manager.router.addHandler('sub-1', (_) => handlerCalled++);

      await manager.connect();
      streamController.add(notificationEvent(
        subscriptionId: 'sub-1',
        type: 'ValueChange',
      ));
      await Future.delayed(Duration.zero);

      // First event transitions to connected, second event type doesn't matter
      // The notification should be routed through
      expect(handlerCalled, 1);

      await manager.dispose();
    });

    test('connection.onConnected triggers resubscribe of existing records',
        () async {
      final manager = createManager();

      // First register subscriptions via registerCoreSubscriptions
      manager.setCoreSubscriptions([
        ('wifi-vc', 'ValueChange', 'Device.WiFi.SSID.'),
      ]);
      await manager.registerCoreSubscriptions();
      expect(manager.registry.activeIds, contains('wifi-vc'));

      // Reset mock to track resubscribe calls
      reset(mockBridge);
      when(() => mockBridge.notifications())
          .thenAnswer((_) => streamController.stream);
      when(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenAnswer((_) async => {});
      when(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          )).thenAnswer((_) async => {});
      when(() => mockBridge.abortSse()).thenReturn(null);

      // Connect triggers onSseConnected which resubscribes existing records
      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(const Duration(milliseconds: 100));

      // Should have resubscribed
      verify(() => mockBridge.subscribe(
            subscriptionId: 'wifi-vc',
            path: 'Device.WiFi.SSID.',
            notifType: 1,
          )).called(1);

      await manager.dispose();
    });

    test('injects onSseSubscribe into UspClient', () {
      createManager();

      verify(() => mockUsp.onSseSubscribe = any(that: isNotNull)).called(1);
    });

    test('injects onTokenRefreshed into UspClient', () {
      createManager();

      verify(() => mockUsp.onTokenRefreshed = any(that: isNotNull)).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // subscribe
  // ---------------------------------------------------------------------------
  group('subscribe', () {
    test('registers subscription on registry', () async {
      final manager = createManager();

      await manager.subscribe(
        subscriptionId: 'test-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
        onNotification: (_) {},
      );

      expect(manager.registry.activeIds, contains('test-sub'));

      await manager.dispose();
    });

    test('adds handler on router', () async {
      final manager = createManager();

      await manager.subscribe(
        subscriptionId: 'test-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
        onNotification: (_) {},
      );

      expect(manager.router.registeredIds, contains('test-sub'));

      await manager.dispose();
    });

    test('cleanup removes handler', () async {
      final manager = createManager();

      final cleanup = await manager.subscribe(
        subscriptionId: 'test-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
        onNotification: (_) {},
      );

      await cleanup();

      expect(manager.router.registeredIds, isNot(contains('test-sub')));

      await manager.dispose();
    });

    test('cleanup unregisters subscription', () async {
      final manager = createManager();

      final cleanup = await manager.subscribe(
        subscriptionId: 'test-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
        onNotification: (_) {},
      );

      await cleanup();

      expect(manager.registry.activeIds, isNot(contains('test-sub')));

      await manager.dispose();
    });

    test('handler receives notification', () async {
      final manager = createManager();
      int handlerCalled = 0;

      await manager.subscribe(
        subscriptionId: 'test-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
        onNotification: (_) => handlerCalled++,
      );

      await manager.connect();
      streamController.add(notificationEvent(
        subscriptionId: 'test-sub',
        type: 'ValueChange',
      ));
      await Future.delayed(Duration.zero);

      expect(handlerCalled, 1);

      await manager.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // addWildcardHandler
  // ---------------------------------------------------------------------------
  group('addWildcardHandler', () {
    test('delegates to router', () {
      final manager = createManager();

      expect(manager.router.wildcardHandlerCount, 0);
      manager.addWildcardHandler((_) {});
      expect(manager.router.wildcardHandlerCount, 1);

      manager.dispose();
    });

    test('cleanup removes handler', () {
      final manager = createManager();

      final cleanup = manager.addWildcardHandler((_) {});
      expect(manager.router.wildcardHandlerCount, 1);

      cleanup();
      expect(manager.router.wildcardHandlerCount, 0);

      manager.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // setCoreSubscriptions / registerDeferredSubscriptions
  // ---------------------------------------------------------------------------
  group('setCoreSubscriptions / registerDeferredSubscriptions', () {
    test('setCoreSubscriptions stores but does not register yet', () {
      final manager = createManager();

      manager.setCoreSubscriptions([
        ('sub-1', 'ValueChange', 'Device.Test.'),
      ]);

      // No bridge call until connect
      verifyNever(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          ));

      manager.dispose();
    });

    test('registerCoreSubscriptions registers core subs', () async {
      final manager = createManager();

      manager.setCoreSubscriptions([
        ('sub-1', 'ValueChange', 'Device.WiFi.SSID.'),
        ('sub-2', 'ObjectCreation', 'Device.Hosts.Host.'),
      ]);

      // In new architecture, orchestrator calls registerCoreSubscriptions
      await manager.registerCoreSubscriptions();

      expect(manager.registry.activeIds, containsAll(['sub-1', 'sub-2']));

      await manager.dispose();
    });

    test('reconnect re-registers existing subs', () async {
      final manager = createManager();

      // First: register a subscription
      await manager.subscribe(
        subscriptionId: 'existing-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
        onNotification: (_) {},
      );

      // Simulate connect → connected
      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(const Duration(milliseconds: 100));

      // Simulate disconnect + reconnect
      await streamController.close();
      await Future.delayed(Duration.zero);

      // Create a new stream for reconnect
      final newStreamController = StreamController<SseEvent>();
      when(() => mockBridge.notifications())
          .thenAnswer((_) => newStreamController.stream);

      await manager.connection.tryReconnect();
      await Future.delayed(Duration.zero);
      newStreamController.add(heartbeatEvent());
      await Future.delayed(const Duration(milliseconds: 100));

      // Bridge.subscribe should have been called again for existing-sub
      verify(() => mockBridge.subscribe(
            subscriptionId: 'existing-sub',
            path: 'Device.Test.',
            notifType: 1,
          )).called(greaterThanOrEqualTo(2));

      newStreamController.close();
      await manager.dispose();
    });

    test('registerCoreSubscriptions registers all subscriptions', () async {
      final manager = createManager();

      manager.setCoreSubscriptions([
        ('sub-1', 'ValueChange', 'Device.Test.'),
      ]);

      await manager.registerCoreSubscriptions();

      expect(manager.registry.activeIds, contains('sub-1'));

      manager.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // dispose
  // ---------------------------------------------------------------------------
  group('dispose', () {
    test('calls connection.disconnect', () async {
      final manager = createManager();
      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);

      await manager.dispose();

      expect(manager.connection.connectionState.value,
          SseConnectionState.disconnected);
    });

    test('calls registry.unregisterAll', () async {
      final manager = createManager();

      await manager.subscribe(
        subscriptionId: 'test-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
        onNotification: (_) {},
      );

      await manager.dispose();

      expect(manager.registry.activeIds, isEmpty);
    });

    test('calls router.dispose', () async {
      final manager = createManager();
      manager.addWildcardHandler((_) {});
      manager.router.addHandler('test', (_) {});

      await manager.dispose();

      expect(manager.router.registeredIds, isEmpty);
      expect(manager.router.wildcardHandlerCount, 0);
    });

    test('clears UspClient callbacks', () async {
      final manager = createManager();

      await manager.dispose();

      verify(() => mockUsp.onSseSubscribe = null).called(1);
      verify(() => mockUsp.onTokenRefreshed = null).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // Passthrough methods
  // ---------------------------------------------------------------------------
  group('passthrough methods', () {
    test('disconnect delegates to connection', () async {
      final manager = createManager();
      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);

      expect(manager.isConnected, isTrue);
      await manager.disconnect();
      expect(manager.isConnected, isFalse);

      await manager.dispose();
    });

    test('tryReconnect delegates to connection', () async {
      final manager = createManager();

      // From disconnected state, tryReconnect should start a connection
      final result = await manager.tryReconnect();
      expect(result, isTrue);

      await manager.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // _handleSseSubscribe (SSE delegate injected into UspClient)
  // ---------------------------------------------------------------------------
  group('_handleSseSubscribe (SSE delegate)', () {
    late _CapturingUspClient capturingUsp;
    late SseManager manager;

    setUp(() {
      capturingUsp = _CapturingUspClient();
      manager = SseManager(
        usp: capturingUsp,
        bridge: mockBridge,
        strategy: FakeSseOperationStrategy(mockBridge),
      );
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('delegate is injected into UspClient', () {
      expect(capturingUsp.capturedSseSubscribe, isNotNull);
    });

    test('delegate registers subscription on registry', () async {
      final result = await capturingUsp.capturedSseSubscribe!(
        subscriptionId: 'codegen-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.WiFi.SSID.',
        onNotification: () {},
      );

      expect(manager.registry.activeIds, contains('codegen-sub'));

      // Cleanup
      result.removeHandler();
      await result.unregister();
    });

    test('delegate adds wildcard handler on router', () async {
      expect(manager.router.wildcardHandlerCount, 0);

      final result = await capturingUsp.capturedSseSubscribe!(
        subscriptionId: 'codegen-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.WiFi.SSID.',
        onNotification: () {},
      );

      expect(manager.router.wildcardHandlerCount, 1);

      result.removeHandler();
      await result.unregister();
    });

    test('wildcard handler fires on matching ValueChange notification',
        () async {
      int callCount = 0;

      final result = await capturingUsp.capturedSseSubscribe!(
        subscriptionId: 'codegen-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.WiFi.SSID.',
        onNotification: () => callCount++,
      );

      await manager.connect();
      streamController.add(notificationEvent(
        subscriptionId: 'cpe-internal-id',
        type: 'ValueChange',
        valueChange: {'param_path': 'Device.WiFi.SSID.1.SSID'},
      ));
      await Future.delayed(Duration.zero);

      expect(callCount, 1);

      result.removeHandler();
      await result.unregister();
    });

    test('wildcard handler fires on matching ObjectCreation notification',
        () async {
      int callCount = 0;

      final result = await capturingUsp.capturedSseSubscribe!(
        subscriptionId: 'codegen-sub',
        notifType: 'ObjectCreation',
        referenceList: 'Device.Hosts.Host.',
        onNotification: () => callCount++,
      );

      await manager.connect();
      streamController.add(notificationEvent(
        subscriptionId: 'cpe-internal-id',
        type: 'ObjectCreation',
        objCreation: {'obj_path': 'Device.Hosts.Host.5.'},
      ));
      await Future.delayed(Duration.zero);

      expect(callCount, 1);

      result.removeHandler();
      await result.unregister();
    });

    test('wildcard handler fires on matching ObjectDeletion notification',
        () async {
      int callCount = 0;

      final result = await capturingUsp.capturedSseSubscribe!(
        subscriptionId: 'codegen-sub',
        notifType: 'ObjectDeletion',
        referenceList: 'Device.Hosts.Host.',
        onNotification: () => callCount++,
      );

      await manager.connect();
      streamController.add(notificationEvent(
        subscriptionId: 'cpe-internal-id',
        type: 'ObjectDeletion',
        objDeletion: {'obj_path': 'Device.Hosts.Host.3.'},
      ));
      await Future.delayed(Duration.zero);

      expect(callCount, 1);

      result.removeHandler();
      await result.unregister();
    });

    test('wildcard handler ignores non-matching type', () async {
      int callCount = 0;

      final result = await capturingUsp.capturedSseSubscribe!(
        subscriptionId: 'codegen-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.WiFi.SSID.',
        onNotification: () => callCount++,
      );

      await manager.connect();
      streamController.add(notificationEvent(
        subscriptionId: 'cpe-internal-id',
        type: 'ObjectCreation',
        objCreation: {'obj_path': 'Device.WiFi.SSID.1.'},
      ));
      await Future.delayed(Duration.zero);

      expect(callCount, 0);

      result.removeHandler();
      await result.unregister();
    });

    test('wildcard handler ignores non-matching path prefix', () async {
      int callCount = 0;

      final result = await capturingUsp.capturedSseSubscribe!(
        subscriptionId: 'codegen-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.WiFi.SSID.',
        onNotification: () => callCount++,
      );

      await manager.connect();
      streamController.add(notificationEvent(
        subscriptionId: 'cpe-internal-id',
        type: 'ValueChange',
        valueChange: {'param_path': 'Device.Hosts.Host.1.Active'},
      ));
      await Future.delayed(Duration.zero);

      expect(callCount, 0);

      result.removeHandler();
      await result.unregister();
    });

    test('wildcard handler ignores unknown notification type', () async {
      int callCount = 0;

      final result = await capturingUsp.capturedSseSubscribe!(
        subscriptionId: 'codegen-sub',
        notifType: 'SomeUnknownType',
        referenceList: 'Device.Test.',
        onNotification: () => callCount++,
      );

      await manager.connect();
      streamController.add(notificationEvent(
        subscriptionId: 'cpe-internal-id',
        type: 'SomeUnknownType',
      ));
      await Future.delayed(Duration.zero);

      // _extractNotifPath returns null for unknown type → path check fails
      expect(callCount, 0);

      result.removeHandler();
      await result.unregister();
    });

    test('cleanup removes handler and unregisters subscription', () async {
      final result = await capturingUsp.capturedSseSubscribe!(
        subscriptionId: 'codegen-sub',
        notifType: 'ValueChange',
        referenceList: 'Device.Test.',
        onNotification: () {},
      );

      expect(manager.registry.activeIds, contains('codegen-sub'));
      expect(manager.router.wildcardHandlerCount, 1);

      result.removeHandler();
      await result.unregister();

      expect(manager.registry.activeIds, isNot(contains('codegen-sub')));
      expect(manager.router.wildcardHandlerCount, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // onTokenRefreshed callback
  // ---------------------------------------------------------------------------
  group('onTokenRefreshed callback', () {
    test('forces disconnect then reconnect', () async {
      final capturingUsp = _CapturingUspClient();
      final manager = SseManager(
        usp: capturingUsp,
        bridge: mockBridge,
        strategy: FakeSseOperationStrategy(mockBridge),
      );

      await manager.connect();
      streamController.add(heartbeatEvent());
      await Future.delayed(Duration.zero);
      expect(manager.isConnected, isTrue);

      // The onTokenRefreshed callback disconnects then reconnects
      // Create a new stream for the reconnection
      final newStreamController = StreamController<SseEvent>();
      when(() => mockBridge.notifications())
          .thenAnswer((_) => newStreamController.stream);

      capturingUsp.capturedTokenRefreshed!();
      await Future.delayed(const Duration(milliseconds: 100));

      // Connection should attempt reconnect (may be connecting or connected)
      expect(manager.connection.connectionState.value,
          isNot(SseConnectionState.suspended));

      newStreamController.close();
      await manager.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // registerCoreSubscriptions error handling
  // ---------------------------------------------------------------------------
  group('registerCoreSubscriptions error handling', () {
    test('logs and continues when registration fails', () async {
      // Make bridge.subscribe throw for specific subscription
      when(() => mockBridge.subscribe(
            subscriptionId: 'fail-sub',
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenThrow(Exception('bridge error'));

      final manager = createManager();

      manager.setCoreSubscriptions([
        ('fail-sub', 'ValueChange', 'Device.Fail.'),
        ('ok-sub', 'ValueChange', 'Device.OK.'),
      ]);

      // In new architecture, orchestrator calls registerCoreSubscriptions
      await manager.registerCoreSubscriptions();

      // ok-sub should still be registered despite fail-sub throwing
      expect(manager.registry.activeIds, contains('ok-sub'));

      await manager.dispose();
    });
  });
}
