import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

/// Health dimension types for system evaluation.
///
/// Each dimension represents a distinct area of router health
/// that can be independently evaluated and displayed.
enum HealthDimensionType {
  internet,
  wifi,
  devices,
  security,
  system,
  firmware,
}

/// Read-only context containing all data needed for health evaluation.
///
/// This is a snapshot of the current system state, populated from
/// L1 dashboard providers. All fields are nullable to handle cases
/// where data hasn't loaded yet.
class HealthEvaluationContext extends Equatable {
  final WanData? wan;
  final WifiData? wifi;
  final DevicesData? devices;
  final FirewallData? firewall;
  final SystemInfoData? systemInfo;
  final FirmwareBanksData? firmware;

  const HealthEvaluationContext({
    this.wan,
    this.wifi,
    this.devices,
    this.firewall,
    this.systemInfo,
    this.firmware,
  });

  const HealthEvaluationContext.empty() : this();

  bool get hasAnyData =>
      wan != null ||
      wifi != null ||
      devices != null ||
      firewall != null ||
      systemInfo != null ||
      firmware != null;

  @override
  List<Object?> get props =>
      [wan, wifi, devices, firewall, systemInfo, firmware];
}

/// A single item in the dimension summary tooltip.
class SummaryItem extends Equatable {
  final String label;
  final String value;

  const SummaryItem(this.label, this.value);

  @override
  List<Object?> get props => [label, value];
}

/// Summary information displayed in the tooltip on long-press.
class DimensionSummary extends Equatable {
  final String status;
  final List<SummaryItem> items;
  final String? hint;

  const DimensionSummary({
    required this.status,
    this.items = const [],
    this.hint,
  });

  @override
  List<Object?> get props => [status, items, hint];
}

/// An action the user can take for a dimension.
class HealthAction extends Equatable {
  final String id;
  final String label;
  final IconData icon;
  final String? routeName;
  final VoidCallback? onTap;

  const HealthAction({
    required this.id,
    required this.label,
    required this.icon,
    this.routeName,
    this.onTap,
  });

  @override
  List<Object?> get props => [id, label, icon, routeName];
}

/// Configurable thresholds for health tier calculation.
///
/// Scores are mapped to tiers as follows:
/// - >= excellent: Excellent
/// - >= good: Good
/// - >= fair: Fair
/// - >= poor: Poor
/// - < poor: Critical
class HealthThresholds extends Equatable {
  final int excellent;
  final int good;
  final int fair;
  final int poor;

  const HealthThresholds({
    this.excellent = 90,
    this.good = 70,
    this.fair = 50,
    this.poor = 30,
  });

  @override
  List<Object?> get props => [excellent, good, fair, poor];
}

/// Abstract interface for a health dimension.
///
/// Each dimension is responsible for:
/// 1. Evaluating its health score (0-100)
/// 2. Providing a tooltip summary
/// 3. Defining available actions
/// 4. Specifying which SSE domains trigger re-evaluation
///
/// To add a new dimension:
/// 1. Create a class extending [HealthDimension]
/// 2. Register it in [HealthDimensionRegistry]
abstract class HealthDimension {
  /// The type identifier for this dimension.
  HealthDimensionType get type;

  /// Display name shown in the word cloud.
  String get displayName;

  /// Icon representing this dimension.
  IconData get icon;

  /// Optional custom thresholds for this dimension.
  HealthThresholds get thresholds => const HealthThresholds();

  /// Evaluate the health score for this dimension.
  ///
  /// Returns a value from 0 (critical) to 100 (excellent).
  /// Should return 100 if data is unavailable (assume healthy).
  int evaluate(HealthEvaluationContext context);

  /// Get summary information for the tooltip.
  DimensionSummary getSummary(HealthEvaluationContext context);

  /// Get available actions for this dimension.
  ///
  /// The [context] parameter provides build context for navigation.
  List<HealthAction> getActions(BuildContext context);

  /// SSE invalidation domains that should trigger re-evaluation.
  ///
  /// When any of these domains emit, the health score will be recalculated.
  Set<InvalidationDomain> get watchedDomains;
}
