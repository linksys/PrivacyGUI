import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'package:privacy_gui/page/instant_verify/models/instant_verify_ui_models.dart';

class WANExternalState extends Equatable {
  final WanExternalUIModel? wanExternal;
  final int lastUpdate;

  const WANExternalState({
    this.wanExternal,
    this.lastUpdate = 0,
  });

  WANExternalState copyWith({
    WanExternalUIModel? wanExternal,
    int? lastUpdate,
  }) {
    return WANExternalState(
      wanExternal: wanExternal ?? this.wanExternal,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wanExternal': wanExternal?.toMap(),
      'lastUpdate': lastUpdate,
    };
  }

  factory WANExternalState.fromMap(Map<String, dynamic> map) {
    return WANExternalState(
      wanExternal: map['wanExternal'] != null
          ? WanExternalUIModel.fromMap(map['wanExternal'])
          : null,
      lastUpdate: map['lastUpdate']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory WANExternalState.fromJson(String source) =>
      WANExternalState.fromMap(json.decode(source));

  @override
  String toString() =>
      'WanExternalState(wanExternal: $wanExternal, lastUpdate: $lastUpdate)';

  @override
  List<Object?> get props => [wanExternal, lastUpdate];
}
