import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppLifecycleCubit extends Cubit<AppLifecycleState> {
  AppLifecycleCubit(): super(AppLifecycleState.inactive);

  void update(AppLifecycleState state) {
    emit(state);
  }

}