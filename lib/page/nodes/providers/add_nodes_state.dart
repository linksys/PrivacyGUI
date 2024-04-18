// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:linksys_app/core/jnap/models/device.dart';

class AddNodesState extends Equatable {
  final bool? onboardingProceed;
  final bool? anyOnboarded;
  final List<RawDevice>? nodesSnapshot;
  final List<RawDevice>? addedNodes;
  final List<RawDevice>? childNodes;
  final bool isLoading;
  final String? loadingMessage;
  final Object? error;

  const AddNodesState({
    this.onboardingProceed,
    this.anyOnboarded,
    this.nodesSnapshot,
    this.addedNodes,
    this.childNodes,
    this.isLoading = false,
    this.loadingMessage,
    this.error,
  });

  @override
  List<Object?> get props {
    return [
      onboardingProceed,
      anyOnboarded,
      nodesSnapshot,
      addedNodes,
      childNodes,
      isLoading,
      loadingMessage,
      error,
    ];
  }

  AddNodesState copyWith({
    bool? onboardingProceed,
    bool? anyOnboarded,
    List<RawDevice>? nodesSnapshot,
    List<RawDevice>? addedNodes,
    List<RawDevice>? childNodes,
    bool? isLoading,
    String? loadingMessage,
    Object? error,
  }) {
    return AddNodesState(
      onboardingProceed: onboardingProceed ?? this.onboardingProceed,
      anyOnboarded: anyOnboarded ?? this.anyOnboarded,
      nodesSnapshot: nodesSnapshot ?? this.nodesSnapshot,
      addedNodes: addedNodes ?? this.addedNodes,
      childNodes: childNodes ?? this.childNodes,
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'onboardingProceed': onboardingProceed,
      'anyOnboarded': anyOnboarded,
      'nodesSnapshot': nodesSnapshot?.map((x) => x.toMap()).toList(),
      'addedNodes': addedNodes?.map((x) => x.toMap()).toList(),
      'childNodes': childNodes?.map((x) => x.toMap()).toList(),
      'isLoading': isLoading,
      'loadingMessage': loadingMessage,
    }..removeWhere((key, value) => value == null);
  }

  factory AddNodesState.fromMap(Map<String, dynamic> map) {
    return AddNodesState(
      onboardingProceed: map['onboardingProceed'] != null
          ? map['onboardingProceed'] as bool
          : null,
      anyOnboarded:
          map['anyOnboarded'] != null ? map['anyOnboarded'] as bool : null,
      nodesSnapshot: map['nodesSnapshot'] != null
          ? List<RawDevice>.from(
              (map['nodesSnapshot'] as List<int>).map<RawDevice?>(
                (x) => RawDevice.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      addedNodes: map['addedNodes'] != null
          ? List<RawDevice>.from(
              (map['addedNodes'] as List<int>).map<RawDevice?>(
                (x) => RawDevice.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      childNodes: map['childNodes'] != null
          ? List<RawDevice>.from(
              (map['childNodes'] as List<int>).map<RawDevice?>(
                (x) => RawDevice.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      isLoading: map['isLoading'],
      loadingMessage: map['loadingMessage'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AddNodesState.fromJson(String source) =>
      AddNodesState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
