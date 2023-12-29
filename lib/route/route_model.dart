import 'package:equatable/equatable.dart';
import 'package:go_router/go_router.dart';

class LinksysRouteConfig extends Equatable {
  const LinksysRouteConfig({
    this.onlyMainView = false,
    this.ignoreConnectivityEvent = false,
    this.ignoreCloudOfflineEvent = false,
  });
  final bool onlyMainView;
  final bool ignoreConnectivityEvent;
  final bool ignoreCloudOfflineEvent;

  @override
  List<Object?> get props => [
        onlyMainView,
        ignoreConnectivityEvent,
        ignoreCloudOfflineEvent,
      ];
}

class LinksysRoute extends GoRoute {
  final LinksysRouteConfig? config;
  LinksysRoute({
    required super.path,
    super.name,
    super.builder,
    super.pageBuilder,
    super.parentNavigatorKey,
    super.redirect,
    super.onExit,
    this.config,
    super.routes = const <RouteBase>[],
  });
}
