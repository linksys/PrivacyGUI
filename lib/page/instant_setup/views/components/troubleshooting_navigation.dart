import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Navigation inside the no-internet troubleshooting tree (#1511 P1).
///
/// Every page of the tree sits under `:caller` in the URL, and go_router asserts
/// on a named route whose path parameter is not supplied. Forwarding the current
/// parameters keeps the caller without any page knowing which caller it is.
extension TroubleshootingNavigation on BuildContext {
  /// [GoRouterHelper.goNamed] to another page of the tree, keeping the caller.
  void goWithinTroubleshooting(String name) =>
      goNamed(name, pathParameters: GoRouterState.of(this).pathParameters);

  /// [GoRouterHelper.pushNamed] to another page of the tree, keeping the caller.
  Future<T?> pushWithinTroubleshooting<T extends Object?>(String name) =>
      pushNamed<T>(name, pathParameters: GoRouterState.of(this).pathParameters);
}
