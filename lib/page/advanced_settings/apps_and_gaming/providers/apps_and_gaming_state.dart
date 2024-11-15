import 'dart:convert';

import 'package:equatable/equatable.dart';

class AppsAndGamingViewState extends Equatable {
  final bool isCurrentViewStateChanged;
  const AppsAndGamingViewState({
    required this.isCurrentViewStateChanged,
  });

  AppsAndGamingViewState copyWith({
    bool? isCurrentViewStateChanged,
  }) {
    return AppsAndGamingViewState(
      isCurrentViewStateChanged: isCurrentViewStateChanged ?? this.isCurrentViewStateChanged,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isCurrentViewStateChanged': isCurrentViewStateChanged,
    };
  }

  factory AppsAndGamingViewState.fromMap(Map<String, dynamic> map) {
    return AppsAndGamingViewState(
      isCurrentViewStateChanged: map['isCurrentViewStateChanged'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppsAndGamingViewState.fromJson(String source) => AppsAndGamingViewState.fromMap(json.decode(source));

  @override
  String toString() => 'AppsAndGamingState(isCurrentViewStateChanged: $isCurrentViewStateChanged)';

  @override
  List<Object> get props => [isCurrentViewStateChanged];
}
