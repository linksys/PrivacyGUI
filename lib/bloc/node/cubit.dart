import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/node/state.dart';
import 'package:linksys_moab/model/router/wan_status.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/network/better_action.dart';
import 'package:linksys_moab/repository/router/batch_extension.dart';
import 'package:linksys_moab/repository/router/core_extension.dart';
import 'package:linksys_moab/repository/router/device_list_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

class NodeCubit extends Cubit<NodeState> {
  NodeCubit(RouterRepository repository)
      : _repository = repository,
        super(const NodeState());

  final RouterRepository _repository;
  Map<String, String> locationMap = {};

  void setDetailNodeID(String deviceID) {
    emit(state.copyWith(
      deviceID: deviceID,
    ));
  }

  Future fetchNodeDetailData() async {
    final results = await _repository.fetchNodeDetails();

    String wanIpAddress = '';
    final getWANStatusOutput =
        results[JNAPAction.getWANStatus.actionValue]?.output;
    if (getWANStatusOutput != null) {
      final wanStatusModel = RouterWANStatus.fromJson(getWANStatusOutput);
      wanIpAddress = wanStatusModel.wanConnection?.ipAddress ?? '';
    }

    final getFirmwareUpdateStatusOutput =
        results[JNAPAction.getFirmwareUpdateStatus.actionValue]?.output;
    final isLatestFW =
        (getFirmwareUpdateStatusOutput?['availableUpdate']) == null;

    final getDevicesOutput = results[JNAPAction.getDevices.actionValue]?.output;
    var devices = List.from(getDevicesOutput?['devices'])
        .map((e) => RouterDevice.fromJson(e))
        .toList();

    emit(_getNodeDetailState(state.deviceID, wanIpAddress, isLatestFW, devices));
  }

  Future updateNodeLocation(String newLocation) async {
    final results = await _repository.setDeviceProperties(
      deviceId: state.deviceID,
      propertiesToModify: [
        {
          'name': 'userDeviceName',
          'value': newLocation,
        }
      ],
    );

    if (results.result == 'OK') {
      emit(state.copyWith(
        location: newLocation,
      ));
    }
  }

  Future updateNodeLightSwitch(bool isOn) async {
    //TODO: Implement real commands for switching the light
    emit(state.copyWith(
      isLightTurnedOn: isOn,
    ));
  }

  Future rebootMeshSystem() async {
    emit(state.copyWith(
      isSystemRestarting: true,
    ));
    final results = await _repository.reboot();
    if (results.result == 'OK') {
      Future.delayed(const Duration(seconds: 130), () {
        emit(state.copyWith(
          isSystemRestarting: false,
        ));
      });
    } else {
      emit(state.copyWith(
        isSystemRestarting: false,
      ));
    }
  }

  NodeState _getNodeDetailState(String targetID, String wanIpAddress,
      bool isLatestFW, List<RouterDevice> devices) {
    // The detail data of the current node
    String location = '';
    bool isMaster = false;
    bool isOnline = false;
    List<RouterDevice> connectedDevices = [];
    String upstreamNode = '';
    bool isWired = false;
    String serialNumber = '';
    String modelNumber = '';
    String firmwareVersion = '';
    String lanIpAddress = '';

    devices.sort((device1, device2) {
      if (device1.isAuthority) {
        return -1;
      } else if (device1.nodeType == null) {
        return 1;
      } else if (device2.nodeType != null) {
        return (device1.nodeType == 'Master') ? -1 : 1;
      } else {
        return -1;
      }
    });

    // First, build location maps for every node devices
    String masterDeviceID = '';
    for (final device in devices) {
      if (device.isAuthority || device.nodeType == 'Master') {
        masterDeviceID = device.deviceID;
        locationMap[masterDeviceID] = _getDeviceLocation(device);
      } else if (device.nodeType == 'Slave') {
        locationMap[device.deviceID] = _getDeviceLocation(device);
      } else {
        // Make sure the connected device is online
        if (device.connections.isNotEmpty) {
          // There usually be at most one connection item
          final parentDeviceID = device.connections.firstOrNull?.parentDeviceID;
          // If the connected device's PID is null, count it under the Master
          // Otherwise, check if PID is the current node
          if ((parentDeviceID == null && targetID == masterDeviceID) || (parentDeviceID == targetID)) {
            connectedDevices.add(device);
          }
        }
      }
    }

    for (final device in devices) {
      if (device.deviceID == targetID) {
        location = locationMap[targetID] ?? '';
        isMaster = (targetID == masterDeviceID);
        isOnline = device.connections.isNotEmpty;
        upstreamNode =
            isMaster ? 'INTERNET' : _getUpstreamOfSlave(device, masterDeviceID);
        isWired = _checkIfWiredConnection(device);
        serialNumber = device.unit.serialNumber ?? '';
        modelNumber = device.model.modelNumber ?? '';
        firmwareVersion = device.unit.firmwareVersion ?? '';
        lanIpAddress = device.connections.firstOrNull?.ipAddress ?? '';
      }
    }

    return state.copyWith(
      location: location,
      isMaster: isMaster,
      isOnline: isOnline,
      connectedDevices: connectedDevices,
      upstreamNode: upstreamNode,
      isWiredConnection: isWired,
      serialNumber: serialNumber,
      modelNumber: modelNumber,
      firmwareVersion: firmwareVersion,
      isLatestFw: isLatestFW,
      lanIpAddress: lanIpAddress,
      wanIpAddress: wanIpAddress,
    );
  }

  String _getUpstreamOfSlave(RouterDevice device, String masterID) {
    final slaveParentID = device.connections.firstOrNull?.parentDeviceID;
    final upstreamNodeLocation = locationMap[slaveParentID];
    final masterNodeLocation = locationMap[masterID];

    return upstreamNodeLocation ?? (masterNodeLocation ?? '');
  }

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
