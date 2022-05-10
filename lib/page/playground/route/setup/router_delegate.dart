import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/page/playground/route/setup/path_model.dart';

class SetupRouterDelegate extends RouterDelegate<SetupRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<SetupRoutePath> {
  SetupRouterDelegate() : navigatorKey = GlobalKey();

  final _stack = <SetupRoutePath>[];

  static SetupRouterDelegate of(BuildContext context) {
    final delegate = Router.of(context).routerDelegate;
    assert(delegate is SetupRouterDelegate, 'Delegate type must match');
    return delegate as SetupRouterDelegate;
  }

  @override
  SetupRoutePath get currentConfiguration {
    print('Get currentConfiguration:: ${_stack.length}');
    return _stack.isNotEmpty ? _stack.last : SetupRoutePath.setupParent();
  }

  List<String> get stack => List.unmodifiable(_stack);
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    print(
        'SetupRouterDelegate::build:${describeIdentity(this)}.stack: [${_stack.map((e) => e.path).join(',').toString()}]');

    return Navigator(
        key: navigatorKey,
        pages: [
          for (final configuration in _stack)
            MaterialPage(
              name: configuration.path,
              key: ValueKey(configuration.path),
              child: _pageFactory(
                  context: context,
                  path: configuration.path,
                  title: configuration.path),
            ),
        ],
        onPopPage: _onPopPage);
  }

  @override
  Future<void> setInitialRoutePath(SetupRoutePath configuration) {
    return setNewRoutePath(configuration);
  }

  @override
  Future<void> setNewRoutePath(SetupRoutePath configuration) async {
    print('SetupRouterDelegate::setNewRoutePath:${configuration.path}');
    _stack
      ..clear()
      ..add(configuration);
    return SynchronousFuture<void>(null);
  }

  void push(SetupRoutePath newRoute) {
    _stack.add(newRoute);
    notifyListeners();
  }

  void pop() {
    if (_stack.isNotEmpty) {
      _stack.remove(_stack.last);
    }
    notifyListeners();
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    if (_stack.isNotEmpty) {
      if (_stack.last.path == route.settings.name) {
        _stack.removeWhere((element) => element.path == route.settings.name);
        notifyListeners();
      }
    }
    return route.didPop(result);
  }

  // Mock UI pages
  Widget _pageFactory(
      {required BuildContext context,
      required String path,
      required String title}) {
    switch (path) {
      case SetupRoutePath.setupParentPrefix:
        return _createPage(
            title: 'Setup Parent',
            callback: () {
              SetupRouterDelegate.of(context)
                  .push(SetupRoutePath.setupInternetCheck());
            });
      case SetupRoutePath.setupInternetCheckPrefix:
        return _createPage(
            title: 'Internet Check',
            callback: () {
              SetupRouterDelegate.of(context).push(SetupRoutePath.setupChild());
            });
      case SetupRoutePath.setupChildPrefix:
        return _createPage(title: 'Setup Child', callback: () {});
      default:
        return _createPage(title: 'Unknown Page', callback: () {});
    }
  }

  Widget _createPage({required String title, required VoidCallback callback}) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: callback,
          child: const Text('Next'),
        ),
      ),
    );
  }
}
