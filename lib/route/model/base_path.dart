import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/page/landing/view/view.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/logger.dart';

enum PageNavigationType { back, close, none }


class PathConfig {
  bool removeFromHistory = false;
}

class PageConfig {
  PageNavigationType navType = PageNavigationType.back;
  ThemeData themeData = MoabTheme.mainLightModeData;
  bool isFullScreenDialog = false;
  bool ignoreAuthChanged = false;
  bool ignoreConnectivityChanged = false;
  bool isOpaque = true;
  bool isBackDisable = false;
}

mixin ReturnablePath<T> {
  final Completer<T?> _completer = Completer();

  void complete(T? data) {
    logger.d("${describeIdentity(this)} complete with data $data");
    _completer.complete(data);
  }

  bool isComplete() => _completer.isCompleted;

  Future<T?> waitForComplete() {
    logger.d("${describeIdentity(this)} is waiting for complete...");
    return _completer.future;
  }
}

/// BasePath is the top level path class for providing to get a generic name
/// and some interfaces -
/// BasePath.buildPage() this better to implement on the sub abstract path,
/// this is because we can easy to understand the whole route in the setup.
abstract class BasePath<P> {
  Map<String, dynamic>? args;

  String get name => P.toString();

  PathConfig get pathConfig => PathConfig();

  PageConfig get pageConfig => PageConfig();

  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case HomePath:
        return HomeView(args: args,);
      case UnknownPath:
        return const Center(
          child: Text("Unknown Path"),
        );
      default:
        return const Center();
    }
  }
}

class HomePath extends BasePath<HomePath> {}

class UnknownPath extends BasePath<UnknownPath> {}

abstract class DebugToolsPath<P> extends BasePath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case DebugToolsMainPath:
        return const DebugToolsView();
      default:
        return const Center();
    }
  }
}

class DebugToolsMainPath extends DebugToolsPath<DebugToolsMainPath> {}