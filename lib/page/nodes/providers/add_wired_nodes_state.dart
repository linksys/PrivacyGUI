// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/page/nodes/models/backhaul_info_ui_model.dart';

class AddWiredNodesState extends Equatable {
  final bool? onboardingProceed;
  final bool? anyOnboarded;
  final List<BackhaulInfoUIModel>? backhaulSnapshot;
  final bool isLoading;
  final bool forceStop;
  final String? loadingMessage;
  final int onboardingTime;
  final List<LinksysDevice>? nodes;

  const AddWiredNodesState({
    this.onboardingProceed,
    this.anyOnboarded,
    this.backhaulSnapshot,
    required this.isLoading,
    this.forceStop = false,
    this.loadingMessage,
    this.onboardingTime = 0,
    this.nodes,
  });

  AddWiredNodesState copyWith({
    bool? onboardingProceed,
    bool? anyOnboarded,
    List<BackhaulInfoUIModel>? backhaulSnapshot,
    bool? isLoading,
    bool? forceStop,
    String? loadingMessage,
    int? onboardingTime,
    List<LinksysDevice>? nodes,
  }) {
    return AddWiredNodesState(
      onboardingProceed: onboardingProceed ?? this.onboardingProceed,
      anyOnboarded: anyOnboarded ?? this.anyOnboarded,
      backhaulSnapshot: backhaulSnapshot ?? this.backhaulSnapshot,
      isLoading: isLoading ?? this.isLoading,
      forceStop: forceStop ?? this.forceStop,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      onboardingTime: onboardingTime ?? this.onboardingTime,
      nodes: nodes ?? this.nodes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'onboardingProceed': onboardingProceed,
      'anyOnboarded': anyOnboarded,
      'backhaulSnapshot': backhaulSnapshot?.map((x) => x.toMap()).toList(),
      'isLoading': isLoading,
      'forceStop': forceStop,
      'loadingMessage': loadingMessage,
      'onboardingTime': onboardingTime,
      'nodes': nodes,
    };
  }

  factory AddWiredNodesState.fromMap(Map<String, dynamic> map) {
    return AddWiredNodesState(
      onboardingProceed: map['onboardingProceed'],
      anyOnboarded: map['anyOnboarded'],
      backhaulSnapshot: map['backhaulSnapshot'] != null
          ? List<BackhaulInfoUIModel>.from(map['backhaulSnapshot']
              ?.map((x) => BackhaulInfoUIModel.fromMap(x)))
          : null,
      isLoading: map['isLoading'] ?? false,
      forceStop: map['forceStop'] ?? false,
      loadingMessage: map['loadingMessage'],
      onboardingTime: map['onboardingTime'],
      nodes: map['nodes'] != null
          ? List<LinksysDevice>.from(
              map['nodes']?.map((x) => LinksysDevice.fromMap(x)))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AddWiredNodesState.fromJson(String source) =>
      AddWiredNodesState.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AddWiredNodesState(onboardingProceed: $onboardingProceed, anyOnboarded: $anyOnboarded, nodesSnapshot: $backhaulSnapshot, isLoading: $isLoading, loadingMessage: $loadingMessage, onboardingTime: $onboardingTime), nodes: $nodes';
  }

  @override
  List<Object?> get props {
    return [
      onboardingProceed,
      anyOnboarded,
      backhaulSnapshot,
      isLoading,
      forceStop,
      loadingMessage,
      onboardingTime,
      nodes,
    ];
  }
}
