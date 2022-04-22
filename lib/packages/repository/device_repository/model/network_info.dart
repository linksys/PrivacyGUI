import 'base_data_model.dart';

class NetworkInfo extends BaseDataModel {
  NetworkInfo({required this.download, required this.upload});

  final int download;
  final int upload;

  factory NetworkInfo.fromJson(Map<String, dynamic> json) {
    final result = json['result'][1];
    final statistics = result['statistics'];
    final download = int.parse(statistics['rx_bytes'].toString());
    final upload = int.parse(statistics['tx_bytes'].toString());

    return NetworkInfo(download: download, upload: upload);
  }
}
