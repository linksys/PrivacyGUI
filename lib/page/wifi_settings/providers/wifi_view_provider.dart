// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wifiViewProvider =
    NotifierProvider<WiFiViewNotifier, WiFiViewState>(() => WiFiViewNotifier());

class WiFiViewState extends Equatable {
  final bool isCurrentViewStateChanged;
  const WiFiViewState({
    required this.isCurrentViewStateChanged,
  });

  WiFiViewState copyWith({
    bool? isCurrentViewStateChanged,
  }) {
    return WiFiViewState(
      isCurrentViewStateChanged:
          isCurrentViewStateChanged ?? this.isCurrentViewStateChanged,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isCurrentViewStateChanged': isCurrentViewStateChanged,
    };
  }

  factory WiFiViewState.fromMap(Map<String, dynamic> map) {
    return WiFiViewState(
      isCurrentViewStateChanged: map['isCurrentViewStateChanged'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory WiFiViewState.fromJson(String source) =>
      WiFiViewState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [isCurrentViewStateChanged];
}

class WiFiViewNotifier extends Notifier<WiFiViewState> {
  @override
  WiFiViewState build() {
    return const WiFiViewState(isCurrentViewStateChanged: false);
  }

  void setChanged(bool value) {
    state = state.copyWith(isCurrentViewStateChanged: value);
  }
}
