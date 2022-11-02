import 'package:equatable/equatable.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/model/router/unconfigured_node.dart';

enum AddNodesStatus {
  init,
  findingNodes,
  noNodesFound,
  addingNodes,
  allDone,
  someDone,
}

enum AddNodesMode {
  setup,
  addNodeOnly,
}

class AddNodesState extends Equatable {
  final AddNodesMode mode;
  final AddNodesStatus status;
  final List<BTDiscoveryData> foundNodes;
  final List<NodeProperties> properties;
  final String? error;

  @override
  List<Object?> get props => [
        mode,
        status,
        foundNodes,
        properties,
        error,
      ];

  const AddNodesState({
    this.mode = AddNodesMode.setup,
    required this.status,
    this.foundNodes = const [],
    this.properties = const [],
    this.error,
  });

  factory AddNodesState.init({AddNodesMode mode = AddNodesMode.setup}) {
    return AddNodesState(
      mode: mode,
      status: AddNodesStatus.init,
      foundNodes: const [],
      properties: const [],
      error: null,
    );
  }

  AddNodesState copyWith({
    AddNodesMode? mode,
    AddNodesStatus? status,
    List<BTDiscoveryData>? foundNodes,
    List<NodeProperties>? properties,
    String? error,
  }) {
    return AddNodesState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      foundNodes: foundNodes ?? this.foundNodes,
      properties: properties ?? this.properties,
      error: error ?? this.error,
    );
  }
}

class NodeProperties extends Equatable {
  final String deviceId;
  final String? location;
  final bool isMaster;
  final bool isModify;

  const NodeProperties({
    required this.deviceId,
    this.location,
    this.isMaster = false,
    this.isModify = false,
  });

  NodeProperties copyWith({
    String? deviceId,
    String? location,
    bool? isMaster,
    bool? isModify,
  }) {
    return NodeProperties(
      deviceId: deviceId ?? this.deviceId,
      location: location ?? this.location,
      isMaster: isMaster ?? this.isMaster,
      isModify: isModify ?? this.isModify,
    );
  }

  List<Map<String, dynamic>> buildPropertiesToModify() {
    return [
      {
        'name': userDefinedDeviceLocation,
        'value': location,
      }
    ];
  }

  @override
  List<Object?> get props => [
        deviceId,
        location,
        isMaster,
        isModify,
      ];
}
