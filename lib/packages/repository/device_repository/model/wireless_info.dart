import 'base_data_model.dart';

class WirelessInfoList extends BaseDataModel {
  WirelessInfoList({required this.children});

  final List<WirelessInfo> children;

  factory WirelessInfoList.fromJson(Map<String, dynamic> json) {
    final result = json['result'][1]['values'] as Map<String, dynamic>;
    final wifiList =
        result.entries.where((element) => element.key.startsWith('wifi'));
    final wifiExtList = result.entries
        .where((element) => (element.value as Map<String, dynamic>)['device']
            .toString()
            .startsWith('wifi'))
        .map((e) => MapEntry<String, dynamic>(e.value['device'], e.value));
    final wifiExtMap = Map.fromEntries(wifiExtList);
    print("wifiExtMap: $wifiExtMap");
    return WirelessInfoList(
        children: wifiList
            .map((e) => WirelessInfo(
                ssid: wifiExtMap[e.key]['ssid'],
                macAddress: e.value['macaddr']))
            .toList());
  }
}

class WirelessInfo {
  const WirelessInfo({
    required this.ssid,
    required this.macAddress,
  });

  final String macAddress;
  final String ssid;
}
