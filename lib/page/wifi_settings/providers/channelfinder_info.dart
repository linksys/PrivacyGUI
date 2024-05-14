import 'dart:convert';

import 'package:equatable/equatable.dart';

class SelectedChannels extends Equatable {
  final String deviceID;
  final List<Channel> channels;

  const SelectedChannels({required this.deviceID, required this.channels});

  factory SelectedChannels.fromJson(Map<String, dynamic> json) {
    return SelectedChannels(
        deviceID: json['deviceID'],
        channels: List.from(json['channels'])
            .map((value) => Channel.fromJson(value))
            .toList());
  }

  Map<String, dynamic> toJson() {
    return {'deviceID': deviceID, 'channels': jsonEncode(channels)};
  }

  SelectedChannels copyWith({String? deviceID, List<Channel>? channels}) {
    return SelectedChannels(
        deviceID: deviceID ?? this.deviceID,
        channels: channels ?? this.channels);
  }

  @override
  List<Object?> get props => [deviceID, channels];
}

class Channel extends Equatable {
  const Channel(
      {required this.radioID,
      required this.band,
      required this.channel,
      this.optimizedChannel,
      this.isOptimized,
      this.dfs});

  final String radioID;
  final String band;
  final int channel;
  final int? optimizedChannel;
  final bool? isOptimized;
  final bool? dfs;

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
        radioID: json['radioID'], band: json['band'], channel: json['channel']);
  }

  Map<String, dynamic> toJson() {
    return {'radioID': radioID, 'band': band, 'channel': channel};
  }

  Channel copyWith(
      {String? radioID,
      String? band,
      int? channel,
      int? optimizedChannel,
      bool? isOptimized,
      bool? dfs}) {
    return Channel(
        radioID: radioID ?? this.radioID,
        band: band ?? this.band,
        channel: channel ?? this.channel,
        optimizedChannel: optimizedChannel ?? this.optimizedChannel,
        isOptimized: isOptimized ?? this.isOptimized,
        dfs: dfs ?? this.dfs);
  }

  @override
  List<Object?> get props =>
      [radioID, band, channel, optimizedChannel, isOptimized, dfs];
}

class OptimizedSelectedChannel extends Equatable {
  final String deviceID;
  final List<Channel> channels;
  final String? deviceName;
  final String? deviceIcon;

  const OptimizedSelectedChannel(
      {required this.deviceID,
      required this.channels,
      this.deviceName,
      this.deviceIcon});

  factory OptimizedSelectedChannel.fromJson(Map<String, dynamic> json) {
    return OptimizedSelectedChannel(
      deviceID: json['deviceID'],
      channels: List.from(json['channels'])
          .map((value) => Channel.fromJson(value))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'deviceID': deviceID, 'channels': jsonEncode(channels)};
  }

  OptimizedSelectedChannel copyWith(
      {String? deviceID,
      List<Channel>? channels,
      String? deviceName,
      String? deviceIcon}) {
    return OptimizedSelectedChannel(
        deviceID: deviceID ?? this.deviceID,
        channels: channels ?? this.channels,
        deviceName: deviceName ?? this.deviceName,
        deviceIcon: deviceIcon ?? this.deviceIcon);
  }

  @override
  List<Object?> get props => [deviceID, channels, deviceName, deviceIcon];
}
