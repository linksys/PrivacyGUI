# Quickstart: AutoParentFirstLogin Service Extraction

**Date**: 2026-01-07
**Feature**: 001-auto-parent-login-service

---

## Overview

This guide provides quick implementation steps for extracting `AutoParentFirstLoginService` from `AutoParentFirstLoginNotifier`.

---

## Prerequisites

- Flutter SDK 3.3+
- Dart SDK 3.0+
- Project dependencies installed (`flutter pub get`)

---

## Step 1: Create Service Directory

```bash
mkdir -p lib/page/login/auto_parent/services
```

---

## Step 2: Create Service File

Create `lib/page/login/auto_parent/services/auto_parent_first_login_service.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/retry_strategy/retry.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Riverpod provider for AutoParentFirstLoginService
final autoParentFirstLoginServiceProvider = Provider<AutoParentFirstLoginService>((ref) {
  return AutoParentFirstLoginService(ref.watch(routerRepositoryProvider));
});

/// Stateless service for auto-parent first-time login operations.
class AutoParentFirstLoginService {
  AutoParentFirstLoginService(this._routerRepository);

  final RouterRepository _routerRepository;

  /// Sets userAcknowledgedAutoConfiguration flag (awaited)
  Future<void> setUserAcknowledgedAutoConfiguration() async {
    await _routerRepository.send(
      JNAPAction.setUserAcknowledgedAutoConfiguration,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
      data: {},
      auth: true,
    );
  }

  /// Fetches and sets firmware update policy to auto-update
  Future<void> setFirmwareUpdatePolicy() async {
    final firmwareUpdateSettings = await _routerRepository
        .send(JNAPAction.getFirmwareUpdateSettings, fetchRemote: true, auth: true)
        .then((value) => value.output)
        .then((output) => FirmwareUpdateSettings.fromMap(output)
            .copyWith(updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto))
        .onError((error, stackTrace) {
      return FirmwareUpdateSettings(
        updatePolicy: FirmwareUpdateSettings.firmwareUpdatePolicyAuto,
        autoUpdateWindow: FirmwareAutoUpdateWindow(startMinute: 0, durationMinutes: 240),
      );
    });

    await _routerRepository.send(
      JNAPAction.setFirmwareUpdateSettings,
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
      data: firmwareUpdateSettings.toMap(),
      auth: true,
    );
  }

  /// Checks internet connection with retry logic
  Future<bool> checkInternetConnection() async {
    final retryStrategy = ExponentialBackoffRetryStrategy(
      maxRetries: 5,
      initialDelay: const Duration(seconds: 2),
      maxDelay: const Duration(seconds: 2),
    );

    return retryStrategy.execute<bool>(() async {
      final result = await _routerRepository.send(
        JNAPAction.getInternetConnectionStatus,
        fetchRemote: true,
        auth: true,
      );
      logger.i('[FirstTime]: Internet connection status: ${result.output}');
      return result.output['connectionStatus'] == 'InternetConnected';
    }, shouldRetry: (result) => !result).onError((error, stackTrace) {
      logger.e('[FirstTime]: Error checking internet connection: $error');
      return false;
    });
  }
}
```

---

## Step 3: Refactor Provider

Update `lib/page/login/auto_parent/providers/auto_parent_first_login_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/login/auto_parent/providers/auto_parent_first_login_state.dart';
import 'package:privacy_gui/page/login/auto_parent/services/auto_parent_first_login_service.dart';

final autoParentFirstLoginProvider = NotifierProvider.autoDispose<
    AutoParentFirstLoginNotifier,
    AutoParentFirstLoginState>(() => AutoParentFirstLoginNotifier());

class AutoParentFirstLoginNotifier
    extends AutoDisposeNotifier<AutoParentFirstLoginState> {
  @override
  AutoParentFirstLoginState build() {
    return AutoParentFirstLoginState();
  }

  Future<bool> checkAndAutoInstallFirmware() async {
    ref.read(pollingProvider.notifier).paused = true;
    final fwUpdate = ref.read(firmwareUpdateProvider.notifier);
    logger.i('[FirstTime]: Do FW update check');
    await fwUpdate.fetchAvailableFirmwareUpdates();
    if (fwUpdate.isFailedCheckFirmwareUpdate()) {
      throw Exception('Failed to check firmware update');
    }
    if (fwUpdate.getAvailableUpdateNumber() > 0) {
      logger.i('[FirstTime]: New Firmware available!');
      await fwUpdate.updateFirmware();
      return true;
    } else {
      logger.i('[FirstTime]: No available FW, ready to go');
      return false;
    }
  }

  Future<void> finishFirstTimeLogin([bool failCheck = false]) async {
    final service = ref.read(autoParentFirstLoginServiceProvider);

    if (!failCheck) {
      final isConnected = await service.checkInternetConnection();
      logger.i('[FirstTime]: Internet connection status: $isConnected');
      await service.setUserAcknowledgedAutoConfiguration();
    }
    await service.setFirmwareUpdatePolicy();
  }
}
```

---

## Step 4: Create Test Data Builder

Create `test/mocks/test_data/auto_parent_first_login_test_data.dart`:

```dart
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for AutoParentFirstLoginService tests
class AutoParentFirstLoginTestData {
  static JNAPSuccess createInternetConnectionStatusSuccess({
    String connectionStatus = 'InternetConnected',
  }) => JNAPSuccess(
    result: 'ok',
    output: {'connectionStatus': connectionStatus},
  );

  static JNAPSuccess createFirmwareUpdateSettingsSuccess({
    String updatePolicy = 'AutoUpdate',
    int startMinute = 0,
    int durationMinutes = 240,
  }) => JNAPSuccess(
    result: 'ok',
    output: {
      'updatePolicy': updatePolicy,
      'autoUpdateWindow': {
        'startMinute': startMinute,
        'durationMinutes': durationMinutes,
      },
    },
  );
}
```

---

## Step 5: Verify Architecture Compliance

```bash
# Should return 0 results (no JNAP models in Provider)
grep -r "import.*jnap/models" lib/page/login/auto_parent/providers/

# Should return 0 results (no JNAP actions in Provider)
grep -r "import.*jnap/actions" lib/page/login/auto_parent/providers/

# Should return 0 results (no JNAP command in Provider)
grep -r "import.*jnap/command" lib/page/login/auto_parent/providers/

# Should find the Service (JNAP models in Service - expected)
grep -r "import.*jnap/models" lib/page/login/auto_parent/services/
```

---

## Step 6: Run Tests

```bash
# Run Service tests
flutter test test/page/login/auto_parent/services/

# Run Provider tests
flutter test test/page/login/auto_parent/providers/

# Run analyze
flutter analyze lib/page/login/auto_parent/
```

---

## Files Changed Summary

| File | Action |
|------|--------|
| `lib/page/login/auto_parent/services/auto_parent_first_login_service.dart` | NEW |
| `lib/page/login/auto_parent/providers/auto_parent_first_login_provider.dart` | MODIFIED |
| `test/mocks/test_data/auto_parent_first_login_test_data.dart` | NEW |
| `test/page/login/auto_parent/services/auto_parent_first_login_service_test.dart` | NEW |
| `test/page/login/auto_parent/providers/auto_parent_first_login_provider_test.dart` | NEW/MODIFIED |
| `test/page/login/auto_parent/providers/auto_parent_first_login_state_test.dart` | NEW |
