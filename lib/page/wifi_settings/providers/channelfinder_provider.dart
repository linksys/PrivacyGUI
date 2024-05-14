import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';

final channelFinderProvider =
    NotifierProvider<ChannelFinderNotifier, ChannelFinderState>(
        () => ChannelFinderNotifier());

class ChannelFinderNotifier extends Notifier<ChannelFinderState> {
  final int pollingInterval = 5000;
  int pollingCount = 1;
  int maxPollingCount = 30;
  int previousChannelCount = 0;
  @override
  ChannelFinderState build() {
    return const ChannelFinderState(result: []);
  }

  Future optimizeChannels() async {
    final oldChannels = await _getSelectedChannels();
    if (oldChannels is List<SelectedChannels>) {
      final optimzed = await _optimizeChannelSuccessCallback(oldChannels);
      state.copyWith(optimzed);
    }
  }

  Future _optimizeChannelSuccessCallback(
      List<SelectedChannels> prevChannels) async {
    final newChannels = await _doAutoChannelSelection(prevChannels.length);
    final isEqual =
        const DeepCollectionEquality().equals(prevChannels, newChannels);
    var optimizedChannels =
        _makeOptimizedChannels(prevChannels, newChannels, isEqual);
    for (var element in optimizedChannels) {
      for (var value in element.channels) {
        value.copyWith(
            dfs: lookupChannelDataInfoByChannel(value.channel, value.band).dfs);
      }
    }
    return optimizedChannels;
  }

  Future _getSelectedChannels() async {
    final response = await ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.getSelectedChannels, cacheLevel: CacheLevel.noCache);
    if (response.output['isRunning'] == true) {
      throw const JNAPError(result: 'already Running');
    } else if (response.output['selectedChannels'] != null) {
      return List.from(response.output['selectedChannels'])
          .map((value) => SelectedChannels.fromJson(value))
          .toList();
    }
  }

  Future _doAutoChannelSelection(int existingChannelCount) async {
    pollingCount = 1;
    previousChannelCount = existingChannelCount;
    await ref
        .read(routerRepositoryProvider)
        .send(JNAPAction.startAutoChannelSelection);
    return _checkIfChannelSelectionRunning();
  }

  Future _checkIfChannelSelectionRunning() async {
    while (pollingCount <= maxPollingCount) {
      logger.d('Check channel selection running count : $pollingCount');
      final result = await ref
          .read(routerRepositoryProvider)
          .send(JNAPAction.getSelectedChannels, cacheLevel: CacheLevel.noCache);
      if (result.output['isRunning'] ||
          List.from(result.output['selectedChannels']).length <
              previousChannelCount) {
        pollingCount++;
        await Future.delayed(Duration(milliseconds: pollingInterval));
      } else {
        return List.from(result.output['selectedChannels'])
            .map((value) => SelectedChannels.fromJson(value))
            .toList();
      }
    }
  }

  List<OptimizedSelectedChannel> _makeOptimizedChannels(
      List<SelectedChannels> previousChannels,
      List<SelectedChannels> newChannels,
      bool isEqual) {
    logger.d('makeOptimizedChannels: previous ${previousChannels.toString()}');
    logger.d('makeOptimizedChannels: new ${newChannels.toString()}');
    final optimizedPreviousChannels = previousChannels
        .map((oldChannel) => _lookup(oldChannel, newChannels, isEqual))
        .toList();
    return optimizedPreviousChannels;
  }

  OptimizedSelectedChannel _lookup(SelectedChannels oldChannel,
      List<SelectedChannels> newChannels, bool isEqual) {
    var oldChannelDeviceID = oldChannel.deviceID;
    var foundDevice = newChannels
        .firstWhere((element) => element.deviceID == oldChannelDeviceID);
    var optimizedOldChannel = OptimizedSelectedChannel(
        deviceID: oldChannelDeviceID, channels: oldChannel.channels);
    var device = ref
        .read(deviceManagerProvider)
        .deviceList
        .firstWhere((element) => element.deviceID == oldChannelDeviceID);
    optimizedOldChannel = optimizedOldChannel.copyWith(
        deviceName: device.friendlyName,
        deviceIcon: routerIconTestByModel(modelNumber: device.modelNumber!));
    if (!isEqual &&
        !const DeepCollectionEquality()
            .equals(oldChannel.channels, foundDevice.channels)) {
      for (var i = 0; i < oldChannel.channels.length; i++) {
        if (oldChannel.channels[i].channel != foundDevice.channels[i].channel) {
          oldChannel.channels[i].copyWith(
              optimizedChannel: foundDevice.channels[i].channel,
              isOptimized: true);
        }
      }
    }
    return optimizedOldChannel;
  }

  int _getChannelSelectionDurationEstimate() {
    var numOnline = 1;
    ref.read(deviceManagerProvider).slaveDevices.forEach((node) {
      if (node.connections.isNotEmpty) {
        numOnline++;
      }
    });
    return numOnline * 60000;
  }

  int _countOptimizedNodes(
      List<OptimizedSelectedChannel> optimizedSelectedChannels) {
    var arr = optimizedSelectedChannels.where((element) {
      return element.channels.any((channel) => channel.isOptimized == true);
    }).toList();
    return arr.length;
  }
}
