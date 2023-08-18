import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_app/bloc/node/state.dart';
import 'package:linksys_app/core/jnap/models/wan_status.dart';
import 'package:linksys_app/core/jnap/models/device.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/utils.dart';

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
    emit(state.copyWith(isLoading: true));
    final results = await _repository.fetchNodeDetails();

    String wanIpAddress = '';
    final getWANStatusOutput =
        JNAPTransactionSuccessWrap.getResult(JNAPAction.getWANStatus, results)
            ?.output;
    if (getWANStatusOutput != null) {
      final wanStatusModel = RouterWANStatus.fromJson(getWANStatusOutput);
      wanIpAddress = wanStatusModel.wanConnection?.ipAddress ?? '';
    }

    final getFirmwareUpdateStatusOutput = JNAPTransactionSuccessWrap.getResult(
            JNAPAction.getFirmwareUpdateStatus, results)
        ?.output;
    final isLatestFW =
        (getFirmwareUpdateStatusOutput?['availableUpdate']) == null;

    final getDevicesOutput =
        JNAPTransactionSuccessWrap.getResult(JNAPAction.getDevices, results)
            ?.output;
    var devices = List.from(getDevicesOutput?['devices'])
        .map((e) => RouterDevice.fromJson(e))
        .toList();

    emit(_getNodeDetailState(state.deviceID, wanIpAddress, isLatestFW, devices)
        .copyWith(isLoading: false));
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
        locationMap[masterDeviceID] = Utils.getDeviceLocation(device);
      } else if (device.nodeType == 'Slave') {
        locationMap[device.deviceID] = Utils.getDeviceLocation(device);
      } else {
        // Make sure the external device is online
        if (device.connections.isNotEmpty) {
          // There usually be at most one connection item
          final parentDeviceID = device.connections.firstOrNull?.parentDeviceID;
          // If the connected device's PID is null, count it under the Master
          // Otherwise, check if PID is the current node
          if ((parentDeviceID == null && targetID == masterDeviceID) ||
              (parentDeviceID == targetID)) {
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
        isWired = Utils.checkIfWiredConnection(device);
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
}
