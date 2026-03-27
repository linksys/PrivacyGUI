import 'package:equatable/equatable.dart';

enum AppEventType { installed, removed, updated }

/// Model for the latest app lifecycle event from /api/app-events.json.
class AppEvent extends Equatable {
  final AppEventType type;
  final String appName;
  final int timestamp;

  const AppEvent({
    required this.type,
    required this.appName,
    required this.timestamp,
  });

  factory AppEvent.fromJson(Map<String, dynamic> json) {
    return AppEvent(
      type: switch (json['event'] as String?) {
        'installed' => AppEventType.installed,
        'removed' => AppEventType.removed,
        'updated' => AppEventType.updated,
        _ => AppEventType.updated,
      },
      appName: (json['app'] as Map<String, dynamic>?)?['name'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [type, appName, timestamp];
}
