import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

import 'mascot_message_templates.dart';

/// L2 Provider for generating dynamic mascot messages.
///
/// Depends on L1 dashboard providers and only activates after
/// [dashboardDomainReadyProvider] has resolved.
final mascotMessageProvider =
    Provider.autoDispose<MascotMessageNotifier>((ref) {
  final isReady = ref.watch(dashboardDomainReadyProvider).hasValue;
  if (!isReady) {
    return MascotMessageNotifier._empty(ref);
  }
  return MascotMessageNotifier(ref);
});

/// Generates dynamic mascot messages based on system state.
class MascotMessageNotifier {
  final Ref _ref;
  final Random _random;
  final bool _isEmpty;

  MascotMessageNotifier(this._ref)
      : _random = Random(),
        _isEmpty = false;

  MascotMessageNotifier._empty(this._ref)
      : _random = Random(),
        _isEmpty = true;

  /// Get a random message, selecting category by weight then template randomly.
  MascotMessage getRandomMessage() {
    if (_isEmpty) {
      return MascotMessage.fallback;
    }

    final category = _selectCategoryByWeight();
    final message = _generateFromCategory(category);

    debugPrint('[Mascot] Generated ${message.category.name}: ${message.text}');
    return message;
  }

  /// Select a category based on configured weights.
  MascotMessageCategory _selectCategoryByWeight() {
    final totalWeight =
        categoryWeights.values.fold<int>(0, (sum, w) => sum + w);
    var roll = _random.nextInt(totalWeight);

    for (final entry in categoryWeights.entries) {
      roll -= entry.value;
      if (roll < 0) {
        return entry.key;
      }
    }
    return MascotMessageCategory.tips;
  }

  /// Generate a message from the selected category.
  MascotMessage _generateFromCategory(MascotMessageCategory category) {
    final templates = getTemplatesForCategory(category);
    final context = _buildContext();

    // Filter templates that pass their condition
    final validTemplates =
        templates.where((t) => t.shouldShow(context)).toList();

    if (validTemplates.isEmpty) {
      // Fallback to tips if no valid templates
      return _generateFromCategory(MascotMessageCategory.tips);
    }

    final template = validTemplates[_random.nextInt(validTemplates.length)];
    return MascotMessage(
      text: template.generate(context),
      category: template.category,
      suggestedAnimation: template.suggestedAnimation,
    );
  }

  /// Build context by reading from L1 providers.
  MascotMessageContext _buildContext() {
    // System info
    final systemInfo = _ref.read(systemInfoDataProvider).valueOrNull;
    final cpuPercent = systemInfo?.model.cpuPercent;
    final memoryPercent = systemInfo?.model.memoryPercent;
    final uptime = systemInfo?.model.formattedUptime;

    // Devices
    final devicesData = _ref.read(devicesDataProvider).valueOrNull;
    final onlineDeviceCount = devicesData?.onlineClientCount;
    final totalDeviceCount = devicesData?.totalClientCount;
    final meshNodeCount = devicesData?.nodes.where((n) => !n.isMaster).length;

    // WAN
    final wanData = _ref.read(wanDataProvider).valueOrNull;
    final wanConnected = wanData?.model.isUp;
    final wanIp = wanData?.model.ipAddress;

    // WiFi
    final wifiData = _ref.read(wifiDataProvider).valueOrNull;
    final totalRadioCount = wifiData?.radioModels.length;
    final enabledRadioCount =
        wifiData?.radioModels.where((r) => r.enable).length;

    return MascotMessageContext(
      cpuPercent: cpuPercent,
      memoryPercent: memoryPercent,
      uptime: uptime,
      onlineDeviceCount: onlineDeviceCount,
      totalDeviceCount: totalDeviceCount,
      meshNodeCount: meshNodeCount,
      wanConnected: wanConnected,
      wanIp: wanIp,
      enabledRadioCount: enabledRadioCount,
      totalRadioCount: totalRadioCount,
    );
  }
}
