import 'package:equatable/equatable.dart';

class JourneyAction extends Equatable {
  final String action;
  final DateTime timestamp;
  final String? result;

  const JourneyAction({
    required this.action,
    required this.timestamp,
    this.result,
  });

  Map<String, dynamic> toMap() => {
        'action': action,
        'timestamp': timestamp.toUtc().toIso8601String(),
        if (result != null) 'result': result,
      };

  @override
  List<Object?> get props => [action, timestamp, result];
}
