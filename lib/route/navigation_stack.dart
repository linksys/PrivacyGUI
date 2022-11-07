import 'package:flutter/foundation.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/util/logger.dart';

class NavigationStack {
  final List<BasePath> _stack;

  NavigationStack(this._stack) {
    logger.d(
        'MoabRouterDelegate::${describeIdentity(this)}.stack: [${_stack.map((e) => e.name).join(',').toString()}]');
  }

  // List<Page> get pages => List.unmodifiable(_stack.map((e) => e.buildPage()));
  List<BasePath> get configs => _stack;

  int get length => _stack.length;

  BasePath get first => _stack.first;

  BasePath get last => _stack.last;

  ///the reason behind returning Navigation Stack instead of just being a void
  ///is to chain calls as we'll see in navigation_cubit.dart
  //not to go into how a cubit defines a state to be new with lists, I've just returned a new instance

  NavigationStack clear() {
    _stack.removeRange(0, _stack.length - 2);
    //pages list in navigator can't be empty, remember
    return NavigationStack(_stack);
  }

  bool canPop() {
    return _stack.length > 1;
  }

  NavigationStack pop() {
    if (canPop()) {
      _completePath(null);
      _stack.remove(_stack.last);
    }
    return NavigationStack(_stack);
  }

  NavigationStack popTo(BasePath config) {
    while (canPop() && _stack.last.name != config.name) {
      _stack.remove(_stack.last);
    }
    return NavigationStack(_stack);
  }

  NavigationStack popToOrPush(BasePath config) {
    if (_stack.any((element) => element.runtimeType == config.runtimeType)) {
      return popTo(config);
    } else {
      return push(config);
    }
  }

  NavigationStack popToAndPush(
      BasePath popConfig, BasePath pushConfig, bool include) {
    if (_stack.any((element) => element.name == popConfig.name)) {
      return include
          ? popTo(popConfig).pop().push(pushConfig)
          : popTo(popConfig).push(pushConfig);
    } else {
      return push(pushConfig);
    }
  }

  NavigationStack pushBeneathCurrent(BasePath config) {
    _stack.insert(_stack.length - 1, config);
    return NavigationStack(_stack);
  }

  NavigationStack push(BasePath config) {
    _stack.removeWhere((element) => element.pathConfig.removeFromHistory);
    if (_stack.isEmpty || _stack.last != config) _stack.add(config);

    return NavigationStack(_stack);
  }

  NavigationStack replace(BasePath config) {
    if (canPop()) {
      _stack.removeLast();
      push(config);
    } else {
      _stack.insert(0, config);
      _stack.removeLast();
    }
    return NavigationStack(_stack);
  }

  NavigationStack clearAndPush(BasePath config) {
    _stack.clear();
    _stack.add(config);
    return NavigationStack(_stack);
  }

  NavigationStack clearAndPushAll(List<BasePath> configs) {
    _stack.clear();
    _stack.addAll(configs);
    return NavigationStack(_stack);
  }

  NavigationStack completeAndPop<T>(T? data) {
    _completePath(data);
    return pop();
  }

  void _completePath<T>(T? data) {
    if (_stack.last is ReturnablePath) {
      final returnable = _stack.last as ReturnablePath;
      if (!returnable.isComplete()) {
        returnable.complete(data);
      }
    }
  }
}
