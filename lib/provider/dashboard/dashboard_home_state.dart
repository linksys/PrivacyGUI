import 'package:flutter/foundation.dart';

@immutable
class DashboardHomeState {
  final String mainWifiSsid;
  final int numOfWifi;
  final int numOfNodes;
  final int numOfOnlineExternalDevices;
  final bool isWanConnected;
  final bool isFirstPolling;
  final String masterIcon;
  final ({String value, String unit}) uploadResult;
  final ({String value, String unit}) downloadResult;

  const DashboardHomeState({
    this.mainWifiSsid = '',
    this.numOfWifi = 0,
    this.numOfNodes = 0,
    this.numOfOnlineExternalDevices = 0,
    this.isWanConnected = false,
    this.isFirstPolling = false,
    this.masterIcon = '',
    this.uploadResult = (value: '', unit: ''),
    this.downloadResult = (value: '', unit: ''),
  });

  DashboardHomeState copyWith({
    String? mainWifiSsid,
    int? numOfWifi,
    int? numOfNodes,
    int? numOfOnlineExternalDevices,
    bool? isWanConnected,
    bool? isFirstPolling,
    String? masterIcon,
    ({String value, String unit})? uploadResult,
    ({String value, String unit})? downloadResult,
  }) {
    return DashboardHomeState(
      mainWifiSsid: mainWifiSsid ?? this.mainWifiSsid,
      numOfWifi: numOfWifi ?? this.numOfWifi,
      numOfNodes: numOfNodes ?? this.numOfNodes,
      numOfOnlineExternalDevices:
          numOfOnlineExternalDevices ?? this.numOfOnlineExternalDevices,
      isWanConnected: isWanConnected ?? this.isWanConnected,
      isFirstPolling: isFirstPolling ?? this.isFirstPolling,
      masterIcon: masterIcon ?? this.masterIcon,
      uploadResult: uploadResult ?? this.uploadResult,
      downloadResult: downloadResult ?? this.downloadResult,
    );
  }
}
