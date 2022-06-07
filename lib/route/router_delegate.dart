import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/analytics.dart';
import 'package:moab_poc/util/logger.dart';

class MoabRouterDelegate extends RouterDelegate<BasePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<BasePath> {
  MoabRouterDelegate() : navigatorKey = GlobalKey();

  final _stack = <BasePath>[];

  static MoabRouterDelegate of(BuildContext context) {
    final delegate = Router.of(context).routerDelegate;
    assert(delegate is MoabRouterDelegate, 'Delegate type must match');
    return delegate as MoabRouterDelegate;
  }

  @override
  BasePath get currentConfiguration {
    return _stack.isNotEmpty ? _stack.last : HomePath();
  }

  List<String> get stack => List.unmodifiable(_stack);
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    logger.d(
        'MoabRouterDelegate::${describeIdentity(this)}.stack: [${_stack.map((e) => e.name).join(',').toString()}]');
    if (_stack.isEmpty) {
      screenInfoLog(context); // TODO re-visit is there has more suitable place to log screen info
      _stack.add(HomePath());
    }
    return Navigator(
        key: navigatorKey,
        pages: [
          for (final path in _stack)
            MaterialPage(
              name: path.name,
              key: ValueKey(path.name),
              fullscreenDialog: path.pageConfig.isFullScreenDialog,
              child: Theme(
                  data: path.pageConfig.themeData, child: path.buildPage(this)),
            ),
        ],
        onPopPage: _onPopPage);
  }

  @override
  Future<void> setInitialRoutePath(BasePath configuration) {
    return setNewRoutePath(configuration);
  }

  @override
  Future<void> setNewRoutePath(BasePath configuration) async {
    print('MoabRouterDelegate::setNewRoutePath:${configuration.name}');
    _stack
      ..clear()
      ..add(configuration);
    return SynchronousFuture<void>(null);
  }

  Future<dynamic> push(BasePath path) async {
    _stack.removeWhere((element) => element.pathConfig.removeFromFactory);
    logger.d('Navigation Push:: ${path.name}');
    logEvent(eventName: "NavigationPush", parameters: {
      'currentPage': currentConfiguration.name,
      'nextPage': path.name,
    });
    _stack.add(path);
    notifyListeners();
    if (currentConfiguration is ReturnablePath) {
      return (currentConfiguration as ReturnablePath).waitForComplete();
    } else {
      return;
    }
  }

  void pop() {
    if (_stack.isNotEmpty) {
      _completePath(_stack.last, null);
      _stack.remove(_stack.last);
    }
    logger.d('Navigation Pop:: current:${currentConfiguration.name}');
    logEvent(eventName: "NavigationPop", parameters: {
      'currentPage': currentConfiguration.name,
    });
    notifyListeners();
  }

  void popTo(BasePath path) {
    if (_stack.isNotEmpty) {
      while (_stack.last.name != path.name) {
        _stack.removeLast();
      }
    }
    logEvent(eventName: "NavigationPopTo", parameters: {
      'currentPage': currentConfiguration.name,
      'nextPage': path.name,
    });
    notifyListeners();
  }

  void completeAndPop<T>(T? data) {
    _completePath(currentConfiguration, data);
    pop();
  }

  void _completePath<T>(BasePath path, T? data) {
    if (path is ReturnablePath) {
      final returnable = path as ReturnablePath;
      if (!returnable.isComplete()) {
        returnable.complete(data);
      }
    }
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    print('MoabRouterDelegate:: onPopPage: $result');
    if (_stack.isNotEmpty) {
      if (_stack.last.name == route.settings.name) {
        _completePath(_stack.last, null);
        _stack.removeWhere((element) => element.name == route.settings.name);
        notifyListeners();
      }
    }
    logger.d('Navigation Back:: current:${currentConfiguration.name}');
    logEvent(eventName: "NavigationBack", parameters: {
      'currentPage': currentConfiguration.name,
    });
    return route.didPop(result);
  }
}
