import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/route/route.dart';

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
    emit(state.push(config));
    if (config is ReturnablePath) {
      return (config as ReturnablePath).waitForComplete();
    } else {
      return null;
    }
  }

  void push(BasePath config) {
    print('push called with $config and ${config.args}');
    // PageConfig config = PageConfig(location: path, args: args);
    emit(state.push(config));
  }

  void clear() {
    emit(state.clear());
  }

  void clearAndPush(BasePath config) {
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
    emit(state.pushBeneathCurrent(config));
  }
}