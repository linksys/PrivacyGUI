import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/unconfigured_node.dart';
import 'package:linksys_moab/network/jnap/better_action.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/commands/_commands.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';

import 'state.dart';

class AddNodesCubit extends Cubit<AddNodesState> {
  AddNodesCubit({required RouterRepository routerRepository})
      : _repository = routerRepository,
        super(AddNodesState.init());

  final RouterRepository _repository;
  StreamSubscription? _findingNodesSubscription;
  StreamSubscription? _addingNodesSubscription;
  StreamSubscription? _checkDevicesSubscription;

  init() {
    emit(AddNodesState.init());
  }

  finish() {
    _findingNodesSubscription?.cancel();
    _addingNodesSubscription?.cancel();
    _checkDevicesSubscription?.cancel();
  }

  setMode(AddNodesMode mode) {
    emit(state.copyWith(mode: mode));
  }

  Future fetchDevices() async {
    final devices = await _repository.getDevices().then(
          (result) => List.from(result.output['devices'])
              .map((e) => RouterDevice.fromJson(e))
              .toList(),
        );
    final master = devices.firstWhere(
        (device) => device.nodeType == 'Master' || device.isAuthority);
    final slaves = devices.where((device) => device.nodeType == 'Slave');

    emit(
      state.copyWith(
        properties: [
          _deviceToProperties(master),
          ...slaves.map((slave) => _deviceToProperties(slave)),
        ],
      ),
    );
  }

  updateNodeLocation(String deviceId, String newLocation) {
    final property = state.properties
        .firstWhereOrNull((element) => element.deviceId == deviceId);
    if (property != null) {
      final newProperty = property.copyWith(
        location: newLocation,
        isModify: property.location != newLocation,
      );
      final index = state.properties.indexOf(property);
      emit(
        state.copyWith(
          properties: List.from(state.properties)
            ..replaceRange(
              index,
              index + 1,
              [newProperty],
            ),
        ),
      );
    }
  }

  save() async {
    // TODO #LINKSYS
    // return _repository
    //     .configureDeviceProperties(deviceProperties: state.properties)
    //     .then<void>((_) {})
    //     .onError((error, stackTrace) => onError(error!, stackTrace));
  }

  NodeProperties _deviceToProperties(RouterDevice device) {
    final origin = state.properties
        .firstWhereOrNull((element) => element.deviceId == device.deviceID);
    final wasModified =
        (origin?.isModify ?? false) && (origin?.location != null);
    final isNew = state.foundNodes
        .any((element) => device.hasSameInterface(element.macAddress));
    final macAddress = state.foundNodes.firstWhereOrNull(
        (element) => device.hasSameInterface(element.macAddress))?.macAddress;
    final newName = device.friendlyName ??
        '${device.nodeType == 'Master' ? 'Router' : 'Addons'}${macAddress == null ? '' : '-$macAddress'}';
    logger.d(
        'build device properties: origin one: $origin, was modified: $wasModified');
    return NodeProperties(
      deviceId: device.deviceID,
      location: isNew
          ? newName
          : wasModified
              ? origin?.location
              : device.properties
                      .firstWhereOrNull(
                          (e) => e.name == userDefinedDeviceLocation)
                      ?.value ??
                  device.friendlyName ??
                  'Node',
      isMaster: device.nodeType == 'Master',
      isModify: false,
    );
  }

  findingNodes() async {
    emit(state.copyWith(status: AddNodesStatus.findingNodes));
    await _repository.btRequestScanUnconfigured(duration: 20);

    _findingNodesSubscription?.cancel();
    _findingNodesSubscription = _repository
        .scheduledCommand(
            retryDelayInSec: 2,
            maxRetry: 15,
            action: JNAPAction.btGetScanUnconfiguredResult,
            condition: () => state.status != AddNodesStatus.findingNodes)
        .listen(_checkFindingNodesFinish, onDone: () {
      _findingNodesSubscription?.cancel();
    });
  }

  addingNodes() async {
    await _repository.startBlueboothAutoOnboarding();
    bool done = false;
    _addingNodesSubscription?.cancel();
    _addingNodesSubscription = _repository
        .scheduledCommand(
            retryDelayInSec: 10,
            maxRetry: 30,
            action: JNAPAction.getBlueboothAutoOnboardingStatus,
            condition: () => done)
        .listen(
      (event) {
        _checkAddingNodesFinish(event).then((value) => done = value);
      },
      onDone: () {
        _addingNodesSubscription?.cancel();
        _checkAllNodesAdded();
      },
    );
  }

  _checkFindingNodesFinish(JNAPResult result) async {
    logger.d('_checkFindingNodesFinish - $result');
    if (result is JNAPSuccess) {
      final isRunning = result.output['isRunning'] as bool? ?? true;
      final discovery = result.output['discovery'];
      if (isRunning) {
        logger.d('_checkFindingNodesFinish:: running: $isRunning');
        return;
      }
      if (discovery == null) {
        logger.d('_checkFindingNodesFinish:: No discovery data');
        return;
      }

      // Threshold 85, only accept the rssi below 85
      final list = List.from(discovery)
          .map((e) => BTDiscoveryData.fromJson(e))
          .where((data) => data.rssi < 85)
          .toList();
      logger.d('_checkFindingNodesFinish:: discovered data: $list');
      if (list.isEmpty) {
        emit(state.copyWith(status: AddNodesStatus.noNodesFound));
        return;
      }
      emit(
        state.copyWith(status: AddNodesStatus.addingNodes, foundNodes: list),
      );
    }
  }

  Future<bool> _checkAddingNodesFinish(JNAPResult result) async {
    if (result is JNAPSuccess) {
      final status = result.output['autoOnboardingStatus'];
      if (status == 'Running') {
        return false;
      }
      return true;
    } else {
      return false;
    }
  }

  _checkAllNodesAdded() {
    bool allDone = false;
    _checkDevicesSubscription?.cancel();
    _checkDevicesSubscription = _repository
        .scheduledCommand(
            retryDelayInSec: 10,
            maxRetry: 60,
            action: JNAPAction.getDevices,
            condition: () => allDone)
        .listen((event) {
      if (event is JNAPSuccess) {
        final routerDevices = List.from(event.output['devices'])
            .map((e) => RouterDevice.fromJson(e))
            .toList();
        final slaves =
            routerDevices.where((element) => element.nodeType == 'Slave');
        allDone = state.foundNodes.fold(
          true,
          (previousValue, found) =>
              previousValue &
              slaves.any(
                (slave) =>
                    slave.hasSameInterface(found.macAddress) &&
                    slave.hasConnection(found.macAddress),
              ),
        );
        logger.d('_checkAllNodesAdded: $allDone');
      }
    }, onDone: () {
      _checkDevicesSubscription?.cancel();
      emit(state.copyWith(
          status: allDone ? AddNodesStatus.allDone : AddNodesStatus.someDone));
    });
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    if (error is JNAPError) {
      // handle error
      emit(state.copyWith(error: error.error));
    }
  }

  @override
  void onChange(Change<AddNodesState> change) {
    super.onChange(change);
    if (!kReleaseMode) {
      logger.d(change);
    }
  }
}
