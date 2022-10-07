import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/model/router/radio_info.dart';
import 'package:linksys_moab/repository/router/core_extension.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/repository/router/wireless_ap_extension.dart';

import 'event.dart';
import 'state.dart';

class SetupBloc extends Bloc<SetupEvent, SetupState> {
  SetupBloc({required RouterRepository routerRepository})
      : _routerRepository = routerRepository,
        super(const SetupState.init()) {
    on<ResumePointChanged>(_onResumePointChanged);
    on<SetWIFISSIDAndPassword>(_onSetWIFISSIDAndPassword);
    on<SetAccountInfo>(_onSetAccountInfo);
    on<SetAdminPasswordHint>(_onSetAdminPasswordHint);
    on<SaveRouterSettings>(_onSaveRouterSettings);
  }

  final RouterRepository _routerRepository;

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
      case SetupResumePoint.waiting:
        return emit(state.copyWith(resumePoint: SetupResumePoint.waiting));
      case SetupResumePoint.finish:
        return emit(state.copyWith(resumePoint: SetupResumePoint.finish));

      default:
        return emit(state.copyWith(resumePoint: SetupResumePoint.none));
    }
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
    // create admin password
    if (state.adminPassword.isNotEmpty) {
      await _routerRepository.createAdminPassword(
          state.adminPassword, state.passwordHint);
    }
    //
    final getRadioInfoResult = await _routerRepository.getRadioInfo();
    final newRadioSettingsList = List.from(getRadioInfoResult.output['radios'])
        .map((e) => RouterRadioInfo.fromJson(e))
        .map(
          (e) => NewRadioSettings(
            radioID: e.radioID,
            settings: e.settings.copyWith(
              ssid: state.wifiSSID,
              wpaPersonalSettings: RouterWPAPersonalSettings(
                passphrase: state.wifiPassword,
              ),
            ),
          ),
        )
        .toList();
    await _routerRepository.setRadioSettings(newRadioSettingsList);
    emit(state.copyWith(resumePoint: SetupResumePoint.waiting));
  }
}
