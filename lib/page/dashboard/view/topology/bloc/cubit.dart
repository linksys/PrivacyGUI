import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/page/dashboard/view/topology/bloc/state.dart';
import 'package:linksys_moab/page/dashboard/view/topology/topology_node.dart';
import 'package:linksys_moab/repository/router/device_list_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

class TopologyCubit extends Cubit<TopologyState> {
  TopologyCubit(RouterRepository repository)
      : _repository = repository,
        super(TopologyState(rootNode: TopologyNode()));

  final RouterRepository _repository;

  Future fetchTopologyData() async {
    // TODO: In order to get signal strength, more requests needed
    final results = await _repository.getDevices();
    final getDevicesOutput = results.output;
    var devices = List.from(getDevicesOutput['devices']).map((e) => RouterDevice.fromJson(e)).toList();

    final masterDeviceID = devices.firstWhereOrNull((device) {
      return device.isAuthority || device.nodeType == 'Master';
    })?.deviceID ?? '';

    final nodeDevices = devices.where((device) =>
    device.isAuthority || device.nodeType != null
    );

    Map<String, TopologyNode> nodeMap = {}; // {DeviceID : NodeObject}

    for (final device in nodeDevices) {
      String deviceID = device.deviceID;
      String location = _getDeviceLocation(device);
      bool isMaster = deviceID == masterDeviceID;
      bool isOnline = device.connections.isNotEmpty;
      bool isWiredConnection = _checkIfWiredConnection(device);
      int signalStrength = 0; //TODO: Find a way to get node signal data

      nodeMap[deviceID] = TopologyNode(
        deviceID: deviceID,
        location: location,
        isMaster: isMaster,
        isOnline: isOnline,
        isWiredConnection: isWiredConnection,
        signalStrength: signalStrength,
        connectedDeviceCount: 0, // Will get this later
        children: [], // Will get this later
      );
    }

    final masterNode = nodeMap[masterDeviceID]!;

    for (final device in nodeDevices) {
      var node = nodeMap[device.deviceID]!;
      // Master will not be child of any node else
      if (!node.isMaster) {
        final parentDeviceID = device.connections.firstOrNull?.parentDeviceID;
        if (parentDeviceID != null) {
          var parentNode = nodeMap[parentDeviceID];
          if (parentNode != null) {
            parentNode.children.add(node);
          } else {
            // Should not be ture - parentDeviceID should always be valid if it exists
            masterNode.children.add(node);
          }
        } else {
          // If parentDeviceID doesn't exist, the current node will be the child of Master
          masterNode.children.add(node);
        }
      }
    }

    final externalDevices = devices.whereNot((device) =>
    device.isAuthority || device.nodeType != null
    );

    for (final device in externalDevices) {
      final parentDeviceID = device.connections.firstOrNull?.parentDeviceID;
      if (parentDeviceID != null) {
        var parentNode = nodeMap[parentDeviceID];
        if (parentNode != null) {
          parentNode.connectedDeviceCount++;
        } else {
          // Should not be ture - parentDeviceID should always be valid if it exists
          masterNode.connectedDeviceCount++;
        }
      } else {
        // If parentDeviceID doesn't exist, the external device will be counted under the Master
        masterNode.connectedDeviceCount++;
      }
    }

    emit(state.copyWith(rootNode: masterNode));
  }

  //TODO: Duplicate function!!
  bool _checkIfWiredConnection(RouterDevice device) {
    bool isWired = false;
    final interfaces = device.knownInterfaces;
    if (interfaces != null) {
      for (final interface in interfaces) {
        if (interface.interfaceType == 'Wired') {
          isWired = true;
        }
      }
    }
    return isWired;
  }

  String _getDeviceLocation(RouterDevice device) {
    for (final property in device.properties) {
      if (property.name == 'userDeviceLocation' && property.value.isNotEmpty) {
        return property.value;
      }
    }
    return getDeviceName(device);
  }

  String getDeviceName(RouterDevice device) {
    for (final property in device.properties) {
      if (property.name == 'userDeviceName' && property.value.isNotEmpty) {
        return property.value;
      }
    }

    bool isAndroidDevice = false;
    if (device.friendlyName != null) {
      // TODO: Fix this regExp
      //final regExp = RegExp('^Android$|^android-[a-fA-F0-9]{16}.*|^Android-[0-9]+');
      final regExp = RegExp('^android-[a-fA-F0-9]{16}.*|^Android-[0-9]+');
      isAndroidDevice = regExp.hasMatch(device.friendlyName!);
    }

    String? androidDeviceName;
    if (isAndroidDevice &&
        ['Mobile', 'Phone', 'Tablet'].contains(device.model.deviceType)) {
      final manufacturer = device.model.manufacturer;
      final modelNumber = device.model.modelNumber;
      if (manufacturer != null && modelNumber != null) {
        // e.g. 'Samsung Galaxy S8'
        androidDeviceName = manufacturer + ' ' + modelNumber;
      } else if (device.unit.operatingSystem != null) {
        // e.g. 'Android Oreo Mobile'
        androidDeviceName =
            device.unit.operatingSystem! + ' ' + device.model.deviceType;
        if (manufacturer != null) {
          // e.g. 'Samsung Android Oreo Mobile'
          androidDeviceName = manufacturer! + androidDeviceName!;
        }
      }
    }

    if (androidDeviceName != null) {
      return androidDeviceName;
    } else if (device.friendlyName != null) {
      return device.friendlyName!;
    } else if (device.model.modelNumber != null) {
      return device.model.modelNumber!;
    } else {
      // Check if it's a guest device
      bool isGuest = false;
      for (final connectionDevice in device.connections) {
        isGuest = connectionDevice.isGuest ?? false;
      }
      return isGuest ? 'Guest Network Device' : 'Network Device';
    }
  }
}
