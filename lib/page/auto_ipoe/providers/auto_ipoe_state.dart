import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';

class AutoIPoEState extends Equatable {
  const AutoIPoEState({
    required this.capabilities,
    required this.settings,
    required this.status,
    required this.log,
  });

  final AutoIPoECapabilities capabilities;
  final AutoIPoESettings settings;
  final AutoIPoEStatus status;
  final AutoIPoELog log;

  const AutoIPoEState.init()
      : capabilities = const AutoIPoECapabilities.init(),
        settings = const AutoIPoESettings.init(),
        status = const AutoIPoEStatus.init(),
        log = const AutoIPoELog.init();

  AutoIPoEState copyWith({
    AutoIPoECapabilities? capabilities,
    AutoIPoESettings? settings,
    AutoIPoEStatus? status,
    AutoIPoELog? log,
  }) {
    return AutoIPoEState(
      capabilities: capabilities ?? this.capabilities,
      settings: settings ?? this.settings,
      status: status ?? this.status,
      log: log ?? this.log,
    );
  }

  Map<String, dynamic> toMap() => {
        'capabilities': capabilities.toMap(),
        'settings': settings.toMap(),
        'status': status.toMap(),
        'log': log.toMap(),
      };

  factory AutoIPoEState.fromMap(Map<String, dynamic> map) {
    return AutoIPoEState(
      capabilities: AutoIPoECapabilities.fromMap(
        map['capabilities'] as Map<String, dynamic>?,
      ),
      settings: AutoIPoESettings.fromMap(
        map['settings'] as Map<String, dynamic>?,
      ),
      status: AutoIPoEStatus.fromMap(map['status'] as Map<String, dynamic>?),
      log: AutoIPoELog.fromMap(map['log'] as Map<String, dynamic>?),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AutoIPoEState.fromJson(String source) =>
      AutoIPoEState.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [capabilities, settings, status, log];
}
