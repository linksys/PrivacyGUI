import 'base_data_model.dart';

class WanStatus extends BaseDataModel {
  WanStatus({required this.isOnline});

  final bool isOnline;

  factory WanStatus.fromJson(Map<String, dynamic> json) {
    final result = json['result'][1] as Map<String, dynamic>;
    bool isOnline = result['up'] as bool;
    return WanStatus(isOnline: isOnline);
  }
}
