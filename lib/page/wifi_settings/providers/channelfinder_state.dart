// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:equatable/equatable.dart';

import 'package:linksys_app/page/wifi_settings/_wifi_settings.dart';

class ChannelFinderState extends Equatable {
  final List<OptimizedSelectedChannel> result;
  const ChannelFinderState({
    required this.result,
  });

  ChannelFinderState copyWith(List<OptimizedSelectedChannel> result) {
    return ChannelFinderState(result: result);
  }

  @override
  List<Object?> get props => [result];
}
