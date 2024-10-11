// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';

class AddWiredNodesState extends Equatable {
  final bool? onboardingProceed;
  final bool? anyOnboarded;
  final List<BackHaulInfoData>? backhaulSnapshot;
  final bool isLoading;
  final String? loadingMessage;
  final int onboardingTime;

  const AddWiredNodesState({
    this.onboardingProceed,
    this.anyOnboarded,
    this.backhaulSnapshot,
    required this.isLoading,
    this.loadingMessage,
    this.onboardingTime = 0,
  });

  AddWiredNodesState copyWith({
    bool? onboardingProceed,
    bool? anyOnboarded,
    List<BackHaulInfoData>? nodesSnapshot,
    bool? isLoading,
    String? loadingMessage,
    int? onboardingTime,
  }) {
    return AddWiredNodesState(
      onboardingProceed: onboardingProceed ?? this.onboardingProceed,
      anyOnboarded: anyOnboarded ?? this.anyOnboarded,
      backhaulSnapshot: nodesSnapshot ?? this.backhaulSnapshot,
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      onboardingTime: onboardingTime ?? this.onboardingTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'onboardingProceed': onboardingProceed,
      'anyOnboarded': anyOnboarded,
      'nodesSnapshot': backhaulSnapshot?.map((x) => x.toMap()).toList(),
      'isLoading': isLoading,
      'loadingMessage': loadingMessage,
      'onboardingTime': onboardingTime,
    };
  }

  factory AddWiredNodesState.fromMap(Map<String, dynamic> map) {
    return AddWiredNodesState(
      onboardingProceed: map['onboardingProceed'],
      anyOnboarded: map['anyOnboarded'],
      backhaulSnapshot: map['nodesSnapshot'] != null
          ? List<BackHaulInfoData>.from(
              map['nodesSnapshot']?.map((x) => BackHaulInfoData.fromMap(x)))
          : null,
      isLoading: map['isLoading'] ?? false,
      loadingMessage: map['loadingMessage'],
      onboardingTime: map['onboardingTime'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AddWiredNodesState.fromJson(String source) =>
      AddWiredNodesState.fromMap(json.decode(source));

  @override
  String toString() {
    return 'AddWiredNodesState(onboardingProceed: $onboardingProceed, anyOnboarded: $anyOnboarded, nodesSnapshot: $backhaulSnapshot, isLoading: $isLoading, loadingMessage: $loadingMessage, onboardingTime: $onboardingTime)';
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
    ];
  }
}
