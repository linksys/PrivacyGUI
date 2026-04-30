# waitingForRecovery Connection State Machine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an application-layer connection state machine that detects router unreachability, pauses background activities, probes for recovery, and auto-reconnects.

**Architecture:** A `AppConnectionStateNotifier` manages three states (`authenticated`, `waitingForRecovery`, `loggedOut`). Entry is triggered by natural signals (SSE suspended + polling 3x errors) or operational calls (WiFi SSID save). A `RecoveryProbeService` runs a health→login→serial loop until recovery or serial mismatch. Polling providers watch the connection state to self-pause. SSE is directly controlled by the notifier.

**Tech Stack:** Dart (Flutter), Riverpod, FlutterSecureStorage, mocktail

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `lib/core/connection/models/app_connection_state.dart` | Enum + trigger metadata |
| `lib/core/connection/providers/app_connection_state_provider.dart` | State machine notifier |
| `lib/core/connection/services/recovery_probe_service.dart` | Probe loop: health → login → serial |
| `lib/core/connection/services/router_fingerprint_service.dart` | Serial number CRUD in FlutterSecureStorage |
| `lib/core/connection/views/recovery_overlay.dart` | Full-screen overlay widget |
| `test/core/connection/providers/app_connection_state_provider_test.dart` | Notifier unit tests |
| `test/core/connection/services/recovery_probe_service_test.dart` | Probe service tests |
| `test/core/connection/services/router_fingerprint_service_test.dart` | Fingerprint service tests |

### Modified Files
| File | Change |
|------|--------|
| `lib/page/_shared/providers/usp_traffic_analysis_notifier.dart` | Watch connection state, pause timer when not authenticated |
| `lib/page/_shared/providers/usp_system_monitor_notifier.dart` | Watch connection state, pause timer when not authenticated |
| `lib/components/layouts/root_container.dart` | Add `RecoveryOverlay` as sibling overlay |
| `lib/page/wifi_settings/providers/usp_wifi_settings_provider.dart` | Call `enterWaiting()` after SSID save |
| `lib/providers/auth/auth_provider.dart` | Clear router fingerprint on logout |
| `lib/core/session/providers/session_provider.dart` | Store fingerprint after device info fetch |

---

## Task 1: Router Fingerprint Service

**Files:**
- Create: `lib/core/connection/services/router_fingerprint_service.dart`
- Create: `test/core/connection/services/router_fingerprint_service_test.dart`

- [ ] **Step 1: Write failing tests for RouterFingerprintService**

```dart
// test/core/connection/services/router_fingerprint_service_test.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacygui/core/connection/services/router_fingerprint_service.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late RouterFingerprintService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = RouterFingerprintService(mockStorage);
  });

  group('RouterFingerprintService', () {
    test('store saves serial number to secure storage', () async {
      when(() => mockStorage.write(
        key: 'router_fingerprint_serial',
        value: 'ABC123',
      )).thenAnswer((_) async {});

      await service.store('ABC123');

      verify(() => mockStorage.write(
        key: 'router_fingerprint_serial',
        value: 'ABC123',
      )).called(1);
    });

    test('read returns stored serial number', () async {
      when(() => mockStorage.read(key: 'router_fingerprint_serial'))
          .thenAnswer((_) async => 'ABC123');

      final result = await service.read();

      expect(result, 'ABC123');
    });

    test('read returns null when no fingerprint stored', () async {
      when(() => mockStorage.read(key: 'router_fingerprint_serial'))
          .thenAnswer((_) async => null);

      final result = await service.read();

      expect(result, isNull);
    });

    test('clear deletes the stored fingerprint', () async {
      when(() => mockStorage.delete(key: 'router_fingerprint_serial'))
          .thenAnswer((_) async {});

      await service.clear();

      verify(() => mockStorage.delete(key: 'router_fingerprint_serial')).called(1);
    });

    test('matches returns true when serial matches stored', () async {
      when(() => mockStorage.read(key: 'router_fingerprint_serial'))
          .thenAnswer((_) async => 'ABC123');

      final result = await service.matches('ABC123');

      expect(result, isTrue);
    });

    test('matches returns false when serial differs', () async {
      when(() => mockStorage.read(key: 'router_fingerprint_serial'))
          .thenAnswer((_) async => 'ABC123');

      final result = await service.matches('XYZ789');

      expect(result, isFalse);
    });

    test('matches returns false when no fingerprint stored', () async {
      when(() => mockStorage.read(key: 'router_fingerprint_serial'))
          .thenAnswer((_) async => null);

      final result = await service.matches('ABC123');

      expect(result, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/connection/services/router_fingerprint_service_test.dart`
Expected: FAIL — cannot resolve import `router_fingerprint_service.dart`

- [ ] **Step 3: Implement RouterFingerprintService**

```dart
// lib/core/connection/services/router_fingerprint_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacygui/core/utils/logger.dart';

const _kStorageKey = 'router_fingerprint_serial';

final routerFingerprintServiceProvider = Provider<RouterFingerprintService>((ref) {
  return RouterFingerprintService(const FlutterSecureStorage());
});

class RouterFingerprintService {
  RouterFingerprintService(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> store(String serialNumber) async {
    await _storage.write(key: _kStorageKey, value: serialNumber);
    logger.d('[Fingerprint] Stored serial: $serialNumber');
  }

  Future<String?> read() async {
    return _storage.read(key: _kStorageKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kStorageKey);
    logger.d('[Fingerprint] Cleared');
  }

  Future<bool> matches(String serialNumber) async {
    final stored = await read();
    if (stored == null) return false;
    return stored == serialNumber;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/connection/services/router_fingerprint_service_test.dart`
Expected: All 7 tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/connection/services/router_fingerprint_service.dart test/core/connection/services/router_fingerprint_service_test.dart
git commit -m "feat(connection): add RouterFingerprintService for serial number storage

Stores/reads/clears router serial number in FlutterSecureStorage.
Used by recovery probe to verify same router after reconnect."
```

---

## Task 2: AppConnectionState Model

**Files:**
- Create: `lib/core/connection/models/app_connection_state.dart`

- [ ] **Step 1: Create the model file**

```dart
// lib/core/connection/models/app_connection_state.dart
enum AppConnectionState {
  authenticated,
  waitingForRecovery,
  loggedOut,
}

enum RecoveryTrigger {
  natural,
  operationalWifiChange,
  operationalReboot,
  operationalFirmwareUpgrade,
}

class RecoveryContext {
  const RecoveryContext({
    required this.trigger,
    required this.cooldown,
  });

  final RecoveryTrigger trigger;
  final Duration cooldown;

  static const natural = RecoveryContext(
    trigger: RecoveryTrigger.natural,
    cooldown: Duration.zero,
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/connection/models/app_connection_state.dart
git commit -m "feat(connection): add AppConnectionState enum and RecoveryContext model"
```

---

## Task 3: Recovery Probe Service

**Files:**
- Create: `lib/core/connection/services/recovery_probe_service.dart`
- Create: `test/core/connection/services/recovery_probe_service_test.dart`

- [ ] **Step 1: Write failing tests for RecoveryProbeService**

```dart
// test/core/connection/services/recovery_probe_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacygui/core/connection/services/recovery_probe_service.dart';
import 'package:privacygui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacygui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacygui/core/usp/services/usp_bridge_client.dart';

class MockUspBridgeClient extends Mock implements UspBridgeClient {}
class MockUspAuthCoordinator extends Mock implements UspAuthCoordinator {}
class MockRouterFingerprintService extends Mock implements RouterFingerprintService {}

void main() {
  late MockUspBridgeClient mockBridge;
  late MockUspAuthCoordinator mockAuth;
  late MockRouterFingerprintService mockFingerprint;
  late RecoveryProbeService service;

  setUp(() {
    mockBridge = MockUspBridgeClient();
    mockAuth = MockUspAuthCoordinator();
    mockFingerprint = MockRouterFingerprintService();
    service = RecoveryProbeService(
      bridge: mockBridge,
      authCoordinator: mockAuth,
      fingerprintService: mockFingerprint,
    );
  });

  group('RecoveryProbeService.probe()', () {
    test('returns unreachable when health check fails', () async {
      when(() => mockBridge.health()).thenThrow(Exception('network error'));

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
      verifyNever(() => mockAuth.restoreSession());
    });

    test('returns unreachable when health OK but login fails', () async {
      when(() => mockBridge.health()).thenAnswer((_) async => {});
      when(() => mockAuth.restoreSession()).thenThrow(Exception('login failed'));

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
      verifyNever(() => mockFingerprint.matches(any()));
    });

    test('returns recovered when health OK, login OK, serial matches', () async {
      when(() => mockBridge.health()).thenAnswer((_) async => {});
      when(() => mockAuth.restoreSession()).thenAnswer((_) async => {});
      when(() => mockFingerprint.matches(any())).thenAnswer((_) async => true);
      when(() => mockAuth.getSerialNumber()).thenAnswer((_) async => 'ABC123');

      final result = await service.probe();

      expect(result, ProbeResult.recovered);
    });

    test('returns serialMismatch when health OK, login OK, serial differs', () async {
      when(() => mockBridge.health()).thenAnswer((_) async => {});
      when(() => mockAuth.restoreSession()).thenAnswer((_) async => {});
      when(() => mockAuth.getSerialNumber()).thenAnswer((_) async => 'XYZ789');
      when(() => mockFingerprint.matches('XYZ789')).thenAnswer((_) async => false);

      final result = await service.probe();

      expect(result, ProbeResult.serialMismatch);
    });

    test('returns unreachable when health OK, login OK, serial read fails', () async {
      when(() => mockBridge.health()).thenAnswer((_) async => {});
      when(() => mockAuth.restoreSession()).thenAnswer((_) async => {});
      when(() => mockAuth.getSerialNumber()).thenThrow(Exception('USP error'));

      final result = await service.probe();

      expect(result, ProbeResult.unreachable);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/connection/services/recovery_probe_service_test.dart`
Expected: FAIL — cannot resolve import

- [ ] **Step 3: Implement RecoveryProbeService**

```dart
// lib/core/connection/services/recovery_probe_service.dart
import 'package:privacygui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacygui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacygui/core/usp/services/usp_bridge_client.dart';
import 'package:privacygui/core/utils/logger.dart';

enum ProbeResult {
  unreachable,
  recovered,
  serialMismatch,
}

class RecoveryProbeService {
  RecoveryProbeService({
    required this.bridge,
    required this.authCoordinator,
    required this.fingerprintService,
  });

  final UspBridgeClient bridge;
  final UspAuthCoordinator authCoordinator;
  final RouterFingerprintService fingerprintService;

  Future<ProbeResult> probe() async {
    // Step 1: Health check (no auth required)
    try {
      await bridge.health();
      logger.d('[Recovery] Health check passed');
    } catch (e) {
      logger.d('[Recovery] Health check failed: $e');
      return ProbeResult.unreachable;
    }

    // Step 2: Restore session (login with stored password)
    try {
      await authCoordinator.restoreSession();
      logger.d('[Recovery] Session restored');
    } catch (e) {
      logger.d('[Recovery] Session restore failed: $e');
      return ProbeResult.unreachable;
    }

    // Step 3: Verify router identity via serial number
    try {
      final serial = await authCoordinator.getSerialNumber();
      final matches = await fingerprintService.matches(serial);
      if (matches) {
        logger.i('[Recovery] Serial match — recovered');
        return ProbeResult.recovered;
      } else {
        logger.w('[Recovery] Serial mismatch — different router detected');
        return ProbeResult.serialMismatch;
      }
    } catch (e) {
      logger.w('[Recovery] Serial read failed: $e');
      return ProbeResult.unreachable;
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/connection/services/recovery_probe_service_test.dart`
Expected: All 5 tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/connection/services/recovery_probe_service.dart test/core/connection/services/recovery_probe_service_test.dart
git commit -m "feat(connection): add RecoveryProbeService with health/login/serial probe

Three-step probe: health check → session restore → serial verify.
Returns unreachable, recovered, or serialMismatch."
```

---

## Task 4: AppConnectionState Notifier

**Files:**
- Create: `lib/core/connection/providers/app_connection_state_provider.dart`
- Create: `test/core/connection/providers/app_connection_state_provider_test.dart`

- [ ] **Step 1: Write failing tests for AppConnectionStateNotifier**

```dart
// test/core/connection/providers/app_connection_state_provider_test.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacygui/core/connection/models/app_connection_state.dart';
import 'package:privacygui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacygui/core/connection/services/recovery_probe_service.dart';
import 'package:privacygui/core/usp/services/sse_connection_manager.dart';
import 'package:privacygui/core/usp/services/sse_manager.dart';
import 'package:privacygui/core/usp/providers/sse_providers.dart';
import 'package:privacygui/providers/auth/auth_provider.dart';

class MockRecoveryProbeService extends Mock implements RecoveryProbeService {}
class MockSseManager extends Mock implements SseManager {}

void main() {
  late MockRecoveryProbeService mockProbe;
  late MockSseManager mockSseManager;

  setUp(() {
    mockProbe = MockRecoveryProbeService();
    mockSseManager = MockSseManager();
  });

  ProviderContainer createContainer({
    SseConnectionState sseState = SseConnectionState.connected,
  }) {
    final sseStateController = StreamController<SseConnectionState>();
    sseStateController.add(sseState);

    return ProviderContainer(
      overrides: [
        recoveryProbeServiceProvider.overrideWithValue(mockProbe),
        sseManagerProvider.overrideWithValue(mockSseManager),
        sseConnectionStateProvider.overrideWith(
          (ref) => sseStateController.stream,
        ),
      ],
    );
  }

  group('AppConnectionStateNotifier', () {
    test('initial state is authenticated', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(appConnectionStateProvider);
      expect(state, AppConnectionState.authenticated);
    });

    test('enterWaiting transitions to waitingForRecovery', () {
      final container = createContainer();
      addTearDown(container.dispose);

      container.read(appConnectionStateProvider.notifier).enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalWifiChange,
          cooldown: Duration.zero,
        ),
      );

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.waitingForRecovery,
      );
    });

    test('enterWaiting does nothing if already in waitingForRecovery', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalWifiChange,
          cooldown: Duration.zero,
        ),
      );
      // Second call should not throw or change behavior
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalReboot,
          cooldown: Duration.zero,
        ),
      );

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.waitingForRecovery,
      );
    });

    test('reportConnectivityFailure triggers waiting when SSE is suspended', () async {
      final container = createContainer(
        sseState: SseConnectionState.suspended,
      );
      addTearDown(container.dispose);

      // Allow SSE state to propagate
      await Future.delayed(Duration.zero);

      container.read(appConnectionStateProvider.notifier)
          .reportConnectivityFailure();

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.waitingForRecovery,
      );
    });

    test('reportConnectivityFailure does NOT trigger waiting when SSE is connected', () {
      final container = createContainer(
        sseState: SseConnectionState.connected,
      );
      addTearDown(container.dispose);

      container.read(appConnectionStateProvider.notifier)
          .reportConnectivityFailure();

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.authenticated,
      );
    });

    test('recovery probe returning recovered transitions to authenticated', () async {
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.recovered);
      when(() => mockSseManager.connect()).thenAnswer((_) async => {});

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalWifiChange,
          cooldown: Duration.zero,
        ),
      );

      // Wait for first probe to execute
      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.authenticated,
      );
      verify(() => mockSseManager.connect()).called(1);
    });

    test('recovery probe returning serialMismatch transitions to loggedOut', () async {
      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.serialMismatch);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalWifiChange,
          cooldown: Duration.zero,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
      );
    });

    test('exitToLogout stops probe loop and transitions to loggedOut', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appConnectionStateProvider.notifier);
      notifier.enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalWifiChange,
          cooldown: Duration(seconds: 30), // long cooldown so probe won't run
        ),
      );

      notifier.exitToLogout();

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
      );
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/connection/providers/app_connection_state_provider_test.dart`
Expected: FAIL — cannot resolve imports

- [ ] **Step 3: Implement AppConnectionStateNotifier**

```dart
// lib/core/connection/providers/app_connection_state_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacygui/core/connection/models/app_connection_state.dart';
import 'package:privacygui/core/connection/services/recovery_probe_service.dart';
import 'package:privacygui/core/connection/services/router_fingerprint_service.dart';
import 'package:privacygui/core/usp/providers/sse_providers.dart';
import 'package:privacygui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacygui/core/usp/services/sse_connection_manager.dart';
import 'package:privacygui/core/usp/services/usp_bridge_client.dart';
import 'package:privacygui/core/utils/logger.dart';
import 'package:privacygui/providers/auth/auth_provider.dart';

final recoveryProbeServiceProvider = Provider<RecoveryProbeService>((ref) {
  final bridge = ref.watch(uspBridgeClientProvider);
  final auth = ref.watch(uspAuthCoordinatorProvider);
  final fingerprint = ref.watch(routerFingerprintServiceProvider);
  return RecoveryProbeService(
    bridge: bridge!,
    authCoordinator: auth,
    fingerprintService: fingerprint,
  );
});

final appConnectionStateProvider =
    NotifierProvider<AppConnectionStateNotifier, AppConnectionState>(
      AppConnectionStateNotifier.new,
    );

class AppConnectionStateNotifier extends Notifier<AppConnectionState> {
  Timer? _probeTimer;
  bool _sseSuspended = false;

  @override
  AppConnectionState build() {
    ref.listen(sseConnectionStateProvider, (_, next) {
      final sseState = next.valueOrNull;
      _sseSuspended = sseState == SseConnectionState.suspended;
    });

    ref.onDispose(() {
      _probeTimer?.cancel();
    });

    return AppConnectionState.authenticated;
  }

  void enterWaiting({required RecoveryContext context}) {
    if (state == AppConnectionState.waitingForRecovery) return;

    logger.i('[Connection] Entering waitingForRecovery '
        '(trigger: ${context.trigger}, cooldown: ${context.cooldown})');

    state = AppConnectionState.waitingForRecovery;

    // Disconnect SSE immediately
    ref.read(sseManagerProvider)?.disconnect();

    // Start probe loop after cooldown
    if (context.cooldown == Duration.zero) {
      _startProbeLoop();
    } else {
      Timer(context.cooldown, _startProbeLoop);
    }
  }

  void reportConnectivityFailure() {
    if (state != AppConnectionState.authenticated) return;
    if (!_sseSuspended) return;

    logger.i('[Connection] Natural trigger: SSE suspended + polling failure');
    enterWaiting(context: RecoveryContext.natural);
  }

  void exitToLogout() {
    _probeTimer?.cancel();
    _probeTimer = null;
    state = AppConnectionState.loggedOut;
    logger.i('[Connection] Manual exit to loggedOut');
    ref.read(authProvider.notifier).logout();
  }

  void _startProbeLoop() {
    _probeTimer?.cancel();
    _runProbe(); // run immediately, then repeat
    _probeTimer = Timer.periodic(const Duration(seconds: 5), (_) => _runProbe());
  }

  Future<void> _runProbe() async {
    if (state != AppConnectionState.waitingForRecovery) {
      _probeTimer?.cancel();
      return;
    }

    final probeService = ref.read(recoveryProbeServiceProvider);
    final result = await probeService.probe();

    switch (result) {
      case ProbeResult.unreachable:
        // Continue waiting
        break;
      case ProbeResult.recovered:
        _probeTimer?.cancel();
        _probeTimer = null;
        state = AppConnectionState.authenticated;
        logger.i('[Connection] Recovered — reconnecting SSE');
        ref.read(sseManagerProvider)?.connect();
        break;
      case ProbeResult.serialMismatch:
        _probeTimer?.cancel();
        _probeTimer = null;
        state = AppConnectionState.loggedOut;
        logger.w('[Connection] Serial mismatch — force logout');
        ref.read(authProvider.notifier).logout();
        break;
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/connection/providers/app_connection_state_provider_test.dart`
Expected: All 7 tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/connection/providers/app_connection_state_provider.dart test/core/connection/providers/app_connection_state_provider_test.dart
git commit -m "feat(connection): add AppConnectionStateNotifier with probe loop

Manages authenticated/waitingForRecovery/loggedOut transitions.
Supports natural (SSE+polling) and operational (explicit) triggers.
Runs recovery probe loop after configurable cooldown."
```

---

## Task 5: Integrate Fingerprint Storage into Session/Auth Flow

**Files:**
- Modify: `lib/core/session/providers/session_provider.dart`
- Modify: `lib/providers/auth/auth_provider.dart`

- [ ] **Step 1: Store fingerprint after device info fetch**

In `lib/core/session/providers/session_provider.dart`, find `fetchDeviceInfoAndInitializeServices()` and add fingerprint storage after successful fetch:

```dart
// After the existing deviceInfo assignment, add:
final serial = deviceInfo.serialNumber;
if (serial != null && serial.isNotEmpty) {
  await ref.read(routerFingerprintServiceProvider).store(serial);
}
```

Import needed:
```dart
import 'package:privacygui/core/connection/services/router_fingerprint_service.dart';
```

- [ ] **Step 2: Clear fingerprint on logout**

In `lib/providers/auth/auth_provider.dart`, within the `logout()` method, add before `clearAllCredentials()`:

```dart
await ref.read(routerFingerprintServiceProvider).clear();
```

Import needed:
```dart
import 'package:privacygui/core/connection/services/router_fingerprint_service.dart';
```

- [ ] **Step 3: Run existing session/auth tests to verify no regressions**

Run: `flutter test test/providers/auth/`
Expected: PASS (fingerprint calls are additive, won't break existing tests)

- [ ] **Step 4: Commit**

```bash
git add lib/core/session/providers/session_provider.dart lib/providers/auth/auth_provider.dart
git commit -m "feat(connection): store/clear router fingerprint in session lifecycle

Store serial number after device info fetch (dashboard init).
Clear on logout."
```

---

## Task 6: Polling Providers Watch Connection State

**Files:**
- Modify: `lib/page/_shared/providers/usp_traffic_analysis_notifier.dart`
- Modify: `lib/page/_shared/providers/usp_system_monitor_notifier.dart`

- [ ] **Step 1: Add connection state watch to TrafficAnalysis notifier**

In `lib/page/_shared/providers/usp_traffic_analysis_notifier.dart`, add import:

```dart
import 'package:privacygui/core/connection/models/app_connection_state.dart';
import 'package:privacygui/core/connection/providers/app_connection_state_provider.dart';
```

In the `build()` method, add a listener that pauses/resumes polling:

```dart
ref.listen(appConnectionStateProvider, (prev, next) {
  if (next != AppConnectionState.authenticated) {
    _timer?.cancel();
    _timer = null;
  }
});
```

In `_fetchAndAppend()`, add a guard at the top:

```dart
final connectionState = ref.read(appConnectionStateProvider);
if (connectionState != AppConnectionState.authenticated) return;
```

Also add consecutive error tracking. Add a field:

```dart
int _consecutiveErrors = 0;
static const _errorThreshold = 3;
```

In `_fetchAndAppend()`, wrap the fetch in error handling that counts connectivity errors:

```dart
// On ConnectivityError:
_consecutiveErrors++;
if (_consecutiveErrors >= _errorThreshold) {
  ref.read(appConnectionStateProvider.notifier).reportConnectivityFailure();
}

// On success:
_consecutiveErrors = 0;
```

- [ ] **Step 2: Add connection state watch to SystemMonitor notifier**

Apply the same pattern to `lib/page/_shared/providers/usp_system_monitor_notifier.dart`:

```dart
import 'package:privacygui/core/connection/models/app_connection_state.dart';
import 'package:privacygui/core/connection/providers/app_connection_state_provider.dart';
```

Same listener in `build()`, same guard in fetch method, same consecutive error counter with `reportConnectivityFailure()`.

- [ ] **Step 3: Run polling tests**

Run: `flutter test test/page/_shared/providers/`
Expected: PASS (new watches and guards are additive)

- [ ] **Step 4: Commit**

```bash
git add lib/page/_shared/providers/usp_traffic_analysis_notifier.dart lib/page/_shared/providers/usp_system_monitor_notifier.dart
git commit -m "feat(connection): polling providers pause on waitingForRecovery

TrafficAnalysis and SystemMonitor watch appConnectionState.
Cancel timers when not authenticated.
Report consecutive connectivity errors to trigger natural entry."
```

---

## Task 7: Recovery Overlay UI

**Files:**
- Create: `lib/core/connection/views/recovery_overlay.dart`
- Modify: `lib/components/layouts/root_container.dart`

- [ ] **Step 1: Create RecoveryOverlay widget**

```dart
// lib/core/connection/views/recovery_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacygui/core/connection/models/app_connection_state.dart';
import 'package:privacygui/core/connection/providers/app_connection_state_provider.dart';

class RecoveryOverlay extends ConsumerWidget {
  const RecoveryOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(appConnectionStateProvider);

    return Stack(
      children: [
        child,
        if (connectionState == AppConnectionState.waitingForRecovery)
          _RecoveryModal(
            onReturnToLogin: () {
              ref.read(appConnectionStateProvider.notifier).exitToLogout();
            },
          ),
      ],
    );
  }
}

class _RecoveryModal extends StatelessWidget {
  const _RecoveryModal({required this.onReturnToLogin});

  final VoidCallback onReturnToLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.router_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(height: 24),
                Text(
                  'Waiting for router...',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'The router is restarting. The app will reconnect automatically.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 48),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onReturnToLogin,
                  child: const Text('Return to login page'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Note:** This uses basic Material widgets as a starting point. During implementation, search `ui_kit_library` for equivalent components (buttons, text styles, icons) and replace. If a component is missing from ui_kit_library, ask before implementing custom.

- [ ] **Step 2: Integrate RecoveryOverlay in AppRootContainer**

In `lib/components/layouts/root_container.dart`, import and wrap:

```dart
import 'package:privacygui/core/connection/views/recovery_overlay.dart';
```

In the `build()` method, wrap the existing `IdleChecker` widget with `RecoveryOverlay`:

```dart
return LayoutBuilder(builder: ((context, constraints) {
  return RecoveryOverlay(
    child: IdleChecker(
      // ... existing code
    ),
  );
}));
```

- [ ] **Step 3: Verify UI manually**

Run: `flutter run -d chrome`
- Verify the overlay does NOT appear during normal operation
- (Full integration testing requires router disconnection — covered in Task 9)

- [ ] **Step 4: Commit**

```bash
git add lib/core/connection/views/recovery_overlay.dart lib/components/layouts/root_container.dart
git commit -m "feat(connection): add RecoveryOverlay full-screen UI

Shows waiting state with spinner and return-to-login button.
Integrated in AppRootContainer, blocks all interaction during recovery."
```

---

## Task 8: WiFi SSID Save Operational Trigger

**Files:**
- Modify: `lib/page/wifi_settings/providers/usp_wifi_settings_provider.dart`

- [ ] **Step 1: Add enterWaiting call after SSID save**

In `lib/page/wifi_settings/providers/usp_wifi_settings_provider.dart`, add import:

```dart
import 'package:privacygui/core/connection/models/app_connection_state.dart';
import 'package:privacygui/core/connection/providers/app_connection_state_provider.dart';
```

In the `save()` method, after `super.save()` completes successfully, add:

```dart
@override
Future<UspWifiSettingsState> save() async {
  state = state.copyWith(status: state.status.copyWith(isSaving: true));
  try {
    final result = await super.save();
    // Trigger recovery waiting after successful SSID change
    ref.read(appConnectionStateProvider.notifier).enterWaiting(
      context: RecoveryContext(
        trigger: RecoveryTrigger.operationalWifiChange,
        cooldown: const Duration(seconds: 3),
      ),
    );
    return result;
  } on ServiceError catch (e) {
    logger.e('[USP][WiFi] Save failed', error: e);
    rethrow;
  } finally {
    state = state.copyWith(status: state.status.copyWith(isSaving: false));
  }
}
```

- [ ] **Step 2: Consider scope — only trigger for SSID name changes**

The overlay should only trigger when SSID name changes (which causes WiFi restart), not for password-only changes. Add a check:

```dart
// Only enter waiting if SSID name actually changed (causes WiFi restart)
final ssidChanged = state.settings.original.networks.any((orig) {
  final current = state.settings.current.networks.firstWhere(
    (n) => n.id == orig.id,
    orElse: () => orig,
  );
  return orig.ssid != current.ssid;
});

if (ssidChanged) {
  ref.read(appConnectionStateProvider.notifier).enterWaiting(
    context: RecoveryContext(
      trigger: RecoveryTrigger.operationalWifiChange,
      cooldown: const Duration(seconds: 3),
    ),
  );
}
```

- [ ] **Step 3: Run WiFi settings tests**

Run: `flutter test test/page/wifi_settings/`
Expected: PASS (the enterWaiting call won't affect existing test mocks)

- [ ] **Step 4: Commit**

```bash
git add lib/page/wifi_settings/providers/usp_wifi_settings_provider.dart
git commit -m "feat(connection): trigger waitingForRecovery after WiFi SSID change

Only triggers when SSID name changes (causes WiFi restart).
Uses 3s cooldown before probe loop starts."
```

---

## Task 9: Add getSerialNumber to UspAuthCoordinator

**Files:**
- Modify: `lib/core/usp/providers/usp_auth_coordinator.dart`

- [ ] **Step 1: Add getSerialNumber method**

The `RecoveryProbeService` needs to read the serial number after login succeeds. Add a method to `UspAuthCoordinator`:

```dart
Future<String> getSerialNumber() async {
  final result = await _usp.get('Device.DeviceInfo.SerialNumber');
  return result.value as String;
}
```

This uses the already-authenticated USP client to read the serial number path.

- [ ] **Step 2: Run existing auth coordinator tests**

Run: `flutter test test/core/usp/providers/`
Expected: PASS (additive method, doesn't change existing behavior)

- [ ] **Step 3: Commit**

```bash
git add lib/core/usp/providers/usp_auth_coordinator.dart
git commit -m "feat(connection): add getSerialNumber() to UspAuthCoordinator

Used by recovery probe to verify router identity after re-login."
```

---

## Task 10: Integration Test — Full Recovery Flow

**Files:**
- Create: `test/core/connection/integration/recovery_flow_test.dart`

- [ ] **Step 1: Write integration test for full natural trigger flow**

```dart
// test/core/connection/integration/recovery_flow_test.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacygui/core/connection/models/app_connection_state.dart';
import 'package:privacygui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacygui/core/connection/services/recovery_probe_service.dart';
import 'package:privacygui/core/usp/providers/sse_providers.dart';
import 'package:privacygui/core/usp/services/sse_connection_manager.dart';
import 'package:privacygui/core/usp/services/sse_manager.dart';

class MockRecoveryProbeService extends Mock implements RecoveryProbeService {}
class MockSseManager extends Mock implements SseManager {}

void main() {
  group('Recovery flow integration', () {
    test('natural trigger → probe recovers → back to authenticated', () async {
      final mockProbe = MockRecoveryProbeService();
      final mockSse = MockSseManager();

      // First probe: unreachable. Second probe: recovered.
      var probeCount = 0;
      when(() => mockProbe.probe()).thenAnswer((_) async {
        probeCount++;
        return probeCount >= 2 ? ProbeResult.recovered : ProbeResult.unreachable;
      });
      when(() => mockSse.connect()).thenAnswer((_) async => {});
      when(() => mockSse.disconnect()).thenReturn(null);

      final sseController = StreamController<SseConnectionState>();
      sseController.add(SseConnectionState.suspended);

      final container = ProviderContainer(
        overrides: [
          recoveryProbeServiceProvider.overrideWithValue(mockProbe),
          sseManagerProvider.overrideWithValue(mockSse),
          sseConnectionStateProvider.overrideWith((ref) => sseController.stream),
        ],
      );
      addTearDown(container.dispose);

      // Allow SSE state to propagate
      await Future.delayed(Duration.zero);

      // Simulate polling failure triggering natural entry
      container.read(appConnectionStateProvider.notifier)
          .reportConnectivityFailure();

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.waitingForRecovery,
      );

      // Wait for probe loop (runs immediately + 5s interval)
      // First probe: unreachable. Second probe at ~5s: recovered.
      await Future.delayed(const Duration(seconds: 6));

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.authenticated,
      );
      verify(() => mockSse.connect()).called(1);
    });

    test('operational trigger → serial mismatch → loggedOut', () async {
      final mockProbe = MockRecoveryProbeService();
      final mockSse = MockSseManager();

      when(() => mockProbe.probe())
          .thenAnswer((_) async => ProbeResult.serialMismatch);
      when(() => mockSse.disconnect()).thenReturn(null);

      final container = ProviderContainer(
        overrides: [
          recoveryProbeServiceProvider.overrideWithValue(mockProbe),
          sseManagerProvider.overrideWithValue(mockSse),
          sseConnectionStateProvider.overrideWith(
            (ref) => Stream.value(SseConnectionState.connected),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(appConnectionStateProvider.notifier).enterWaiting(
        context: RecoveryContext(
          trigger: RecoveryTrigger.operationalWifiChange,
          cooldown: Duration.zero,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(
        container.read(appConnectionStateProvider),
        AppConnectionState.loggedOut,
      );
    });
  });
}
```

- [ ] **Step 2: Run integration tests**

Run: `flutter test test/core/connection/integration/recovery_flow_test.dart`
Expected: All 2 tests PASS

- [ ] **Step 3: Commit**

```bash
git add test/core/connection/integration/recovery_flow_test.dart
git commit -m "test(connection): add integration tests for recovery flow

Tests natural trigger + recovery, and operational trigger + serial mismatch."
```

---

## Task 11: Manual End-to-End Verification

- [ ] **Step 1: Run full test suite**

Run: `./run_tests.sh`
Expected: All tests PASS, no regressions

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No errors (warnings acceptable)

- [ ] **Step 3: Manual test — WiFi SSID change flow**

1. `flutter run -d chrome`
2. Login to a connected router
3. Navigate to WiFi Settings
4. Change SSID name
5. Save
6. Verify: overlay appears immediately ("Waiting for router...")
7. Reconnect to new WiFi SSID
8. Verify: overlay disappears, app resumes normally

- [ ] **Step 4: Manual test — Return to login button**

1. Trigger waitingForRecovery (change SSID)
2. While overlay is showing, tap "Return to login page"
3. Verify: navigates to login page, probe loop stops

- [ ] **Step 5: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "fix(connection): address issues found during manual testing"
```
