// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wifiViewProvider =
    NotifierProvider<WiFiViewNotifier, WiFiViewState>(() => WiFiViewNotifier());

class WiFiViewState extends Equatable {
  final bool isWifiListViewStateChanged;
  final bool isWifiAdvancedSettingsViewStateChanged;
  final bool isMacFilteringViewStateChanged;

  const WiFiViewState({
    this.isWifiListViewStateChanged = false,
    this.isWifiAdvancedSettingsViewStateChanged = false,
    this.isMacFilteringViewStateChanged = false,
  });

  WiFiViewState copyWith({
    bool? isWifiListViewStateChanged,
    bool? isWifiAdvancedSettingsViewStateChanged,
    bool? isMacFilteringViewStateChanged,
  }) {
    return WiFiViewState(
      isWifiListViewStateChanged:
          isWifiListViewStateChanged ?? this.isWifiListViewStateChanged,
      isWifiAdvancedSettingsViewStateChanged:
          isWifiAdvancedSettingsViewStateChanged ??
              this.isWifiAdvancedSettingsViewStateChanged,
      isMacFilteringViewStateChanged:
          isMacFilteringViewStateChanged ?? this.isMacFilteringViewStateChanged,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isWifiListViewStateChanged': isWifiListViewStateChanged,
      'isWifiAdvancedSettingsViewStateChanged':
          isWifiAdvancedSettingsViewStateChanged,
      'isMacFilteringViewStateChanged': isMacFilteringViewStateChanged,
    };
  }

  factory WiFiViewState.fromMap(Map<String, dynamic> map) {
    return WiFiViewState(
      isWifiListViewStateChanged: map['isWifiListViewStateChanged'] as bool,
      isWifiAdvancedSettingsViewStateChanged:
          map['isWifiAdvancedSettingsViewStateChanged'] as bool,
      isMacFilteringViewStateChanged:
          map['isMacFilteringViewStateChanged'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory WiFiViewState.fromJson(String source) =>
      WiFiViewState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [
        isWifiListViewStateChanged,
        isWifiAdvancedSettingsViewStateChanged,
        isMacFilteringViewStateChanged,
      ];
}

class WiFiViewNotifier extends Notifier<WiFiViewState> {
  @override
  WiFiViewState build() {
    return const WiFiViewState();
  }

  bool hasChanged() {
    return state.isWifiListViewStateChanged ||
        state.isWifiAdvancedSettingsViewStateChanged;
  }

  void setWifiListViewStateChanged(bool value) {
    state = state.copyWith(isWifiListViewStateChanged: value);
  }

  void setWifiAdvancedSettingsViewChanged(bool value) {
    state = state.copyWith(isWifiAdvancedSettingsViewStateChanged: value);
  }

  void setMacFilteringViewChanged(bool value) {
    state = state.copyWith(isMacFilteringViewStateChanged: value);
  }
}
