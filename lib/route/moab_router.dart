import 'package:flutter/widgets.dart';
import 'package:moab_poc/route/path_model.dart';
import 'package:moab_poc/route/router_delegate.dart';

class MoabRouter {
  static Future<dynamic> push(BuildContext context, BasePath path) {
    return MoabRouterDelegate.of(context).push(path);
  }

  static void pop(BuildContext context) {
    MoabRouterDelegate.of(context).pop();
  }

  static void popTo(BuildContext context, BasePath path) {
    MoabRouterDelegate.of(context).popTo(path);
  }

  static void returnResult<T>(BuildContext context, T? data) {
    MoabRouterDelegate.of(context).completeAndPop(data);
  }
}

Future<T?> showPopup<T>({
  required BuildContext context,
  required BasePath path,
}) async {
  assert(path.pageConfig.isFullScreenDialog);
  return await MoabRouterDelegate.of(context).push(path);
}
