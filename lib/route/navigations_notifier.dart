import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/core/utils/logger.dart';

Future<dynamic> showPopup({required WidgetRef ref, required BasePath config}) {
  return ref.read(navigationsProvider.notifier).pushAndWait(config);
}

final navigationsProvider =
    StateNotifierProvider<NavigationNotifier, List<BasePath>>(
        (ref) => NavigationNotifier());

class NavigationNotifier extends StateNotifier<List<BasePath>> {
  NavigationNotifier() : super([HomePath()]);

  int get length => state.length;

  BasePath get first => state.first;

  BasePath get last => state.last;

  void clear() {
    state = _cloned..removeRange(0, state.length - 2);
  }

  bool canPop() {
    return state.length > 1;
  }

  void pop() {
    if (canPop()) {
      _completePath(null);
      state = _cloned..remove(state.last);
    }
  }

  void popTo(BasePath config) {
    while (canPop() && state.last.name != config.name) {
      state = _cloned..remove(state.last);
    }
  }

  void popToOrPush(BasePath config) {
    logger.d(
        'NavigationNotifier: popToOrPush called with $config and arguments: ${config.args}, next: ${config.next}');

    if (state.any((element) => element.runtimeType == config.runtimeType)) {
      popTo(config);
    } else {
      push(config);
    }
  }

  void popToAndPush(BasePath popConfig, BasePath pushConfig, bool include) {
    logger.d(
        'NavigationNotifier: popToAndPush called pop to $popTo include self: $include, and push $push with arguments: ${pushConfig.args}, next: ${pushConfig.next}');

    if (state.any((element) => element.name == popConfig.name)) {
      popTo(popConfig);
      if (include) {
        pop();
      }
      push(pushConfig);
    } else {
      push(pushConfig);
    }
  }

  void pushBeneathCurrent(BasePath config) {
    logger.d(
        'NavigationNotifier: pushBeneathCurrent called with $config and arguments: ${config.args}, next: ${config.next}');

    state = _cloned..insert(state.length - 1, config);
  }

  void push(BasePath config) {
    logger.d(
        'NavigationNotifier: push called with $config and arguments: ${config.args}, next: ${config.next}');
    final state = _cloned;
    state.removeWhere((element) => element.pathConfig.removeFromHistory);
    if (state.isEmpty || state.last != config) state.add(config);
    this.state = state;
  }

  void replace(BasePath config) {
    logger.d(
        'NavigationNotifier: replace called with $config and arguments: ${config.args}, next: ${config.next}');

    if (canPop()) {
      state = _cloned..removeLast();
      push(config);
    } else {
      state = _cloned..insert(0, config);
      state = _cloned..removeLast();
    }
  }

  void clearAndPush(BasePath config) {
    logger.d(
        'NavigationNotifier: clearAndPush called with $config and arguments: ${config.args}, next: ${config.next}');

    state = _cloned..clear();
    state = _cloned..add(config);
  }

  void popWithResult<T>(T? data) {
    completeAndPop(data);
  }

  void clearAndPushAll(List<BasePath> configs) {
    state = _cloned..clear();
    state = _cloned..addAll(configs);
  }

  Future<dynamic> pushAndWait(BasePath config) async {
    logger.d(
        'NavigationNotifier: pushAndWait called with $config and arguments: ${config.args}, next: ${config.next}');
    push(config);
    if (config is ReturnablePath) {
      return (config as ReturnablePath).waitForComplete();
    } else {
      return null;
    }
  }

  void completeAndPop<T>(T? data) {
    _completePath(data);
    pop();
  }

  void _completePath<T>(T? data) {
    if (state.last is ReturnablePath) {
      final returnable = state.last as ReturnablePath;
      if (!returnable.isComplete()) {
        returnable.complete(data);
      }
    }
  }

  List<BasePath> get _cloned => List.from(state);
}
