import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/util/logger.dart';

// TODO rename
Future<dynamic> showPopup({required BuildContext context, required BasePath config}) {
  return context.read<NavigationCubit>().pushAndWait(config);
}

class NavigationCubit extends Cubit<NavigationStack> {
  NavigationCubit(List<BasePath> initialPages) : super(NavigationStack(initialPages));

  static NavigationCubit of(BuildContext context) {
    return context.read<NavigationCubit>();
  }

  Future<dynamic> pushAndWait(BasePath config) async {
    logger.d('NavigationCubit: pushAndWait called with $config and arguments: ${config.args}, next: ${config.next}');
    emit(state.push(config));
    if (config is ReturnablePath) {
      return (config as ReturnablePath).waitForComplete();
    } else {
      return null;
    }
  }

  void push(BasePath config) {
    logger.d('NavigationCubit: push called with $config and arguments: ${config.args}, next: ${config.next}');
    // PageConfig config = PageConfig(location: path, args: args);
    emit(state.push(config));
  }

  void clear() {
    emit(state.clear());
  }

  void clearAndPush(BasePath config) {
    logger.d('NavigationCubit: clearAndPush called with $config and arguments: ${config.args}, next: ${config.next}');
    // PageConfig config = PageConfig(location: path, args: args);
    emit(state.clearAndPush(config));
  }

  void pop() {
    emit(state.pop());
  }

  void popTo(BasePath config) {
    emit(state.popTo(config));
  }

  void popWithResult<T>(T? data) {
    emit(state.completeAndPop(data));
  }

  bool canPop() {
    return state.canPop();
  }

  void pushBeneathCurrent(BasePath config) {
    logger.d('NavigationCubit: pushBeneathCurrent called with $config and arguments: ${config.args}, next: ${config.next}');
    emit(state.pushBeneathCurrent(config));
  }

  void replace(BasePath config) {
    logger.d('NavigationCubit: replace called with $config and arguments: ${config.args}, next: ${config.next}');
    emit(state.replace(config));
  }
}