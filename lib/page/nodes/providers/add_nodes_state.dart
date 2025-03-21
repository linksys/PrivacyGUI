// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';

class AddNodesState extends Equatable {
  final bool? onboardingProceed;
  final bool? anyOnboarded;
  final List<LinksysDevice>? nodesSnapshot;
  final List<LinksysDevice>? addedNodes;
  final List<LinksysDevice>? childNodes;
  final bool isLoading;
  final String? loadingMessage;
  final List<String>? onboardedMACList;

  const AddNodesState({
    this.onboardingProceed,
    this.anyOnboarded,
    this.nodesSnapshot,
    this.addedNodes,
    this.childNodes,
    this.isLoading = false,
    this.loadingMessage,
    this.onboardedMACList,
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
      onboardedMACList,
    ];
  }

  AddNodesState copyWith({
    bool? onboardingProceed,
    bool? anyOnboarded,
    List<LinksysDevice>? nodesSnapshot,
    List<LinksysDevice>? addedNodes,
    List<LinksysDevice>? childNodes,
    bool? isLoading,
    String? loadingMessage,
    List<String>? onboardedMACList,
  }) {
    return AddNodesState(
      onboardingProceed: onboardingProceed ?? this.onboardingProceed,
      anyOnboarded: anyOnboarded ?? this.anyOnboarded,
      nodesSnapshot: nodesSnapshot ?? this.nodesSnapshot,
      addedNodes: addedNodes ?? this.addedNodes,
      childNodes: childNodes ?? this.childNodes,
      isLoading: isLoading ?? this.isLoading,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      onboardedMACList: onboardedMACList ?? this.onboardedMACList,
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
      'onboardedMACList': onboardedMACList,
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
          ? List<LinksysDevice>.from(
              map['nodesSnapshot'].map<LinksysDevice?>(
                (x) => LinksysDevice.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      addedNodes: map['addedNodes'] != null
          ? List<LinksysDevice>.from(
              map['addedNodes'].map<LinksysDevice?>(
                (x) => LinksysDevice.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      childNodes: map['childNodes'] != null
          ? List<LinksysDevice>.from(
              map['childNodes'].map<LinksysDevice?>(
                (x) => LinksysDevice.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
      isLoading: map['isLoading'],
      loadingMessage: map['loadingMessage'],
      onboardedMACList: map['onboardedMACList'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AddNodesState.fromJson(String source) =>
      AddNodesState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;
}
