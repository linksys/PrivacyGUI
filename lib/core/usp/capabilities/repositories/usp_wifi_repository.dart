import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:usp_client_core/usp_client_core.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/usp/providers/polling_manager_provider.dart';
import '../../usp_mapper_repository.dart';
import '../capability_registry.dart';
import '../models/device_feature.dart';

// Defines the data structure for the WiFi bundle
class WifiDataBundle {
  final Map<String, dynamic> radioInfo;
  final Map<String, dynamic> guestRadioSettings;
  final Map<String, dynamic> macFilterSettings;

  WifiDataBundle({
    required this.radioInfo,
    required this.guestRadioSettings,
    required this.macFilterSettings,
  });
}

/// A generic interface allows swapping implementations (JNAP vs USP)
abstract class WifiRepository {
  Stream<WifiDataBundle> watchWifiBundle();
}

class UspWifiRepository implements WifiRepository {
  final UspWifiService _wifiService;
  final PollingManager _pollingManager;
  final bool Function(DeviceFeature) _hasFeature;

  late final ResourceWatcher<WifiDataBundle> _watcher;

  UspWifiRepository({
    required UspWifiService wifiService,
    required PollingManager pollingManager,
    required bool Function(DeviceFeature) hasFeature,
  })  : _wifiService = wifiService,
        _pollingManager = pollingManager,
        _hasFeature = hasFeature {
    _watcher = ResourceWatcher<WifiDataBundle>(
      path: 'Device.WiFi.',
      pollingManager: _pollingManager,
      strategy: WatchStrategy.eventPreferred,
      checkEventSupport: () => _hasFeature(DeviceFeature.rebootEvent),
      fetchData: _fetchBundle,
      ensureSubscription: _subscribeToWifi,
    );
  }

  @override
  Stream<WifiDataBundle> watchWifiBundle() {
    return _watcher.start();
  }

  Future<WifiDataBundle> _fetchBundle() async {
    final radioInfo = await _wifiService.getRadioInfo();
    final guestInfo = await _wifiService.getGuestRadioSettings();
    final macFilter = await _wifiService.getMACFilterSettings();

    return WifiDataBundle(
      radioInfo: radioInfo,
      guestRadioSettings: guestInfo,
      macFilterSettings: macFilter,
    );
  }

  Future<void> _subscribeToWifi() async {
    throw UnimplementedError('Subscription not supported yet');
  }

  void dispose() {
    _watcher.stop();
  }
}

final uspWifiRepositoryProvider = Provider<UspWifiRepository>((ref) {
  final repo = ref.watch(routerRepositoryProvider);

  if (repo is! UspMapperRepository) {
    throw UnimplementedError('UspWifiRepository requires UspMapperRepository');
  }

  final pollingManager = ref.watch(pollingManagerProvider);
  final capabilityRepo = ref.watch(capabilityRepositoryProvider);

  return UspWifiRepository(
    wifiService: repo.wifiService,
    pollingManager: pollingManager,
    hasFeature: capabilityRepo.hasFeature,
  );
});
