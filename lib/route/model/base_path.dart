import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/design/themes.dart';
import 'package:linksys_moab/page/components/picker/simple_item_picker.dart';
import 'package:linksys_moab/page/landing/view/_view.dart';

import 'package:linksys_moab/util/logger.dart';

enum PageNavigationType { back, close, none }

class PathConfig {
  bool removeFromHistory = false;
  BasePath? next;
}

class PageConfig {
  PageNavigationType navType = PageNavigationType.back;
  ThemeData themeData = MoabTheme.mainLightModeData;
  bool isFullScreenDialog = false;
  bool ignoreAuthChanged = false;
  bool ignoreConnectivityChanged = false;
  bool isOpaque = true;
  bool isBackDisable = false;
  bool isHideBottomNavBar = true;
  bool isBackAvailable = true;
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
abstract class BasePath extends Equatable {
  Map<String, dynamic> args = {};
  final PathConfig _pathConfig = PathConfig();
  final PageConfig _pageConfig = PageConfig();

  String get name => runtimeType.toString();

  PathConfig get pathConfig => _pathConfig;

  PageConfig get pageConfig => _pageConfig;

  Widget buildPage() {
    switch (runtimeType) {
      case HomePath:
        return HomeView(
          args: args,
        );
      case SimpleItemPickerPath:
        return SimpleItemPickerView(
          next: next,
          args: args,
        );
      case UnknownPath:
        return const Center(
          child: Text("Unknown Path"),
        );
      default:
        return const Center();
    }
  }

  BasePath? get next => pathConfig.next;

  set next(BasePath? next) {
    pathConfig.next = next;
    logger.d('set next: ${this.next} to $runtimeType');
  }

  @override
  List<Object?> get props => [
        name,
        next,
        args,
      ];
}

class HomePath extends BasePath {}

class UnknownPath extends BasePath {}

class SimpleItemPickerPath extends BasePath with ReturnablePath {}

class LoadingTransitionPath extends BasePath {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;

  @override
  PageConfig get pageConfig =>
      super.pageConfig..navType = PageNavigationType.none;
}

abstract class DebugToolsPath extends BasePath {
  @override
  Widget buildPage() {
    switch (runtimeType) {
      case DebugToolsMainPath:
        return const DebugToolsView();
      default:
        return const Center();
    }
  }
}

class DebugToolsMainPath extends DebugToolsPath {}
