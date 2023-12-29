import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LayoutHelper {
  static bool canShowSub(BuildContext context) {
    final goRouter = GoRouter.maybeOf(context);
    return false;
  }
}
