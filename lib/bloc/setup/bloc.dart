import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/state.dart';

import 'event.dart';
import 'state.dart';

class SetupBloc extends Bloc<SetupEvent, SetupState> {
  SetupBloc() : super(SetupState.init()) {
    on<ResumePointChanged>(_onResumePointChanged);
    on<SetWIFISSIDAndPassword>(_onSetWIFISSIDAndPassword);
    on<SetAccountInfo>(_onSetAccountInfo);
  }

  void _onResumePointChanged(
      ResumePointChanged event, Emitter<SetupState> emit) {
    switch (event.status) {
      case SetupResumePoint.NONE:
        return emit(state.copyWith(resumePoint: SetupResumePoint.NONE));
      case SetupResumePoint.INTERNETCHECK:
        return emit(
            state.copyWith(resumePoint: SetupResumePoint.INTERNETCHECK));
      case SetupResumePoint.SETSSID:
        return emit(state.copyWith(resumePoint: SetupResumePoint.SETSSID));
      case SetupResumePoint.ADDCHILDNODE:
        return emit(state.copyWith(resumePoint: SetupResumePoint.ADDCHILDNODE));
      case SetupResumePoint.ROUTERPASSWORD:
        return emit(
            state.copyWith(resumePoint: SetupResumePoint.ROUTERPASSWORD));
      case SetupResumePoint.CREATECLOUDACCOUNT:
        return emit(
            state.copyWith(resumePoint: SetupResumePoint.CREATECLOUDACCOUNT));
      case SetupResumePoint.LOCATION:
        return emit(state.copyWith(resumePoint: SetupResumePoint.LOCATION));
      default:
        return emit(state.copyWith(resumePoint: SetupResumePoint.NONE));
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
}
