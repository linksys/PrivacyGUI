import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/models/network_health_helpers.dart';

import 'health_dimension.dart';

/// Health score for a single dimension.
class HealthScore extends Equatable {
  final HealthDimensionType dimension;
  final int score;
  final DateTime evaluatedAt;
  final String? issueMessage;

  const HealthScore({
    required this.dimension,
    required this.score,
    required this.evaluatedAt,
    this.issueMessage,
  });

  /// Map score to health tier using default thresholds.
  HealthTier get tier => tierFromScore(score);

  /// Map score to health tier using custom thresholds.
  HealthTier tierWithThresholds(HealthThresholds t) {
    if (score >= t.excellent) return HealthTier.excellent;
    if (score >= t.good) return HealthTier.good;
    if (score >= t.fair) return HealthTier.fair;
    if (score >= t.poor) return HealthTier.poor;
    return HealthTier.critical;
  }

  /// Default tier calculation (reuses NetworkHealthHelpers thresholds).
  static HealthTier tierFromScore(int score) {
    return NetworkHealthHelpers.tierFromScore(score);
  }

  /// Font size multiplier for word cloud (lower score = bigger).
  ///
  /// Returns a value between 1.0 (score=100) and 2.0 (score=0).
  double get fontSizeMultiplier => 1.0 + (100 - score.clamp(0, 100)) / 100;

  /// Get tier-appropriate color from color scheme.
  Color getColor(ColorScheme cs) => NetworkHealthHelpers.tierColor(tier, cs);

  @override
  List<Object?> get props => [dimension, score, evaluatedAt, issueMessage];
}

/// Aggregated health state for all dimensions.
class SystemHealthState extends Equatable {
  final Map<HealthDimensionType, HealthScore> scores;
  final DateTime? lastEvaluated;
  final bool isEvaluating;

  const SystemHealthState({
    required this.scores,
    this.lastEvaluated,
    this.isEvaluating = false,
  });

  const SystemHealthState.initial()
      : scores = const {},
        lastEvaluated = null,
        isEvaluating = true;

  /// Get score for a specific dimension, or null if not evaluated.
  HealthScore? operator [](HealthDimensionType type) => scores[type];

  /// Overall system health (average of all dimensions).
  int get overallScore {
    if (scores.isEmpty) return 100;
    final total = scores.values.map((s) => s.score).reduce((a, b) => a + b);
    return total ~/ scores.length;
  }

  /// Overall health tier.
  HealthTier get overallTier => HealthScore.tierFromScore(overallScore);

  /// Dimensions that need attention (score < 70).
  List<HealthDimensionType> get attentionNeeded =>
      scores.entries.where((e) => e.value.score < 70).map((e) => e.key).toList()
        ..sort((a, b) => scores[a]!.score.compareTo(scores[b]!.score));

  /// Whether any dimension is in critical state.
  bool get hasCritical =>
      scores.values.any((s) => s.tier == HealthTier.critical);

  /// Whether any dimension needs attention.
  bool get hasIssues => attentionNeeded.isNotEmpty;

  /// Create a copy with updated values.
  SystemHealthState copyWith({
    Map<HealthDimensionType, HealthScore>? scores,
    DateTime? lastEvaluated,
    bool? isEvaluating,
  }) {
    return SystemHealthState(
      scores: scores ?? this.scores,
      lastEvaluated: lastEvaluated ?? this.lastEvaluated,
      isEvaluating: isEvaluating ?? this.isEvaluating,
    );
  }

  @override
  List<Object?> get props => [scores, lastEvaluated, isEvaluating];
}
