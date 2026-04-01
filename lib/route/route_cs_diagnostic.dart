part of 'router_provider.dart';

final csDiagnosticRoute = GoRoute(
  name: RouteNamed.csDiagnostic,
  path: RoutePath.csDiagnostic,
  builder: (context, state) => const DiagnosticEntryView(),
);
