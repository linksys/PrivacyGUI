// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacygui_widgets/widgets/topology/tree_node.dart';

typedef RouterTreeNode = AppTreeNode<TopologyModel>;

///
/// DO NOT instant root sealed class
///
sealed class BaseTopologyNode extends RouterTreeNode {
  BaseTopologyNode({required super.data, required super.children});
}

class OnlineTopologyNode extends BaseTopologyNode {
  OnlineTopologyNode({
    required super.children,
    required super.data,
  });
}

class OfflineTopologyNode extends BaseTopologyNode {
  OfflineTopologyNode({
    required super.children,
    required super.data,
  });
}

class RouterTopologyNode extends BaseTopologyNode {
  RouterTopologyNode({
    required super.data,
    required super.children,
  });
}

class DeviceTopologyNode extends BaseTopologyNode {
  DeviceTopologyNode({
    required super.data,
    required super.children,
  });
}

class TopologyModel extends Equatable {
  final String deviceId;
  final String location;
  final bool isMaster;
  final bool isOnline;
  final bool isWiredConnection;
  final int signalStrength;
  final bool isRouter;
  final String icon;
  final int connectedDeviceCount;

  const TopologyModel({
    this.deviceId = '',
    this.location = '',
    this.isMaster = false,
    this.isOnline = false,
    this.isWiredConnection = false,
    this.signalStrength = 0,
    this.isRouter = false,
    this.icon = 'genericDevice',
    this.connectedDeviceCount = 0,
  });

  TopologyModel copyWith({
    String? deviceId,
    String? location,
    bool? isMaster,
    bool? isOnline,
    bool? isWiredConnection,
    int? signalStrength,
    bool? isRouter,
    String? icon,
    int? connectedDeviceCount,
  }) {
    return TopologyModel(
      deviceId: deviceId ?? this.deviceId,
      location: location ?? this.location,
      isMaster: isMaster ?? this.isMaster,
      isOnline: isOnline ?? this.isOnline,
      isWiredConnection: isWiredConnection ?? this.isWiredConnection,
      signalStrength: signalStrength ?? this.signalStrength,
      isRouter: isRouter ?? this.isRouter,
      icon: icon ?? this.icon,
      connectedDeviceCount: connectedDeviceCount ?? this.connectedDeviceCount,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'deviceId': deviceId,
      'location': location,
      'isMaster': isMaster,
      'isOnline': isOnline,
      'isWiredConnection': isWiredConnection,
      'signalStrength': signalStrength,
      'isRouter': isRouter,
      'icon': icon,
      'connectedDeviceCount': connectedDeviceCount,
    };
  }

  factory TopologyModel.fromMap(Map<String, dynamic> map) {
    return TopologyModel(
      deviceId: map['deviceId'] as String,
      location: map['location'] as String,
      isMaster: map['isMaster'] as bool,
      isOnline: map['isOnline'] as bool,
      isWiredConnection: map['isWiredConnection'] as bool,
      signalStrength: map['signalStrength'] as int,
      isRouter: map['isRouter'] as bool,
      icon: map['icon'] as String,
      connectedDeviceCount: map['connectedDeviceCount'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory TopologyModel.fromJson(String source) =>
      TopologyModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object> get props {
    return [
      deviceId,
      location,
      isMaster,
      isOnline,
      isWiredConnection,
      signalStrength,
      isRouter,
      icon,
      connectedDeviceCount,
    ];
  }
}
