import 'package:flutter/material.dart';

/// Network health score with rating and comment.
class NetworkHealthScore {
  final int score;
  final String comment;
  final NetworkHealthLevel level;

  const NetworkHealthScore({
    required this.score,
    required this.comment,
    required this.level,
  });

  factory NetworkHealthScore.calculate({
    required bool isOnline,
    required int connectedDevices,
    required int? wifiDevices,
    required int? weakSignalDevices,
  }) {
    if (!isOnline) {
      return const NetworkHealthScore(
        score: 0,
        comment: 'Network is offline',
        level: NetworkHealthLevel.critical,
      );
    }

    int score = 100;
    String comment = 'Everything looks great!';

    // Deduct points for weak signal devices
    if (weakSignalDevices != null && weakSignalDevices > 0) {
      final deduction = (weakSignalDevices * 10).clamp(0, 30);
      score -= deduction;
      if (weakSignalDevices == 1) {
        comment = '1 device has weak signal';
      } else {
        comment = '$weakSignalDevices devices have weak signal';
      }
    }

    // Bonus comment for many devices
    if (score >= 90 && connectedDevices > 10) {
      comment = 'Handling $connectedDevices devices smoothly!';
    }

    final level = NetworkHealthLevel.fromScore(score);

    // Override comment based on level
    if (level == NetworkHealthLevel.good &&
        comment == 'Everything looks great!') {
      comment = 'Network is healthy';
    }

    return NetworkHealthScore(
      score: score.clamp(0, 100),
      comment: comment,
      level: level,
    );
  }
}

enum NetworkHealthLevel {
  excellent,
  good,
  fair,
  poor,
  critical;

  factory NetworkHealthLevel.fromScore(int score) {
    if (score >= 90) return NetworkHealthLevel.excellent;
    if (score >= 70) return NetworkHealthLevel.good;
    if (score >= 50) return NetworkHealthLevel.fair;
    if (score >= 20) return NetworkHealthLevel.poor;
    return NetworkHealthLevel.critical;
  }

  Color get color {
    return switch (this) {
      NetworkHealthLevel.excellent => const Color(0xFF4CAF50),
      NetworkHealthLevel.good => const Color(0xFF8BC34A),
      NetworkHealthLevel.fair => const Color(0xFFFFC107),
      NetworkHealthLevel.poor => const Color(0xFFFF9800),
      NetworkHealthLevel.critical => const Color(0xFFF44336),
    };
  }

  String get emoji {
    return switch (this) {
      NetworkHealthLevel.excellent => ':)',
      NetworkHealthLevel.good => ':)',
      NetworkHealthLevel.fair => ':|',
      NetworkHealthLevel.poor => ':(',
      NetworkHealthLevel.critical => ':(',
    };
  }
}
