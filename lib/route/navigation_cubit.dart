import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/route/route.dart';

Future<dynamic> showPopup({required BuildContext context, required BasePath config}) {
  return context.read<NavigationCubit>().pushAndWait(config);
}

class NavigationCubit extends Cubit<NavigationStack> {
  NavigationCubit(List<BasePath> initialPages) : super(NavigationStack(initialPages));

  Future<dynamic> pushAndWait(BasePath config) async {
    emit(state.push(config));
    if (config is ReturnablePath) {
      return (config as ReturnablePath).waitForComplete();
    } else {
      return null;
    }
  }

  void push(BasePath config) {
    // print('push called with $path and $args');
    // PageConfig config = PageConfig(location: path, args: args);
    emit(state.push(config));
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

extension NavigationCubitExts on NavigationCubit {
  static NavigationCubit _get(BuildContext context) {
    return context.read<NavigationCubit>();
  }
  static bool canPop(BuildContext context) {
    return _get(context).canPop();
  }

  static void pop(BuildContext context) {
    _get(context).pop();
  }

  static void popTo(BuildContext context, BasePath config) {
    return _get(context).popTo(config);
  }

  static void popWithResult<T> (BuildContext context, T? data) {
    return _get(context).popWithResult(data);
  }

  static void push(BuildContext context, BasePath config) {
    _get(context).push(config);
  }

  static void clearAndPush(BuildContext context, BasePath config) {
    _get(context).clearAndPush(config);
  }

  static Future<dynamic> pushAndWait(BuildContext context, BasePath config) {
    return _get(context).pushAndWait(config);
  }

  static pushBeneathCurrent(BuildContext context, BasePath config) {
    _get(context).pushBeneathCurrent(config);
  }
}