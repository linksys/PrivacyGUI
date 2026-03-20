import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/route/navigation_extra.dart';

extension NavigationExtension on BuildContext {
  void navigateBack({String? fallback}) {
    if (canPop()) {
      pop();
      return;
    }
    final extra = GoRouterState.of(this).extra;
    if (extra is NavigationExtra && extra.backDestination != null) {
      goNamed(extra.backDestination!);
      return;
    }
    if (fallback != null) {
      goNamed(fallback);
    }
  }
}
