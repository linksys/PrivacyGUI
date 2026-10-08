import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/providers/remote_assistance_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';

import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';

final autoIPoEServiceProvider = Provider<AutoIPoEService>((ref) {
  final supported =
      ref.watch(deviceCapabilitiesProvider).has(DeviceCapability.autoIPoE);
  if (!supported) throw const ResourceNotFoundError();
  var active = true;
  ref.onDispose(() => active = false);
  final client = ref.watch(uspClientProvider);
  if (client == null) throw const ServiceNotInitializedError();
  // Rebinding keeps the client identity stable. The new config refreshes the
  // session cache; the captured generation also fences work queued before it.
  final remoteConfig =
      ref.watch(remoteAssistanceProvider.select((state) => state.config));
  // Follow login/client changes, including direct navigation before root setup.
  final loginType = ref.watch(authProvider.select((s) => s.value?.loginType));
  final coordinator = ref.watch(uspAuthCoordinatorProvider);
  return AutoIPoEService(
    client,
    isAvailable: () => active,
    connectionGeneration: client.connectionGeneration,
    storageScope: remoteConfig?.sessionId,
    ensureSession: () async {
      if (loginType == LoginType.remote || client.isAuthenticated) return;
      await coordinator.restoreSession(isRecovering: true);
      if (!client.isAuthenticated) throw const NotAuthenticatedError();
    },
  );
});

/// Native FLWRT adapter. All transport errors cross the ServiceError boundary.
class AutoIPoEService {
  AutoIPoEService(this.client,
      {this.ensureSession,
      this.isAvailable,
      int? connectionGeneration,
      String? storageScope})
      : _connectionGeneration = connectionGeneration,
        _storageScope = storageScope;

  /// The composition root fences a service when device support or session changes.
  final bool Function()? isAvailable;
  final String? _storageScope;
  final int? _connectionGeneration;

  /// Refuses work belonging to a connection replaced on the stable USP client.
  void checkConnection() {
    if (isAvailable?.call() == false) throw const ResourceNotFoundError();
    if (_connectionGeneration != null &&
        client.connectionGeneration != _connectionGeneration) {
      throw const NotAuthenticatedError();
    }
  }

  final Future<void> Function()? ensureSession;
  final UspClient client;
  static const object = 'Device.X_LINKSYS_AutoIPoE.';
  String get _storageKey => 'auto-ipoe-submission:${client.baseUrl}'
      '${_storageScope == null ? '' : ':session:${Uri.encodeComponent(_storageScope)}'}';

  static Map<String, dynamic> decodeObject(Object? raw) {
    if (raw is! String || raw.length > 131072) throw const InvalidInputError();
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic>) throw const InvalidInputError();
    return value;
  }

  Future<AutoIPoESnapshot> fetch() async {
    try {
      checkConnection();
      await ensureSession?.call();
      checkConnection();
      final raw = await client.get([
        '${object}APIVersion',
        '${object}Capabilities',
        '${object}Settings',
        '${object}Status',
        '${object}Log',
      ], fresh: true);
      checkConnection();
      if (raw['${object}APIVersion']?.toString() != '1') {
        throw const ResourceNotFoundError();
      }
      final status = decodeObject(raw['${object}Status']);
      final exitCode = status['exitCode'];
      // Capabilities describe selectable services, not current WAN ownership.
      // Some USP agents return an empty leaf on a helper error. Keep valid
      // Settings/Status authoritative even on the first page load.
      var capabilities = const AutoIPoECapabilities.init();
      var capabilitiesAvailable = false;
      try {
        final value = decodeObject(raw['${object}Capabilities']);
        if (value['isSupported'] is! bool ||
            value['supportedModes'] is! List ||
            value.containsKey('error')) {
          throw const InvalidInputError();
        }
        capabilities = AutoIPoECapabilities.fromMap(value);
        capabilitiesAvailable = true;
      } catch (_) {
        // No cached/default modes are advertised after a failed capability read.
      }
      return AutoIPoESnapshot(
        capabilities: capabilities,
        capabilitiesAvailable: capabilitiesAvailable,
        settings: AutoIPoESettings.fromMap(
          decodeObject(raw['${object}Settings']),
        ),
        runtime: AutoIPoEStatus.fromMap(status),
        log: AutoIPoELog.fromMap(decodeObject(raw['${object}Log'])),
        requestId: status['requestId'] as String?,
        operationId: status['operationId'] as String?,
        exitCode: exitCode is int && exitCode >= 0 && exitCode <= 255
            ? exitCode
            : null,
        accepted: status['accepted'] == true,
      );
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // The native adapter accepts only the active provider's arguments. Sending
  // every draft profile also sends unsupported legacy fields for OCN.
  static Map<String, dynamic> _nativeSettings(AutoIPoESettings settings) {
    final group = switch (settings.selectedMode) {
      AutoIPoEMode.standardIpip => 'standardIpipSettings',
      AutoIPoEMode.v6PlusStaticIp => 'v6PlusStaticIpSettings',
      AutoIPoEMode.biglobeStaticIp => 'biglobeStaticIpSettings',
      AutoIPoEMode.transixStaticIp => 'transixStaticIpSettings',
      AutoIPoEMode.asahiNetStaticIp => 'asahiNetStaticIpSettings',
      AutoIPoEMode.xpassStaticIp => 'xpassStaticIpSettings',
      AutoIPoEMode.auto ||
      AutoIPoEMode.disabled ||
      AutoIPoEMode.ocnVirtualConnectStaticIp ||
      AutoIPoEMode.ocxHikariV6ixStaticIp =>
        null,
    };
    return {
      'isEnabled': settings.isEnabled,
      'selectedMode': settings.selectedMode.value,
      if (group != null) group: settings.toMap()[group],
    };
  }

  /// Sends exactly once. Network interruption leaves the outcome unknown;
  /// callers retain RequestId and only poll Status after reconnecting.
  Future<AutoIPoEReceipt> submit(
    AutoIPoESubmission submission, {
    AutoIPoESettings? settings,
    bool resetFirst = false,
  }) async {
    try {
      checkConnection();
      final raw = await client.operate(
        '$object${submission.reset ? 'Reset' : 'Apply'}()',
        args: {
          'RequestId': submission.requestId,
          if (!submission.reset) 'ResetFirst': resetFirst.toString(),
          if (!submission.reset && settings != null)
            'Settings': jsonEncode(_nativeSettings(settings)),
        },
        retryOnAuthFailure: false,
        redactArguments: true,
      );
      checkConnection();
      final result = decodeObject(raw['Result']);
      if (result['accepted'] != true) return _receipt(result);
      if (result['requestId'] != submission.requestId ||
          result['operationId'] != submission.requestId ||
          result['cancelled'] == true) {
        throw const UnexpectedError();
      }
      return _receipt(result);
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Recovery fences a request that never reached the worker. It
  /// cannot cancel an existing accepted job and never replays Apply/Reset.
  Future<AutoIPoEReceipt> resolvePending(AutoIPoESubmission submission) async {
    try {
      checkConnection();
      final raw = await client.operate(
        '${object}ResolvePending()',
        args: {'RequestId': submission.requestId},
        retryOnAuthFailure: false,
        redactArguments: true,
      );
      checkConnection();
      final receipt = _receipt(decodeObject(raw['Result']));
      if ((receipt.cancelled && receipt.accepted) ||
          receipt.requestId != submission.requestId ||
          receipt.operationId != submission.requestId) {
        throw const UnexpectedError();
      }
      return receipt;
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  AutoIPoEReceipt _receipt(Map<String, dynamic> result) {
    final status = Map<String, dynamic>.from(
      result['status'] as Map? ?? const {},
    );
    return AutoIPoEReceipt(
      accepted: result['accepted'] == true,
      cancelled: result['cancelled'] == true,
      error: result['error'] as String?,
      requestId: result['requestId'] as String?,
      operationId: result['operationId'] as String?,
      exitCode: status['exitCode'] is int ? status['exitCode'] as int : null,
      status: AutoIPoEStatus.fromMap(status),
    );
  }

  Future<AutoIPoESubmission?> loadSubmission() async {
    try {
      checkConnection();
      final key = _storageKey;
      final prefs = await SharedPreferences.getInstance();
      checkConnection();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final data = jsonDecode(raw);
      if (data is! Map ||
          data['requestId'] is! String ||
          data['reset'] is! bool ||
          !RegExp(
            r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
          ).hasMatch(data['requestId'] as String)) {
        return null;
      }
      return AutoIPoESubmission(
        data['requestId'] as String,
        reset: data['reset'] as bool,
      );
    } on ServiceError {
      rethrow;
    } catch (_) {
      throw const StorageError();
    }
  }

  Future<void> storeSubmission(AutoIPoESubmission submission) async {
    try {
      checkConnection();
      final key = _storageKey;
      final prefs = await SharedPreferences.getInstance();
      checkConnection();
      final saved = await prefs.setString(
        key,
        jsonEncode({
          'requestId': submission.requestId,
          'reset': submission.reset,
        }),
      );
      checkConnection();
      if (!saved) throw const StorageError();
    } on ServiceError {
      rethrow;
    } catch (_) {
      throw const StorageError();
    }
  }

  Future<void> clearSubmission() async {
    checkConnection();
    final key = _storageKey;
    final prefs = await SharedPreferences.getInstance();
    checkConnection();
    final removed = await prefs.remove(key);
    checkConnection();
    if (!removed) throw const StorageError();
  }
}
