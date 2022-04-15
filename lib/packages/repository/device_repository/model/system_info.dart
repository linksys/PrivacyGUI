import 'base_data_model.dart';

class SystemInfo extends BaseDataModel {
  SystemInfo(
      {required this.kernel,
      required this.system,
      required this.model,
      required this.release});

  final String kernel;
  final String system;
  final String model;
  final String release;

  factory SystemInfo.fromJson(Map<String, dynamic> json) {
    final result = json['result'][1];
    final kernel = result['kernel'];
    final system = result['system'];
    final model = result['model'];
    final release = result['release']['description'];
    return SystemInfo(
        kernel: kernel, system: system, model: model, release: release);
  }
}
