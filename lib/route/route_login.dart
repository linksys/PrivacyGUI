part of 'router_provider.dart';

final loginRoute = GoRoute(
  name: 'cloudLoginAccount',
  path: 'cloudLogin',
  builder: (context, state) => const CloudLoginAccountView(),
  routes: [
    GoRoute(
      name: 'cloudLoginPassword',
      path: 'cloudLoginPassword',
      builder: (context, state) => CloudLoginPasswordView(
        args: state.uri.queryParametersAll,
      ),
    ),
  ],
);
