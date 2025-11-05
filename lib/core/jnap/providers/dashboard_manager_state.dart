import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';

class DashboardManagerState extends Equatable {
  final NodeDeviceInfo? deviceInfo;
  final List<RouterRadio> mainRadios;
  final List<GuestRadioInfo> guestRadios;
  final bool isGuestNetworkEnabled;
  final int uptimes;
  final String? wanConnection;
  final List<String> lanConnections;
  final String? skuModelNumber;
  final int localTime;
  final String? cpuLoad;
  final String? memoryLoad;

  const DashboardManagerState({
    this.deviceInfo,
    this.mainRadios = const [],
    this.guestRadios = const [],
    this.isGuestNetworkEnabled = false,
    this.uptimes = 0,
    this.wanConnection,
    this.lanConnections = const [],
    this.skuModelNumber,
    this.localTime = 0,
    this.cpuLoad,
    this.memoryLoad,
  });

  @override
  List<Object?> get props {
    return [
      deviceInfo,
      mainRadios,
      guestRadios,
      isGuestNetworkEnabled,
      uptimes,
      wanConnection,
      lanConnections,
      skuModelNumber,
      localTime,
      cpuLoad,
      memoryLoad,
    ];
  }

  DashboardManagerState copyWith({
    NodeDeviceInfo? deviceInfo,
    List<RouterRadio>? mainRadios,
    List<GuestRadioInfo>? guestRadios,
    bool? isGuestNetworkEnabled,
    int? uptimes,
    String? wanConnection,
    List<String>? lanConnections,
    String? skuModelNumber,
    int? localTime,
    String? cpuLoad,
    String? memoryLoad,
  }) {
    return DashboardManagerState(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      mainRadios: mainRadios ?? this.mainRadios,
      guestRadios: guestRadios ?? this.guestRadios,
      isGuestNetworkEnabled:
          isGuestNetworkEnabled ?? this.isGuestNetworkEnabled,
      uptimes: uptimes ?? this.uptimes,
      wanConnection: wanConnection ?? this.wanConnection,
      lanConnections: lanConnections ?? this.lanConnections,
      skuModelNumber: skuModelNumber ?? this.skuModelNumber,
      localTime: localTime ?? this.localTime,
      cpuLoad: cpuLoad ?? this.cpuLoad,
      memoryLoad: memoryLoad ?? this.memoryLoad,
    );
  }

  // NOTE: fromMap, toMap, and fromJson are intentionally omitted as they depend on the old data structure
  // and are not critical for this refactoring step. They can be updated later if serialization is needed.

  @override
  bool get stringify => true;
}