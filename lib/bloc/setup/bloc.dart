import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/constants/jnap_const.dart';
import 'package:linksys_moab/model/router/device.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/repository/router/core_extension.dart';
import 'package:linksys_moab/repository/router/device_list_extension.dart';
import 'package:linksys_moab/repository/router/owend_network_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/repository/router/smart_mode_extension.dart';
import 'package:linksys_moab/repository/router/transactions_extension.dart';
import 'package:linksys_moab/repository/router/wireless_ap_extension.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'event.dart';
import 'state.dart';

class SetupBloc extends Bloc<SetupEvent, SetupState> {
  SetupBloc({required RouterRepository routerRepository})
      : _routerRepository = routerRepository,
        super(const SetupState.init()) {
    on<Init>(_onInit);
    on<ResumePointChanged>(_onResumePointChanged);
    on<SetWIFISSIDAndPassword>(_onSetWIFISSIDAndPassword);
    on<SetAccountInfo>(_onSetAccountInfo);
    on<SetAdminPasswordHint>(_onSetAdminPasswordHint);
    on<SaveRouterSettings>(_onSaveRouterSettings);
    on<FetchNetworkId>(_onFetchNetworkId);
    on<SetRouterLocation>(_onSetRouterLocation);
  }

  final RouterRepository _routerRepository;

  @override
  void onTransition(Transition<SetupEvent, SetupState> transition) {
    super.onTransition(transition);
    logger.d(transition);
  }

  // TODO #REFACTOR to revisit
  void _onResumePointChanged(
      ResumePointChanged event, Emitter<SetupState> emit) {
    switch (event.status) {
      case SetupResumePoint.none:
        return emit(state.copyWith(resumePoint: SetupResumePoint.none));
      case SetupResumePoint.internetCheck:
        return emit(
            state.copyWith(resumePoint: SetupResumePoint.internetCheck));
      case SetupResumePoint.setSSID:
        return emit(state.copyWith(resumePoint: SetupResumePoint.setSSID));
      case SetupResumePoint.addChildNode:
        return emit(state.copyWith(resumePoint: SetupResumePoint.addChildNode));
      case SetupResumePoint.routerPassword:
        return emit(
            state.copyWith(resumePoint: SetupResumePoint.routerPassword));
      case SetupResumePoint.createCloudAccount:
        return emit(
            state.copyWith(resumePoint: SetupResumePoint.createCloudAccount));
      case SetupResumePoint.location:
        return emit(state.copyWith(resumePoint: SetupResumePoint.location));
      case SetupResumePoint.wifiInterrupted:
        return emit(
            state.copyWith(resumePoint: SetupResumePoint.wifiInterrupted));
      case SetupResumePoint.wifiConnectionBackSuccess:
        return emit(state.copyWith(
            resumePoint: SetupResumePoint.wifiConnectionBackSuccess));
      case SetupResumePoint.wifiConnectionBackFailed:
        return emit(state.copyWith(
            resumePoint: SetupResumePoint.wifiConnectionBackFailed));
      case SetupResumePoint.finish:
        return emit(state.copyWith(resumePoint: SetupResumePoint.finish));

      default:
        return emit(state.copyWith(resumePoint: SetupResumePoint.none));
    }
  }

  void _onInit(Init event, Emitter<SetupState> emit){
    return emit(SetupState.init());
  }
  void _onSetWIFISSIDAndPassword(
      SetWIFISSIDAndPassword event, Emitter<SetupState> emit) {
    return emit(
        state.copyWith(wifiSSID: event.ssid, wifiPassword: event.password));
  }

  void _onSetAccountInfo(SetAccountInfo event, Emitter<SetupState> emit) {
    return emit(state.copyWith(accountInfo: event.accountInfo));
  }

  void _onSetAdminPasswordHint(
      SetAdminPasswordHint event, Emitter<SetupState> emit) {
    return emit(state.copyWith(
        adminPassword: event.password, passwordHint: event.hint));
  }

  void _onSaveRouterSettings(
      SaveRouterSettings event, Emitter<SetupState> emit) async {
    final getRadioInfoResult = await _routerRepository.getRadioInfo();
    final devices = await _routerRepository.getDevices().then((result) =>
        List.from(result.output['devices'])
            .map((e) => Device.fromJson(e))
            .toList());
    final simpleWiFiSettingsList =
        List.from(getRadioInfoResult.output['radios'])
            .map((e) => RouterRadioInfo.fromJson(e))
            .map((e) => SimpleWiFiSettings.fromRadioInfo(e).copyWith(
                  ssid: state.wifiSSID,
                  passphrase: state.wifiPassword,
                ))
            .toList();
    // the devices should at least has 1 device
    if (devices.isNotEmpty) {
      await _routerRepository
          .setDeviceProperties(deviceId: devices[0].deviceID, propertiesToModify: [
        {
          'name': userDefinedDeviceLocation,
          'value': state.deviceLocation,
        }
      ]);
    }
    // TODO #1 Don't wait for now since there won't have response MOABLITE-38 - https://linksys.atlassian.net/browse/MOABLITE-38
    _routerRepository.configureRouter(
      adminPassword: state.adminPassword,
      passwordHint: state.passwordHint,
      settings: simpleWiFiSettingsList,
    );
    // TODO #1 to wait the transaction done since current transaction won't get response back
    await Future.delayed(Duration(seconds: 30));
    emit(state.copyWith(resumePoint: SetupResumePoint.wifiInterrupted));
  }

  void _onFetchNetworkId(FetchNetworkId event, Emitter<SetupState> emit) async {
    final result = await _routerRepository.getOwnedNetworkID();
    final networkId = result.output['ownedNetworkID'];
    await SharedPreferences.getInstance().then((pref) async =>
        await pref.setString(moabPrefSelectedNetworkId, networkId));
    return emit(state.copyWith(
        resumePoint: SetupResumePoint.finish, networkId: networkId));
  }

  void _onSetRouterLocation(
      SetRouterLocation event, Emitter<SetupState> emit) async {
    emit(state.copyWith(deviceLocation: event.location));
  }

  Future<void> associateNetwork(String accountId, String groupId) async {
    await _routerRepository.setCloudIds(accountId, groupId);
  }
}
