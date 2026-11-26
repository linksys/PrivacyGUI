import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/router_provider.dart';

/// The app's route table (routerProvider), and what each of its routes
/// builds.
///
/// [build] calls a route's builder as go_router does when it shows the route,
/// with the URL go_router names it by and the `extra` a push hands it, and
/// returns the page widget without laying it out: what a route builds is the
/// page and the arguments it passes, not the page's own UI.
class AppRoutes {
  AppRoutes() : container = ProviderContainer() {
    router = container.read(routerProvider);
  }

  final ProviderContainer container;
  late final GoRouter router;

  void dispose() => container.dispose();

  /// The route named [name], wherever it sits in the table.
  GoRoute named(String name) {
    GoRoute? found;
    void walk(List<RouteBase> routes) {
      for (final route in routes) {
        if (route is GoRoute && route.name == name) found = route;
        walk(route.routes);
      }
    }

    walk(router.configuration.routes);
    return found ?? (throw StateError('no route named $name'));
  }

  /// What route [name] builds for a URL with [query], pushed with [extra].
  Future<Widget> build(
    WidgetTester tester,
    String name, {
    Object? extra,
    Map<String, String> query = const {},
  }) async {
    late BuildContext context;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: Builder(builder: (built) {
        context = built;
        return const SizedBox();
      }),
    ));
    final uri = Uri.parse(router.namedLocation(name, queryParameters: query));
    final state = GoRouterState(
      router.configuration,
      uri: uri,
      matchedLocation: uri.path,
      name: name,
      fullPath: uri.path,
      pathParameters: const {},
      extra: extra,
      pageKey: ValueKey(uri.toString()),
    );
    return named(name).builder!(context, state);
  }
}

/// The arguments a page built by a route was handed.
Map<String, dynamic> argsOf(Widget page) => switch (page) {
      ArgumentsBaseConsumerStatefulView(:final args) => args,
      ArgumentsBaseConsumerStatelessView(:final args) => args,
      _ => throw StateError('${page.runtimeType} takes no arguments'),
    };
