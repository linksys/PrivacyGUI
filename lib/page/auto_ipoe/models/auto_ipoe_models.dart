import 'dart:convert';

import 'package:equatable/equatable.dart';

enum AutoIPoEMode {
  disabled('Disabled'),
  auto('Auto'),
  biglobeStaticIp('BIGLOBEStaticIP'),
  standardIpip('StandardIPIP'),
  v6PlusStaticIp('V6PlusStaticIP'),
  ocnVirtualConnectStaticIp('OCNVirtualConnectStaticIP'),
  transixStaticIp('TransixStaticIP'),
  asahiNetStaticIp('AsahiNetStaticIP'),
  xpassStaticIp('XpassStaticIP'),
  ocxHikariV6ixStaticIp('OCXHikariV6IXStaticIP');

  const AutoIPoEMode(this.value);

  final String value;

  static AutoIPoEMode fromValue(String? value) {
    return AutoIPoEMode.values.firstWhere(
      (entry) => entry.value == value,
      orElse: () => AutoIPoEMode.disabled,
    );
  }
}

enum AutoIPoERuntimeType {
  none('None'),
  dhcpAuto('DHCPAuto'),
  mape('MAPE'),
  dsLite('DSLite'),
  ipip6('IPIP6'),
  unknown('Unknown');

  const AutoIPoERuntimeType(this.value);

  final String value;

  static AutoIPoERuntimeType fromValue(String? value) {
    return AutoIPoERuntimeType.values.firstWhere(
      (entry) => entry.value == value,
      orElse: () => AutoIPoERuntimeType.unknown,
    );
  }
}

enum AutoIPoEApplyState {
  idle('Idle'),
  applying('Applying'),
  active('Active'),
  failed('Failed'),
  resetting('Resetting');

  const AutoIPoEApplyState(this.value);

  final String value;

  static AutoIPoEApplyState fromValue(String? value) {
    return AutoIPoEApplyState.values.firstWhere(
      (entry) => entry.value == value,
      orElse: () => AutoIPoEApplyState.idle,
    );
  }
}

/// Optional runtime progress reported by newer Auto-IPoE backends.
///
/// Older firmware does not return this field. Keep [fromValue] nullable so the
/// PnP flow can retain its lifecycle-based compatibility path instead of
/// guessing a detailed phase.
enum AutoIPoEProgressPhase {
  detecting('Detecting'),
  provisioning('Provisioning'),
  applyingNetwork('ApplyingNetwork'),
  validatingTunnel('ValidatingTunnel'),
  checkingInternet('CheckingInternet'),
  retryScheduled('RetryScheduled'),
  completed('Completed'),
  failed('Failed');

  const AutoIPoEProgressPhase(this.value);

  final String value;

  static AutoIPoEProgressPhase? fromValue(String? value) {
    return switch (value) {
      'Detecting' || 'checking_ipv6' => AutoIPoEProgressPhase.detecting,
      'Provisioning' ||
      'getting_isp_settings' =>
        AutoIPoEProgressPhase.provisioning,
      'ApplyingNetwork' ||
      'applying_network' =>
        AutoIPoEProgressPhase.applyingNetwork,
      'ValidatingTunnel' ||
      'validating_connection' =>
        AutoIPoEProgressPhase.validatingTunnel,
      'CheckingInternet' ||
      'checking_internet' =>
        AutoIPoEProgressPhase.checkingInternet,
      'RetryScheduled' ||
      'retry_scheduled' =>
        AutoIPoEProgressPhase.retryScheduled,
      'Completed' || 'completed' => AutoIPoEProgressPhase.completed,
      'Failed' || 'failed' => AutoIPoEProgressPhase.failed,
      _ => null,
    };
  }
}

enum AutoIPoETerminalPhase {
  completed('completed'),
  failed('failed'),
  busy('busy'),
  retryScheduled('retry_scheduled');

  const AutoIPoETerminalPhase(this.value);

  final String value;

  static AutoIPoETerminalPhase? fromValue(String? value) {
    for (final entry in AutoIPoETerminalPhase.values) {
      if (entry.value == value) {
        return entry;
      }
    }
    return null;
  }
}

class AutoIPoETerminalResult extends Equatable {
  const AutoIPoETerminalResult({
    required this.phase,
    required this.operation,
    required this.exitCode,
    required this.reason,
    required this.connectivityVerified,
  });

  static const applyOperation = 'auto_ipoe';

  final AutoIPoETerminalPhase phase;
  final String operation;
  final int exitCode;
  final String reason;
  final bool connectivityVerified;

  bool get isValid {
    return switch (phase) {
      AutoIPoETerminalPhase.completed =>
        exitCode == 0 && reason == 'Completed' && connectivityVerified,
      AutoIPoETerminalPhase.busy =>
        exitCode == 75 && reason == 'Busy' && !connectivityVerified,
      AutoIPoETerminalPhase.retryScheduled =>
        exitCode == 0 && reason == 'RetryScheduled' && !connectivityVerified,
      AutoIPoETerminalPhase.failed => reason != 'Completed' &&
          reason != 'Busy' &&
          reason != 'RetryScheduled' &&
          !connectivityVerified,
    };
  }

  bool isSuccessfulFor(String expectedOperation) =>
      isValid &&
      operation == expectedOperation &&
      phase == AutoIPoETerminalPhase.completed;

  bool isFailureFor(String expectedOperation) =>
      isValid &&
      operation == expectedOperation &&
      phase == AutoIPoETerminalPhase.failed;

  bool isBusyFor(String expectedOperation) =>
      isValid &&
      operation == expectedOperation &&
      phase == AutoIPoETerminalPhase.busy;

  bool isRetryScheduledFor(String expectedOperation) =>
      isValid &&
      operation == expectedOperation &&
      phase == AutoIPoETerminalPhase.retryScheduled;

  Map<String, dynamic> toMap() => {
        'phase': phase.value,
        'operation': operation,
        'exitCode': exitCode,
        'reason': reason,
        'connectivityVerified': connectivityVerified,
      };

  static AutoIPoETerminalResult? fromMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = Map<String, dynamic>.from(value);
    final phase = AutoIPoETerminalPhase.fromValue(map['phase'] as String?);
    final operation = map['operation'];
    final exitCodeValue = map['exitCode'];
    final reason = map['reason'];
    final connectivityVerified = map['connectivityVerified'];
    if (phase == null ||
        operation is! String ||
        operation.isEmpty ||
        operation.length > 32 ||
        !RegExp(r'^[A-Za-z0-9_]+$').hasMatch(operation) ||
        exitCodeValue is! num ||
        exitCodeValue != exitCodeValue.toInt() ||
        exitCodeValue < 0 ||
        exitCodeValue > 255 ||
        reason is! String ||
        reason.isEmpty ||
        reason.length > 64 ||
        !RegExp(r'^[A-Za-z0-9_]+$').hasMatch(reason) ||
        connectivityVerified is! bool) {
      return null;
    }
    return AutoIPoETerminalResult(
      phase: phase,
      operation: operation,
      exitCode: exitCodeValue.toInt(),
      reason: reason,
      connectivityVerified: connectivityVerified,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        operation,
        exitCode,
        reason,
        connectivityVerified,
      ];
}

class AutoIPoESecret extends Equatable {
  const AutoIPoESecret({this.value, this.hasStoredValue = false});

  final String? value;
  final bool hasStoredValue;

  AutoIPoESecret copyWith({String? value, bool? hasStoredValue}) {
    return AutoIPoESecret(
      value: value ?? this.value,
      hasStoredValue: hasStoredValue ?? this.hasStoredValue,
    );
  }

  Map<String, dynamic> toMap() => {
        'value': value,
        'hasStoredValue': hasStoredValue
      }..removeWhere((key, value) => value == null);

  factory AutoIPoESecret.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const AutoIPoESecret();
    }
    return AutoIPoESecret(
      value: map['value'] as String?,
      hasStoredValue: map['hasStoredValue'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [value, hasStoredValue];
}

class AutoIPoECapabilities extends Equatable {
  const AutoIPoECapabilities({
    required this.isSupported,
    required this.supportedModes,
    required this.blocksManualIPv6Configuration,
    required this.requiresResetOnExit,
  });

  final bool isSupported;
  final List<AutoIPoEMode> supportedModes;
  final bool blocksManualIPv6Configuration;
  final bool requiresResetOnExit;

  const AutoIPoECapabilities.init()
      : isSupported = false,
        supportedModes = const [],
        blocksManualIPv6Configuration = true,
        requiresResetOnExit = true;

  AutoIPoECapabilities copyWith({
    bool? isSupported,
    List<AutoIPoEMode>? supportedModes,
    bool? blocksManualIPv6Configuration,
    bool? requiresResetOnExit,
  }) {
    return AutoIPoECapabilities(
      isSupported: isSupported ?? this.isSupported,
      supportedModes: supportedModes ?? this.supportedModes,
      blocksManualIPv6Configuration:
          blocksManualIPv6Configuration ?? this.blocksManualIPv6Configuration,
      requiresResetOnExit: requiresResetOnExit ?? this.requiresResetOnExit,
    );
  }

  Map<String, dynamic> toMap() => {
        'isSupported': isSupported,
        'supportedModes': supportedModes.map((entry) => entry.value).toList(),
        'blocksManualIPv6Configuration': blocksManualIPv6Configuration,
        'requiresResetOnExit': requiresResetOnExit,
      };

  factory AutoIPoECapabilities.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const AutoIPoECapabilities.init();
    }
    return AutoIPoECapabilities(
      isSupported: map['isSupported'] as bool? ?? false,
      supportedModes: ((map['supportedModes'] as List?) ?? const [])
          .map((entry) => AutoIPoEMode.fromValue(entry as String?))
          .toList(),
      blocksManualIPv6Configuration:
          map['blocksManualIPv6Configuration'] as bool? ?? true,
      requiresResetOnExit: map['requiresResetOnExit'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        isSupported,
        supportedModes,
        blocksManualIPv6Configuration,
        requiresResetOnExit,
      ];
}

class AutoIPoELog extends Equatable {
  const AutoIPoELog({
    required this.content,
    required this.isComplete,
    required this.rebootRecommended,
  });

  final String content;
  final bool isComplete;
  final bool rebootRecommended;

  const AutoIPoELog.init()
      : content = '',
        isComplete = false,
        rebootRecommended = false;

  AutoIPoELog copyWith({
    String? content,
    bool? isComplete,
    bool? rebootRecommended,
  }) {
    return AutoIPoELog(
      content: content ?? this.content,
      isComplete: isComplete ?? this.isComplete,
      rebootRecommended: rebootRecommended ?? this.rebootRecommended,
    );
  }

  Map<String, dynamic> toMap() => {
        'content': content,
        'isComplete': isComplete,
        'rebootRecommended': rebootRecommended,
      };

  static bool _hasCompletionMarker(String content) {
    final normalized = content.toLowerCase();
    return normalized.contains('### end of logging') ||
        normalized.contains('end of logging') ||
        normalized.contains('rebooting the router...');
  }

  factory AutoIPoELog.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const AutoIPoELog.init();
    }
    final content = map['content'] as String? ?? '';
    final completed = _hasCompletionMarker(content);
    final hasExplicitCompletion = map.containsKey('isComplete');
    return AutoIPoELog(
      content: content,
      // An explicit backend false is authoritative (for example, when the
      // current apply failed but its log still contains the normal footer).
      // Only infer completion from legacy log text when the field is absent.
      isComplete: hasExplicitCompletion
          ? (map['isComplete'] as bool? ?? false)
          : completed,
      // Completion and reboot are separate backend signals. Auto-IPoE now
      // restarts WAN/Wi-Fi itself, so a completion marker is not a reboot
      // recommendation.
      rebootRecommended: map['rebootRecommended'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [content, isComplete, rebootRecommended];
}

/// Determinate five-stage progress for one Auto-IPoE PnP operation.
///
/// Tunnel validation and the backend connectivity attempts intentionally share
/// step 4. Their different [phase] values let the copy change while keeping the
/// user-facing sequence to five useful stages. Firmware without structured
/// progress continues to use the legacy constructors below.
class AutoIPoEReconciliationProgress extends Equatable {
  const AutoIPoEReconciliationProgress({
    required this.currentStep,
    this.phase,
    this.attempt,
    this.attemptTotal,
  });

  static const int totalSteps = 5;
  static const int statusCheckingStep = 1;
  static const int providerSettingsStep = 2;
  static const int applyingNetworkStep = 3;
  static const int tunnelValidationStep = 4;
  static const int connectivityCheckingStep = 4;
  // Compatibility names used by the Advanced settings three-stage spinner.
  static const int tunnelWaitingStep = providerSettingsStep;
  static const int tunnelCompletedStep = applyingNetworkStep;

  final int currentStep;
  final AutoIPoEProgressPhase? phase;
  final int? attempt;
  final int? attemptTotal;

  const AutoIPoEReconciliationProgress.initial()
      : currentStep = statusCheckingStep,
        phase = AutoIPoEProgressPhase.detecting,
        attempt = null,
        attemptTotal = null;

  const AutoIPoEReconciliationProgress.waitingForTunnel()
      : currentStep = tunnelWaitingStep,
        phase = null,
        attempt = null,
        attemptTotal = null;

  const AutoIPoEReconciliationProgress.tunnelCompleted()
      : currentStep = tunnelCompletedStep,
        phase = null,
        attempt = null,
        attemptTotal = null;

  const AutoIPoEReconciliationProgress.validatingTunnel()
      : currentStep = tunnelValidationStep,
        phase = AutoIPoEProgressPhase.validatingTunnel,
        attempt = null,
        attemptTotal = null;

  const AutoIPoEReconciliationProgress.connectivityChecking({
    this.attempt,
    this.attemptTotal,
  })  : currentStep = connectivityCheckingStep,
        phase = AutoIPoEProgressPhase.checkingInternet;

  const AutoIPoEReconciliationProgress.completed()
      : currentStep = totalSteps,
        phase = AutoIPoEProgressPhase.completed,
        attempt = null,
        attemptTotal = null;

  factory AutoIPoEReconciliationProgress.fromStructuredStatus(
    AutoIPoEStatus status,
  ) {
    return switch (status.progressPhase) {
      AutoIPoEProgressPhase.detecting =>
        const AutoIPoEReconciliationProgress.initial(),
      AutoIPoEProgressPhase.provisioning =>
        const AutoIPoEReconciliationProgress(
          currentStep: providerSettingsStep,
          phase: AutoIPoEProgressPhase.provisioning,
        ),
      AutoIPoEProgressPhase.applyingNetwork =>
        const AutoIPoEReconciliationProgress(
          currentStep: applyingNetworkStep,
          phase: AutoIPoEProgressPhase.applyingNetwork,
        ),
      AutoIPoEProgressPhase.validatingTunnel =>
        const AutoIPoEReconciliationProgress.validatingTunnel(),
      AutoIPoEProgressPhase.checkingInternet =>
        AutoIPoEReconciliationProgress.connectivityChecking(
          attempt: status.validProgressAttempt,
          attemptTotal: status.validProgressTotal,
        ),
      AutoIPoEProgressPhase.retryScheduled =>
        const AutoIPoEReconciliationProgress(
          currentStep: providerSettingsStep,
          phase: AutoIPoEProgressPhase.retryScheduled,
        ),
      AutoIPoEProgressPhase.completed
          when status.hasVerifiedBackendConnectivity =>
        const AutoIPoEReconciliationProgress.completed(),
      AutoIPoEProgressPhase.completed =>
        const AutoIPoEReconciliationProgress.connectivityChecking(),
      AutoIPoEProgressPhase.failed =>
        const AutoIPoEReconciliationProgress.initial(),
      null => const AutoIPoEReconciliationProgress.initial(),
    };
  }

  /// Retains forward movement while allowing attempt text to update within a
  /// stage. Stale status responses cannot move the phase or attempt backwards.
  AutoIPoEReconciliationProgress advanceTo(
    AutoIPoEReconciliationProgress next,
  ) {
    if (next.currentStep < currentStep) {
      return this;
    }
    if (next.currentStep > currentStep) {
      return next;
    }

    final currentPhaseOrder = _phaseOrder(phase);
    final nextPhaseOrder = _phaseOrder(next.phase);
    if (nextPhaseOrder < currentPhaseOrder) {
      return this;
    }
    if (nextPhaseOrder > currentPhaseOrder) {
      return next;
    }

    final currentAttempt = attempt ?? 0;
    final nextAttempt = next.attempt ?? 0;
    if (nextAttempt < currentAttempt) {
      return this;
    }
    if (nextAttempt == currentAttempt && next == this) {
      return this;
    }
    return next;
  }

  static int _phaseOrder(AutoIPoEProgressPhase? phase) => switch (phase) {
        AutoIPoEProgressPhase.detecting => 1,
        AutoIPoEProgressPhase.provisioning => 2,
        AutoIPoEProgressPhase.applyingNetwork => 3,
        AutoIPoEProgressPhase.validatingTunnel => 4,
        AutoIPoEProgressPhase.checkingInternet => 5,
        AutoIPoEProgressPhase.retryScheduled => 6,
        AutoIPoEProgressPhase.completed => 7,
        AutoIPoEProgressPhase.failed => 0,
        null => 0,
      };

  bool get hasAttempt =>
      attempt != null &&
      attemptTotal != null &&
      attempt! > 0 &&
      attemptTotal! > 0 &&
      attempt! <= attemptTotal!;

  double get value => currentStep / totalSteps;

  @override
  List<Object?> get props => [currentStep, phase, attempt, attemptTotal];
}

class StandardIPIPSettings extends Equatable {
  const StandardIPIPSettings({
    this.ipv6Remote,
    this.ipv6InterfaceId,
    this.ipv4Address,
  });

  final String? ipv6Remote;
  final String? ipv6InterfaceId;
  final String? ipv4Address;

  StandardIPIPSettings copyWith({
    String? ipv6Remote,
    String? ipv6InterfaceId,
    String? ipv4Address,
  }) {
    return StandardIPIPSettings(
      ipv6Remote: ipv6Remote ?? this.ipv6Remote,
      ipv6InterfaceId: ipv6InterfaceId ?? this.ipv6InterfaceId,
      ipv4Address: ipv4Address ?? this.ipv4Address,
    );
  }

  Map<String, dynamic> toMap() => {
        'ipv6Remote': ipv6Remote,
        'ipv6InterfaceId': ipv6InterfaceId,
        'ipv4Address': ipv4Address,
      }..removeWhere((key, value) => value == null);

  factory StandardIPIPSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const StandardIPIPSettings();
    }
    return StandardIPIPSettings(
      ipv6Remote: map['ipv6Remote'] as String?,
      ipv6InterfaceId: map['ipv6InterfaceId'] as String?,
      ipv4Address: map['ipv4Address'] as String?,
    );
  }

  @override
  List<Object?> get props => [ipv6Remote, ipv6InterfaceId, ipv4Address];
}

class BiglobeStaticIPSettings extends Equatable {
  const BiglobeStaticIPSettings({
    this.userId = const AutoIPoESecret(),
    this.userPassword = const AutoIPoESecret(),
  });

  final AutoIPoESecret userId;
  final AutoIPoESecret userPassword;

  BiglobeStaticIPSettings copyWith({
    AutoIPoESecret? userId,
    AutoIPoESecret? userPassword,
  }) {
    return BiglobeStaticIPSettings(
      userId: userId ?? this.userId,
      userPassword: userPassword ?? this.userPassword,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId.toMap(),
        'userPassword': userPassword.toMap(),
      };

  factory BiglobeStaticIPSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const BiglobeStaticIPSettings();
    }
    return BiglobeStaticIPSettings(
      userId: AutoIPoESecret.fromMap(
        map['userId'] as Map<String, dynamic>?,
      ),
      userPassword: AutoIPoESecret.fromMap(
        map['userPassword'] as Map<String, dynamic>?,
      ),
    );
  }

  @override
  List<Object?> get props => [userId, userPassword];
}

class V6PlusStaticIPSettings extends Equatable {
  const V6PlusStaticIPSettings({
    this.ipv6Remote,
    this.ipv6InterfaceId,
    this.ipv4Address,
    this.userId,
    this.userPassword = const AutoIPoESecret(),
  });

  final String? ipv6Remote;
  final String? ipv6InterfaceId;
  final String? ipv4Address;
  final String? userId;
  final AutoIPoESecret userPassword;

  V6PlusStaticIPSettings copyWith({
    String? ipv6Remote,
    String? ipv6InterfaceId,
    String? ipv4Address,
    String? userId,
    AutoIPoESecret? userPassword,
  }) {
    return V6PlusStaticIPSettings(
      ipv6Remote: ipv6Remote ?? this.ipv6Remote,
      ipv6InterfaceId: ipv6InterfaceId ?? this.ipv6InterfaceId,
      ipv4Address: ipv4Address ?? this.ipv4Address,
      userId: userId ?? this.userId,
      userPassword: userPassword ?? this.userPassword,
    );
  }

  Map<String, dynamic> toMap() => {
        'ipv6Remote': ipv6Remote,
        'ipv6InterfaceId': ipv6InterfaceId,
        'ipv4Address': ipv4Address,
        'userId': userId,
        'userPassword': userPassword.toMap(),
      }..removeWhere((key, value) => value == null);

  factory V6PlusStaticIPSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const V6PlusStaticIPSettings();
    }
    return V6PlusStaticIPSettings(
      ipv6Remote: map['ipv6Remote'] as String?,
      ipv6InterfaceId: map['ipv6InterfaceId'] as String?,
      ipv4Address: map['ipv4Address'] as String?,
      userId: map['userId'] as String?,
      userPassword: AutoIPoESecret.fromMap(
        map['userPassword'] as Map<String, dynamic>?,
      ),
    );
  }

  @override
  List<Object?> get props => [
        ipv6Remote,
        ipv6InterfaceId,
        ipv4Address,
        userId,
        userPassword,
      ];
}

class OCNVirtualConnectStaticIPSettings extends Equatable {
  const OCNVirtualConnectStaticIPSettings({
    this.ruleApiCode = const AutoIPoESecret(),
    this.updateUserId,
    this.updatePassword = const AutoIPoESecret(),
  });

  final AutoIPoESecret ruleApiCode;
  final String? updateUserId;
  final AutoIPoESecret updatePassword;

  OCNVirtualConnectStaticIPSettings copyWith({
    AutoIPoESecret? ruleApiCode,
    String? updateUserId,
    AutoIPoESecret? updatePassword,
  }) {
    return OCNVirtualConnectStaticIPSettings(
      ruleApiCode: ruleApiCode ?? this.ruleApiCode,
      updateUserId: updateUserId ?? this.updateUserId,
      updatePassword: updatePassword ?? this.updatePassword,
    );
  }

  Map<String, dynamic> toMap() => {
        'ruleApiCode': ruleApiCode.toMap(),
        'updateUserId': updateUserId,
        'updatePassword': updatePassword.toMap(),
      }..removeWhere((key, value) => value == null);

  factory OCNVirtualConnectStaticIPSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const OCNVirtualConnectStaticIPSettings();
    }
    return OCNVirtualConnectStaticIPSettings(
      ruleApiCode: AutoIPoESecret.fromMap(
        map['ruleApiCode'] as Map<String, dynamic>?,
      ),
      updateUserId: map['updateUserId'] as String?,
      updatePassword: AutoIPoESecret.fromMap(
        map['updatePassword'] as Map<String, dynamic>?,
      ),
    );
  }

  @override
  List<Object?> get props => [ruleApiCode, updateUserId, updatePassword];
}

class TransixStaticIPSettings extends Equatable {
  const TransixStaticIPSettings({
    this.ipv6Remote,
    this.ipv6InterfaceId,
    this.ipv4Address,
    this.updateUserId,
    this.updatePassword = const AutoIPoESecret(),
  });

  final String? ipv6Remote;
  final String? ipv6InterfaceId;
  final String? ipv4Address;
  final String? updateUserId;
  final AutoIPoESecret updatePassword;

  TransixStaticIPSettings copyWith({
    String? ipv6Remote,
    String? ipv6InterfaceId,
    String? ipv4Address,
    String? updateUserId,
    AutoIPoESecret? updatePassword,
  }) {
    return TransixStaticIPSettings(
      ipv6Remote: ipv6Remote ?? this.ipv6Remote,
      ipv6InterfaceId: ipv6InterfaceId ?? this.ipv6InterfaceId,
      ipv4Address: ipv4Address ?? this.ipv4Address,
      updateUserId: updateUserId ?? this.updateUserId,
      updatePassword: updatePassword ?? this.updatePassword,
    );
  }

  Map<String, dynamic> toMap() => {
        'ipv6Remote': ipv6Remote,
        'ipv6InterfaceId': ipv6InterfaceId,
        'ipv4Address': ipv4Address,
        'updateUserId': updateUserId,
        'updatePassword': updatePassword.toMap(),
      }..removeWhere((key, value) => value == null);

  factory TransixStaticIPSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const TransixStaticIPSettings();
    }
    return TransixStaticIPSettings(
      ipv6Remote: map['ipv6Remote'] as String?,
      ipv6InterfaceId: map['ipv6InterfaceId'] as String?,
      ipv4Address: map['ipv4Address'] as String?,
      updateUserId: map['updateUserId'] as String?,
      updatePassword: AutoIPoESecret.fromMap(
        map['updatePassword'] as Map<String, dynamic>?,
      ),
    );
  }

  @override
  List<Object?> get props => [
        ipv6Remote,
        ipv6InterfaceId,
        ipv4Address,
        updateUserId,
        updatePassword,
      ];
}

class AsahiNetStaticIPSettings extends Equatable {
  const AsahiNetStaticIPSettings({
    this.authenticationKey,
    this.authenticationPassword = const AutoIPoESecret(),
  });

  final String? authenticationKey;
  final AutoIPoESecret authenticationPassword;

  AsahiNetStaticIPSettings copyWith({
    String? authenticationKey,
    AutoIPoESecret? authenticationPassword,
  }) {
    return AsahiNetStaticIPSettings(
      authenticationKey: authenticationKey ?? this.authenticationKey,
      authenticationPassword:
          authenticationPassword ?? this.authenticationPassword,
    );
  }

  Map<String, dynamic> toMap() => {
        'authenticationKey': authenticationKey,
        'authenticationPassword': authenticationPassword.toMap(),
      }..removeWhere((key, value) => value == null);

  factory AsahiNetStaticIPSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const AsahiNetStaticIPSettings();
    }
    return AsahiNetStaticIPSettings(
      authenticationKey: map['authenticationKey'] as String?,
      authenticationPassword: AutoIPoESecret.fromMap(
        map['authenticationPassword'] as Map<String, dynamic>?,
      ),
    );
  }

  @override
  List<Object?> get props => [authenticationKey, authenticationPassword];
}

class XpassStaticIPSettings extends Equatable {
  const XpassStaticIPSettings({
    this.fqdn,
    this.ddnsId,
    this.ddnsPassword = const AutoIPoESecret(),
    this.basicAuthId,
    this.basicAuthPassword = const AutoIPoESecret(),
    this.ddnsUpdateUrl,
    this.ipv6Remote,
    this.ipv4Address,
  });

  final String? fqdn;
  final String? ddnsId;
  final AutoIPoESecret ddnsPassword;
  final String? basicAuthId;
  final AutoIPoESecret basicAuthPassword;
  final String? ddnsUpdateUrl;
  final String? ipv6Remote;
  final String? ipv4Address;

  XpassStaticIPSettings copyWith({
    String? fqdn,
    String? ddnsId,
    AutoIPoESecret? ddnsPassword,
    String? basicAuthId,
    AutoIPoESecret? basicAuthPassword,
    String? ddnsUpdateUrl,
    String? ipv6Remote,
    String? ipv4Address,
  }) {
    return XpassStaticIPSettings(
      fqdn: fqdn ?? this.fqdn,
      ddnsId: ddnsId ?? this.ddnsId,
      ddnsPassword: ddnsPassword ?? this.ddnsPassword,
      basicAuthId: basicAuthId ?? this.basicAuthId,
      basicAuthPassword: basicAuthPassword ?? this.basicAuthPassword,
      ddnsUpdateUrl: ddnsUpdateUrl ?? this.ddnsUpdateUrl,
      ipv6Remote: ipv6Remote ?? this.ipv6Remote,
      ipv4Address: ipv4Address ?? this.ipv4Address,
    );
  }

  Map<String, dynamic> toMap() => {
        'fqdn': fqdn,
        'ddnsId': ddnsId,
        'ddnsPassword': ddnsPassword.toMap(),
        'basicAuthId': basicAuthId,
        'basicAuthPassword': basicAuthPassword.toMap(),
        'ddnsUpdateUrl': ddnsUpdateUrl,
        'ipv6Remote': ipv6Remote,
        'ipv4Address': ipv4Address,
      }..removeWhere((key, value) => value == null);

  factory XpassStaticIPSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const XpassStaticIPSettings();
    }
    return XpassStaticIPSettings(
      fqdn: map['fqdn'] as String?,
      ddnsId: map['ddnsId'] as String?,
      ddnsPassword: AutoIPoESecret.fromMap(
        map['ddnsPassword'] as Map<String, dynamic>?,
      ),
      basicAuthId: map['basicAuthId'] as String?,
      basicAuthPassword: AutoIPoESecret.fromMap(
        map['basicAuthPassword'] as Map<String, dynamic>?,
      ),
      ddnsUpdateUrl: map['ddnsUpdateUrl'] as String?,
      ipv6Remote: map['ipv6Remote'] as String?,
      ipv4Address: map['ipv4Address'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        fqdn,
        ddnsId,
        ddnsPassword,
        basicAuthId,
        basicAuthPassword,
        ddnsUpdateUrl,
        ipv6Remote,
        ipv4Address,
      ];
}

class OCXHikariV6IXStaticIPSettings extends Equatable {
  const OCXHikariV6IXStaticIPSettings();

  Map<String, dynamic> toMap() => const {};

  factory OCXHikariV6IXStaticIPSettings.fromMap(Map<String, dynamic>? map) {
    return const OCXHikariV6IXStaticIPSettings();
  }

  @override
  List<Object?> get props => const [];
}

class AutoIPoESettings extends Equatable {
  const AutoIPoESettings({
    required this.isEnabled,
    required this.selectedMode,
    this.biglobeStaticIpSettings = const BiglobeStaticIPSettings(),
    this.standardIpipSettings = const StandardIPIPSettings(),
    this.v6PlusStaticIpSettings = const V6PlusStaticIPSettings(),
    this.ocnVirtualConnectStaticIpSettings =
        const OCNVirtualConnectStaticIPSettings(),
    this.transixStaticIpSettings = const TransixStaticIPSettings(),
    this.asahiNetStaticIpSettings = const AsahiNetStaticIPSettings(),
    this.xpassStaticIpSettings = const XpassStaticIPSettings(),
    this.ocxHikariV6ixStaticIpSettings = const OCXHikariV6IXStaticIPSettings(),
  });

  final bool isEnabled;
  final AutoIPoEMode selectedMode;
  final BiglobeStaticIPSettings biglobeStaticIpSettings;
  final StandardIPIPSettings standardIpipSettings;
  final V6PlusStaticIPSettings v6PlusStaticIpSettings;
  final OCNVirtualConnectStaticIPSettings ocnVirtualConnectStaticIpSettings;
  final TransixStaticIPSettings transixStaticIpSettings;
  final AsahiNetStaticIPSettings asahiNetStaticIpSettings;
  final XpassStaticIPSettings xpassStaticIpSettings;
  final OCXHikariV6IXStaticIPSettings ocxHikariV6ixStaticIpSettings;

  const AutoIPoESettings.init()
      : isEnabled = false,
        selectedMode = AutoIPoEMode.disabled,
        biglobeStaticIpSettings = const BiglobeStaticIPSettings(),
        standardIpipSettings = const StandardIPIPSettings(),
        v6PlusStaticIpSettings = const V6PlusStaticIPSettings(),
        ocnVirtualConnectStaticIpSettings =
            const OCNVirtualConnectStaticIPSettings(),
        transixStaticIpSettings = const TransixStaticIPSettings(),
        asahiNetStaticIpSettings = const AsahiNetStaticIPSettings(),
        xpassStaticIpSettings = const XpassStaticIPSettings(),
        ocxHikariV6ixStaticIpSettings = const OCXHikariV6IXStaticIPSettings();

  AutoIPoESettings copyWith({
    bool? isEnabled,
    AutoIPoEMode? selectedMode,
    BiglobeStaticIPSettings? biglobeStaticIpSettings,
    StandardIPIPSettings? standardIpipSettings,
    V6PlusStaticIPSettings? v6PlusStaticIpSettings,
    OCNVirtualConnectStaticIPSettings? ocnVirtualConnectStaticIpSettings,
    TransixStaticIPSettings? transixStaticIpSettings,
    AsahiNetStaticIPSettings? asahiNetStaticIpSettings,
    XpassStaticIPSettings? xpassStaticIpSettings,
    OCXHikariV6IXStaticIPSettings? ocxHikariV6ixStaticIpSettings,
  }) {
    return AutoIPoESettings(
      isEnabled: isEnabled ?? this.isEnabled,
      selectedMode: selectedMode ?? this.selectedMode,
      biglobeStaticIpSettings:
          biglobeStaticIpSettings ?? this.biglobeStaticIpSettings,
      standardIpipSettings: standardIpipSettings ?? this.standardIpipSettings,
      v6PlusStaticIpSettings:
          v6PlusStaticIpSettings ?? this.v6PlusStaticIpSettings,
      ocnVirtualConnectStaticIpSettings: ocnVirtualConnectStaticIpSettings ??
          this.ocnVirtualConnectStaticIpSettings,
      transixStaticIpSettings:
          transixStaticIpSettings ?? this.transixStaticIpSettings,
      asahiNetStaticIpSettings:
          asahiNetStaticIpSettings ?? this.asahiNetStaticIpSettings,
      xpassStaticIpSettings:
          xpassStaticIpSettings ?? this.xpassStaticIpSettings,
      ocxHikariV6ixStaticIpSettings:
          ocxHikariV6ixStaticIpSettings ?? this.ocxHikariV6ixStaticIpSettings,
    );
  }

  Map<String, dynamic> toMap() => {
        'isEnabled': isEnabled,
        'selectedMode': selectedMode.value,
        'biglobeStaticIpSettings': biglobeStaticIpSettings.toMap(),
        'standardIpipSettings': standardIpipSettings.toMap(),
        'v6PlusStaticIpSettings': v6PlusStaticIpSettings.toMap(),
        'ocnVirtualConnectStaticIpSettings':
            ocnVirtualConnectStaticIpSettings.toMap(),
        'transixStaticIpSettings': transixStaticIpSettings.toMap(),
        'asahiNetStaticIpSettings': asahiNetStaticIpSettings.toMap(),
        'xpassStaticIpSettings': xpassStaticIpSettings.toMap(),
        'ocxHikariV6ixStaticIpSettings': ocxHikariV6ixStaticIpSettings.toMap(),
      };

  factory AutoIPoESettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const AutoIPoESettings.init();
    }
    return AutoIPoESettings(
      isEnabled: map['isEnabled'] as bool? ?? false,
      selectedMode: AutoIPoEMode.fromValue(map['selectedMode'] as String?),
      biglobeStaticIpSettings: BiglobeStaticIPSettings.fromMap(
        map['biglobeStaticIpSettings'] as Map<String, dynamic>?,
      ),
      standardIpipSettings: StandardIPIPSettings.fromMap(
        map['standardIpipSettings'] as Map<String, dynamic>?,
      ),
      v6PlusStaticIpSettings: V6PlusStaticIPSettings.fromMap(
        map['v6PlusStaticIpSettings'] as Map<String, dynamic>?,
      ),
      ocnVirtualConnectStaticIpSettings:
          OCNVirtualConnectStaticIPSettings.fromMap(
        map['ocnVirtualConnectStaticIpSettings'] as Map<String, dynamic>?,
      ),
      transixStaticIpSettings: TransixStaticIPSettings.fromMap(
        map['transixStaticIpSettings'] as Map<String, dynamic>?,
      ),
      asahiNetStaticIpSettings: AsahiNetStaticIPSettings.fromMap(
        map['asahiNetStaticIpSettings'] as Map<String, dynamic>?,
      ),
      xpassStaticIpSettings: XpassStaticIPSettings.fromMap(
        map['xpassStaticIpSettings'] as Map<String, dynamic>?,
      ),
      ocxHikariV6ixStaticIpSettings: OCXHikariV6IXStaticIPSettings.fromMap(
        map['ocxHikariV6ixStaticIpSettings'] as Map<String, dynamic>?,
      ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AutoIPoESettings.fromJson(String source) =>
      AutoIPoESettings.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        isEnabled,
        selectedMode,
        biglobeStaticIpSettings,
        standardIpipSettings,
        v6PlusStaticIpSettings,
        ocnVirtualConnectStaticIpSettings,
        transixStaticIpSettings,
        asahiNetStaticIpSettings,
        xpassStaticIpSettings,
        ocxHikariV6ixStaticIpSettings,
      ];
}

class AutoIPoEStatus extends Equatable {
  const AutoIPoEStatus({
    required this.isEnabled,
    required this.isCurrentWANType,
    required this.selectedMode,
    required this.applyState,
    required this.runtimeKind,
    this.currentVNE,
    required this.blockIPv6ManualConfiguration,
    required this.isBusy,
    required this.needsResetBeforeLeaving,
    this.lastResult,
    this.lastError,
    this.errorCategory,
    this.retryable,
    this.errorFieldGroup,
    this.progressPhase,
    this.progressAttempt,
    this.progressTotal,
    this.connectivityVerified,
    this.terminalResultSupported = false,
    this.terminalResult,
  });

  final bool isEnabled;
  final bool isCurrentWANType;
  final AutoIPoEMode selectedMode;
  final AutoIPoEApplyState applyState;
  final AutoIPoERuntimeType runtimeKind;
  final String? currentVNE;
  final bool blockIPv6ManualConfiguration;
  final bool isBusy;
  final bool needsResetBeforeLeaving;
  final String? lastResult;
  final String? lastError;
  final String? errorCategory;
  final bool? retryable;
  final String? errorFieldGroup;
  final AutoIPoEProgressPhase? progressPhase;
  final int? progressAttempt;
  final int? progressTotal;
  final bool? connectivityVerified;
  final bool terminalResultSupported;
  final AutoIPoETerminalResult? terminalResult;

  const AutoIPoEStatus.init()
      : isEnabled = false,
        isCurrentWANType = false,
        selectedMode = AutoIPoEMode.disabled,
        applyState = AutoIPoEApplyState.idle,
        runtimeKind = AutoIPoERuntimeType.none,
        currentVNE = null,
        blockIPv6ManualConfiguration = false,
        isBusy = false,
        needsResetBeforeLeaving = false,
        lastResult = null,
        lastError = null,
        errorCategory = null,
        retryable = null,
        errorFieldGroup = null,
        progressPhase = null,
        progressAttempt = null,
        progressTotal = null,
        connectivityVerified = null,
        terminalResultSupported = false,
        terminalResult = null;

  AutoIPoEStatus copyWith({
    bool? isEnabled,
    bool? isCurrentWANType,
    AutoIPoEMode? selectedMode,
    AutoIPoEApplyState? applyState,
    AutoIPoERuntimeType? runtimeKind,
    String? currentVNE,
    bool? blockIPv6ManualConfiguration,
    bool? isBusy,
    bool? needsResetBeforeLeaving,
    String? lastResult,
    String? lastError,
    String? errorCategory,
    bool? retryable,
    String? errorFieldGroup,
    AutoIPoEProgressPhase? progressPhase,
    int? progressAttempt,
    int? progressTotal,
    bool? connectivityVerified,
    bool? terminalResultSupported,
    AutoIPoETerminalResult? terminalResult,
  }) {
    return AutoIPoEStatus(
      isEnabled: isEnabled ?? this.isEnabled,
      isCurrentWANType: isCurrentWANType ?? this.isCurrentWANType,
      selectedMode: selectedMode ?? this.selectedMode,
      applyState: applyState ?? this.applyState,
      runtimeKind: runtimeKind ?? this.runtimeKind,
      currentVNE: currentVNE ?? this.currentVNE,
      blockIPv6ManualConfiguration:
          blockIPv6ManualConfiguration ?? this.blockIPv6ManualConfiguration,
      isBusy: isBusy ?? this.isBusy,
      needsResetBeforeLeaving:
          needsResetBeforeLeaving ?? this.needsResetBeforeLeaving,
      lastResult: lastResult ?? this.lastResult,
      lastError: lastError ?? this.lastError,
      errorCategory: errorCategory ?? this.errorCategory,
      retryable: retryable ?? this.retryable,
      errorFieldGroup: errorFieldGroup ?? this.errorFieldGroup,
      progressPhase: progressPhase ?? this.progressPhase,
      progressAttempt: progressAttempt ?? this.progressAttempt,
      progressTotal: progressTotal ?? this.progressTotal,
      connectivityVerified: connectivityVerified ?? this.connectivityVerified,
      terminalResultSupported:
          terminalResultSupported ?? this.terminalResultSupported,
      terminalResult: terminalResult ?? this.terminalResult,
    );
  }

  Map<String, dynamic> toMap() => {
        'isEnabled': isEnabled,
        'isCurrentWANType': isCurrentWANType,
        'selectedMode': selectedMode.value,
        'applyState': applyState.value,
        'runtimeType': runtimeKind.value,
        'currentVNE': currentVNE,
        'blockIPv6ManualConfiguration': blockIPv6ManualConfiguration,
        'isBusy': isBusy,
        'needsResetBeforeLeaving': needsResetBeforeLeaving,
        'lastResult': lastResult,
        'lastError': lastError,
        'errorCategory': errorCategory,
        'retryable': retryable,
        'errorFieldGroup': errorFieldGroup,
        'progressPhase': progressPhase?.value,
        'progressAttempt': progressAttempt,
        'progressTotal': progressTotal,
        'connectivityVerified': connectivityVerified,
        'terminalResultSupported': terminalResultSupported,
        'terminalResult': terminalResult?.toMap(),
      }..removeWhere((key, value) => value == null);

  factory AutoIPoEStatus.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const AutoIPoEStatus.init();
    }
    return AutoIPoEStatus(
      isEnabled: map['isEnabled'] as bool? ?? false,
      isCurrentWANType: map['isCurrentWANType'] as bool? ?? false,
      selectedMode: AutoIPoEMode.fromValue(
        (map['selectedMode'] ?? map['mode']) as String?,
      ),
      applyState: AutoIPoEApplyState.fromValue(map['applyState'] as String?),
      runtimeKind: AutoIPoERuntimeType.fromValue(
        map['runtimeType'] as String?,
      ),
      currentVNE: map['currentVNE'] as String?,
      blockIPv6ManualConfiguration:
          map['blockIPv6ManualConfiguration'] as bool? ?? false,
      isBusy: map['isBusy'] as bool? ?? false,
      needsResetBeforeLeaving: map['needsResetBeforeLeaving'] as bool? ?? false,
      lastResult: map['lastResult'] as String?,
      lastError: map['lastError'] as String?,
      errorCategory: map['errorCategory'] as String?,
      retryable: map['retryable'] as bool?,
      errorFieldGroup: map['errorFieldGroup'] as String?,
      progressPhase: AutoIPoEProgressPhase.fromValue(
        map['progressPhase'] as String?,
      ),
      progressAttempt: _progressInt(map['progressAttempt']),
      progressTotal: _progressInt(map['progressTotal']),
      connectivityVerified: map['connectivityVerified'] as bool?,
      terminalResultSupported: map['terminalResultSupported'] as bool? ??
          map.containsKey('terminalResult'),
      terminalResult: AutoIPoETerminalResult.fromMap(map['terminalResult']),
    );
  }

  static int? _progressInt(Object? value) {
    if (value is! num) {
      return null;
    }
    final result = value.toInt();
    return result >= 1 && result <= 100 ? result : null;
  }

  int? get validProgressAttempt {
    final attempt = progressAttempt;
    final total = progressTotal;
    if (attempt == null || total == null || attempt > total) {
      return null;
    }
    return attempt;
  }

  int? get validProgressTotal =>
      validProgressAttempt == null ? null : progressTotal;

  bool get hasStructuredProgress =>
      progressPhase != null && progressPhase != AutoIPoEProgressPhase.failed;

  bool get hasVerifiedBackendConnectivity => terminalResultSupported
      ? terminalResult?.isSuccessfulFor(
            AutoIPoETerminalResult.applyOperation,
          ) ==
          true
      : progressPhase == AutoIPoEProgressPhase.completed &&
          connectivityVerified == true;

  /// Whether the current Apply is conclusively known to have failed.
  ///
  /// Once the backend advertises the structured terminal-result contract,
  /// only a valid result correlated to the Auto-IPoE Apply operation is
  /// authoritative. The older apply state can briefly expose a stale or
  /// log-derived Failed value while the current result is still pending.
  bool get hasTerminalApplyFailure => terminalResultSupported
      ? terminalResult?.isFailureFor(
            AutoIPoETerminalResult.applyOperation,
          ) ==
          true
      : applyState == AutoIPoEApplyState.failed;

  bool get hasTerminalApplyBusy =>
      terminalResultSupported &&
      terminalResult?.isBusyFor(
            AutoIPoETerminalResult.applyOperation,
          ) ==
          true;

  bool get hasTerminalApplyRetryScheduled =>
      terminalResultSupported &&
      terminalResult?.isRetryScheduledFor(
            AutoIPoETerminalResult.applyOperation,
          ) ==
          true;

  bool get hasTerminalApplyOutcome => terminalResultSupported
      ? hasTerminalApplyFailure ||
          hasTerminalApplyBusy ||
          hasTerminalApplyRetryScheduled
      : !isBusy && hasTerminalApplyFailure;

  bool get isTerminalApplyResultPending =>
      terminalResultSupported &&
      terminalResult?.isSuccessfulFor(
            AutoIPoETerminalResult.applyOperation,
          ) !=
          true &&
      terminalResult?.isFailureFor(
            AutoIPoETerminalResult.applyOperation,
          ) !=
          true &&
      terminalResult?.isBusyFor(
            AutoIPoETerminalResult.applyOperation,
          ) !=
          true &&
      terminalResult?.isRetryScheduledFor(
            AutoIPoETerminalResult.applyOperation,
          ) !=
          true;

  @override
  List<Object?> get props => [
        isEnabled,
        isCurrentWANType,
        selectedMode,
        applyState,
        runtimeKind,
        currentVNE,
        blockIPv6ManualConfiguration,
        isBusy,
        needsResetBeforeLeaving,
        lastResult,
        lastError,
        errorCategory,
        retryable,
        errorFieldGroup,
        progressPhase,
        progressAttempt,
        progressTotal,
        connectivityVerified,
        terminalResultSupported,
        terminalResult,
      ];
}
