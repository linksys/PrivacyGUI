import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/utils/logger.dart';

final routerLoggerProvider = Provider((ref) {
  return RouterLogger(ref);
});

class RouterLogger extends NavigatorObserver {
  final Ref _ref;
  RouterLogger(Ref ref) : _ref = ref;

  /// The [Navigator] pushed `route`.
  ///
  /// The route immediately below that one, and thus the previously active
  /// route, is `previousRoute`.
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logger.d('did push the page - ${route.settings.name}');
  }

  /// The [Navigator] popped `route`.
  ///
  /// The route immediately below that one, and thus the newly active
  /// route, is `previousRoute`.
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logger.d('did pop the page - $route');
  }

  /// The [Navigator] removed `route`.
  ///
  /// If only one route is being removed, then the route immediately below
  /// that one, if any, is `previousRoute`.
  ///
  /// If multiple routes are being removed, then the route below the
  /// bottommost route being removed, if any, is `previousRoute`, and this
  /// method will be called once for each removed route, from the topmost route
  /// to the bottommost route.
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    logger.d('did remove the page - $route');
  }

  /// The [Navigator] replaced `oldRoute` with `newRoute`.
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    logger.d('did replace the page - $newRoute');
  }
}
