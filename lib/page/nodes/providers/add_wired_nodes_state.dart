// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

class AddWiredNodesState extends Equatable {
  final bool? onboardingProceed;
  final bool? anyOnboarded;
  final List<BackHaulInfoData>? backhaulSnapshot;
  final bool isLoading;
  final String? loadingMessage;
  final int onboardingTime;
  final List<LinksysDevice>? nodes;

  const AddWiredNodesState({
    this.onboardingProceed,
    this.anyOnboarded,
    this.backhaulSnapshot,
    required this.isLoading,
    this.loadingMessage,
    this.onboardingTime = 0,
    this.nodes,
  });

  AddWiredNodesState copyWith({
    bool? onboardingProceed,
    bool? anyOnboarded,
    List<BackHaulInfoData>? backhaulSnapshot,
    bool? isLoading,
    String? loadingMessage,
    int? onboardingTime,
    List<LinksysDevice>? nodes,
  }) {
    return AddWiredNodesState(
      onboardingProceed: onboardingProceed ?? this.onboardingProceed,
      anyOnboarded: anyOnboarded ?? this.anyOnboarded,
      backhaulSnapshot: backhaulSnapshot ?? this.backhaulSnapshot,
      isLoading: isLoading ?? this.isLoading,
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
          ? List<BackHaulInfoData>.from(
              map['backhaulSnapshot']?.map((x) => BackHaulInfoData.fromMap(x)))
          : null,
      isLoading: map['isLoading'] ?? false,
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
      loadingMessage,
      onboardingTime,
      nodes,
    ];
  }
}
