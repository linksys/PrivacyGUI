import 'package:collection/collection.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/wifi_settings/providers/channel_data.dart';
import 'package:privacy_gui/page/wifi_settings/providers/channelfinder_info.dart';

class ChannelFinderService {
  final RouterRepository _repo;
  final int pollingInterval = 5000;
  final int maxPollingCount = 30;

  ChannelFinderService(this._repo);

  Future<List<SelectedChannels>> getSelectedChannels() async {
    final response = await _repo.send(JNAPAction.getSelectedChannels,
        cacheLevel: CacheLevel.noCache);
    if (response.output['isRunning'] == true) {
      throw const JNAPError(result: 'already Running');
    } else if (response.output['selectedChannels'] != null) {
      return List.from(response.output['selectedChannels'])
          .map((value) => SelectedChannels.fromJson(value))
          .toList();
    }
    return [];
  }

  Future<List<OptimizedSelectedChannel>> optimizeChannels({
    required List<SelectedChannels> prevChannels,
    required List<LinksysDevice> devices,
  }) async {
    final newChannels = await _doAutoChannelSelection(prevChannels.length);
    final isEqual =
        const DeepCollectionEquality().equals(prevChannels, newChannels);
    var optimizedChannels =
        _makeOptimizedChannels(prevChannels, newChannels, isEqual, devices);

    // Fix bug: Ensure immutability is respected
    return optimizedChannels.map((e) {
      final newChannels = e.channels.map((c) {
        return c.copyWith(
            dfs: _lookupChannelDataInfoByChannel(c.channel, c.band).dfs);
      }).toList();
      return e.copyWith(channels: newChannels);
    }).toList();
  }

  ChannelDataInfo _lookupChannelDataInfoByChannel(int channel, String band) {
    return ChannelDataInfo.fromMap(channelData.firstWhere(
        (element) => element['band'] == band && element['channel'] == channel));
  }

  Future<List<SelectedChannels>> _doAutoChannelSelection(
      int existingChannelCount) async {
    await _repo.send(JNAPAction.startAutoChannelSelection);
    return _checkIfChannelSelectionRunning(existingChannelCount);
  }

  Future<List<SelectedChannels>> _checkIfChannelSelectionRunning(
      int previousChannelCount) async {
    int pollingCount = 1;
    while (pollingCount <= maxPollingCount) {
      logger.d('Check channel selection running count : $pollingCount');
      final result = await _repo.send(JNAPAction.getSelectedChannels,
          cacheLevel: CacheLevel.noCache);
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
    throw const JNAPError(result: 'Timeout');
  }

  List<OptimizedSelectedChannel> _makeOptimizedChannels(
      List<SelectedChannels> previousChannels,
      List<SelectedChannels> newChannels,
      bool isEqual,
      List<LinksysDevice> devices) {
    logger.d('makeOptimizedChannels: previous ${previousChannels.toString()}');
    logger.d('makeOptimizedChannels: new ${newChannels.toString()}');
    final optimizedPreviousChannels = previousChannels
        .map((oldChannel) => _lookup(oldChannel, newChannels, isEqual, devices))
        .toList();
    return optimizedPreviousChannels;
  }

  OptimizedSelectedChannel _lookup(
      SelectedChannels oldChannel,
      List<SelectedChannels> newChannels,
      bool isEqual,
      List<LinksysDevice> devices) {
    var oldChannelDeviceID = oldChannel.deviceID;
    var foundDevice = newChannels
        .firstWhere((element) => element.deviceID == oldChannelDeviceID);

    // Fix bug: Channel is immutable
    List<Channel> mappedChannels = List.from(oldChannel.channels);

    var device =
        devices.firstWhere((element) => element.deviceID == oldChannelDeviceID);

    if (!isEqual &&
        !const DeepCollectionEquality()
            .equals(oldChannel.channels, foundDevice.channels)) {
      for (var i = 0; i < oldChannel.channels.length; i++) {
        if (oldChannel.channels[i].channel != foundDevice.channels[i].channel) {
          mappedChannels[i] = mappedChannels[i].copyWith(
              optimizedChannel: foundDevice.channels[i].channel,
              isOptimized: true);
        }
      }
    }
    return OptimizedSelectedChannel(
        deviceID: oldChannelDeviceID,
        channels: mappedChannels,
        deviceName: device.friendlyName,
        deviceIcon: routerIconTestByModel(modelNumber: device.modelNumber!));
  }
}
