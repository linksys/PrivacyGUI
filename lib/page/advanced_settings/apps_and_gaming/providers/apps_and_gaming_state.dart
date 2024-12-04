import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';

class AppsAndGamingViewState extends Equatable {
  final DDNSState? preserveDDNSState;
  final SinglePortForwardingListState? preserveSinglePortForwardingListState;
  final PortRangeForwardingListState? preservePortRangeForwardingListState;
  final PortRangeTriggeringListState? preservePortRangeTriggeringListState;
  final bool isDataValid;

  const AppsAndGamingViewState({
    this.preserveDDNSState,
    this.preserveSinglePortForwardingListState,
    this.preservePortRangeForwardingListState,
    this.preservePortRangeTriggeringListState,
    this.isDataValid = true,
  });

  AppsAndGamingViewState copyWith({
    ValueGetter<DDNSState?>? preserveDDNSState,
    ValueGetter<SinglePortForwardingListState?>? preserveSinglePortForwardingListState,
    ValueGetter<PortRangeForwardingListState?>? preservePortRangeForwardingListState,
    ValueGetter<PortRangeTriggeringListState?>? preservePortRangeTriggeringListState,
    bool? isDataValid,
  }) {
    return AppsAndGamingViewState(
      preserveDDNSState: preserveDDNSState != null ? preserveDDNSState() : this.preserveDDNSState,
      preserveSinglePortForwardingListState: preserveSinglePortForwardingListState != null ? preserveSinglePortForwardingListState() : this.preserveSinglePortForwardingListState,
      preservePortRangeForwardingListState: preservePortRangeForwardingListState != null ? preservePortRangeForwardingListState() : this.preservePortRangeForwardingListState,
      preservePortRangeTriggeringListState: preservePortRangeTriggeringListState != null ? preservePortRangeTriggeringListState() : this.preservePortRangeTriggeringListState,
      isDataValid: isDataValid ?? this.isDataValid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preserveDDNSState': preserveDDNSState?.toMap(),
      'preserveSinglePortForwardingListState': preserveSinglePortForwardingListState?.toMap(),
      'preservePortRangeForwardingListState': preservePortRangeForwardingListState?.toMap(),
      'preservePortRangeTriggeringListState': preservePortRangeTriggeringListState?.toMap(),
      'isDataValid': isDataValid,
    };
  }

  factory AppsAndGamingViewState.fromMap(Map<String, dynamic> map) {
    return AppsAndGamingViewState(
      preserveDDNSState: map['preserveDDNSState'] != null ? DDNSState.fromMap(map['preserveDDNSState']) : null,
      preserveSinglePortForwardingListState: map['preserveSinglePortForwardingListState'] != null ? SinglePortForwardingListState.fromMap(map['preserveSinglePortForwardingListState']) : null,
      preservePortRangeForwardingListState: map['preservePortRangeForwardingListState'] != null ? PortRangeForwardingListState.fromMap(map['preservePortRangeForwardingListState']) : null,
      preservePortRangeTriggeringListState: map['preservePortRangeTriggeringListState'] != null ? PortRangeTriggeringListState.fromMap(map['preservePortRangeTriggeringListState']) : null,
      isDataValid: map['isDataValid'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppsAndGamingViewState.fromJson(String source) =>
      AppsAndGamingViewState.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AppsAndGamingViewState(preserveDDNSState: $preserveDDNSState, preserveSinglePortForwardingListState: $preserveSinglePortForwardingListState, preservePortRangeForwardingListState: $preservePortRangeForwardingListState, preservePortRangeTriggeringListState: $preservePortRangeTriggeringListState, isDataValid: $isDataValid)';
  }

  @override
  List<Object?> get props {
    return [
      preserveDDNSState,
      preserveSinglePortForwardingListState,
      preservePortRangeForwardingListState,
      preservePortRangeTriggeringListState,
      isDataValid,
    ];
  }
}
