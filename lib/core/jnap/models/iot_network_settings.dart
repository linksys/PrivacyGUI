import 'package:equatable/equatable.dart';

class IoTNetworkSetting extends Equatable {
  final bool isIoTNetworkEnabled;

  @override
  List<Object?> get props => [
    isIoTNetworkEnabled,
  ];

  const IoTNetworkSetting({
    required this.isIoTNetworkEnabled,
  });

  IoTNetworkSetting copyWith({
    bool? isIoTNetworkEnabled,
  }) {
    return IoTNetworkSetting(
      isIoTNetworkEnabled: isIoTNetworkEnabled ?? this.isIoTNetworkEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isIoTNetworkEnabled': isIoTNetworkEnabled,
    }..removeWhere((key, value) => value == null);
  }

  factory IoTNetworkSetting.fromJson(Map<String, dynamic> json) {
    return IoTNetworkSetting(
      isIoTNetworkEnabled: json['isIoTNetworkEnabled'],
    );
  }
}