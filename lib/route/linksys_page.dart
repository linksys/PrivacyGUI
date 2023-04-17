import 'package:flutter/material.dart';

class LinksysPage<T> extends Page<T> {
  /// Creates a material page.
  const LinksysPage({
    required this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.opaque = true,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) : super(
            key: key,
            name: name,
            arguments: arguments,
            restorationId: restorationId);

  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  /// {@macro flutter.widgets.PageRoute.fullscreenDialog}
  final bool fullscreenDialog;

  final bool opaque;
  @override
  Route<T> createRoute(BuildContext context) {
    // https://github.com/flutter/flutter/issues/57202
    // Can't have custom transition for iOS, will lost swipe back gesture.
    if (opaque) {
      return _PageBasedLinksysPageRoute<T>(page: this);
    } else {
      return _PageBasedLinksysTransparentPageRoute<T>(page: this);
    }
  }
}

// A page-based version of MaterialPageRoute.
//
// This route uses the builder from the page to build its content. This ensures
// the content is up to date after page updates.
class _BaseLinksysPageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  _BaseLinksysPageRoute({
    required LinksysPage<T> page,
  }) : super(settings: page);
  LinksysPage<T> get _page => settings as LinksysPage<T>;

  @override
  Widget buildContent(BuildContext context) {
    return _page.child;
  }

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

class _PageBasedLinksysTransparentPageRoute<T> extends _BaseLinksysPageRoute<T> {
  _PageBasedLinksysTransparentPageRoute({
    required LinksysPage<T> page,
  }) : super(page: page);

  @override
  bool get opaque => false;
}

class _PageBasedLinksysPageRoute<T> extends _BaseLinksysPageRoute<T> {
  _PageBasedLinksysPageRoute({
    required LinksysPage<T> page,
  }) : super(page: page);

  @override
  bool get opaque => true;
}
