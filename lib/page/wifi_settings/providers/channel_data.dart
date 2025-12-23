// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

export 'package:privacy_gui/page/wifi_settings/models/channel_constants.dart';

class ChannelDataInfo extends Equatable {
  final String band;
  final int channel;
  final String frequency;
  final bool dfs;
  final List<int> unii;
  const ChannelDataInfo({
    required this.band,
    required this.channel,
    required this.frequency,
    required this.dfs,
    required this.unii,
  });

  ChannelDataInfo copyWith({
    String? band,
    int? channel,
    String? frequency,
    bool? dfs,
    List<int>? unii,
  }) {
    return ChannelDataInfo(
      band: band ?? this.band,
      channel: channel ?? this.channel,
      frequency: frequency ?? this.frequency,
      dfs: dfs ?? this.dfs,
      unii: unii ?? this.unii,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'band': band,
      'channel': channel,
      'frequency': frequency,
      'dfs': dfs,
      'unii': unii,
    };
  }

  factory ChannelDataInfo.fromMap(Map<String, dynamic> map) {
    return ChannelDataInfo(
        band: map['band'] as String,
        channel: map['channel'] as int,
        frequency: map['frequency'] as String,
        dfs: map['dfs'] as bool,
        unii: List<int>.from(
          (map['unii']),
        ));
  }

  String toJson() => json.encode(toMap());

  factory ChannelDataInfo.fromJson(String source) =>
      ChannelDataInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      band,
      channel,
      frequency,
      dfs,
      unii,
    ];
  }
}
