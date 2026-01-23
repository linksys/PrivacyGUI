import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
// removed unused import
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/services/channel_finder_service.dart';

final channelFinderProvider =
    NotifierProvider<ChannelFinderNotifier, ChannelFinderState>(
        () => ChannelFinderNotifier());

class ChannelFinderNotifier extends Notifier<ChannelFinderState> {
  @override
  ChannelFinderState build() {
    return const ChannelFinderState(result: []);
  }

  Future optimizeChannels() async {
    final service = ref.read(channelFinderServiceProvider);
    final oldChannels = await service.getSelectedChannels();
    if (oldChannels.isNotEmpty) {
      final devices = ref.read(deviceManagerProvider).deviceList;
      final optimized = await service.optimizeChannels(
          prevChannels: oldChannels, devices: devices);
      state = state.copyWith(optimized);
    }
  }
}
