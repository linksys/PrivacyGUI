part of 'router_provider.dart';

final homeRoute = GoRoute(
  name: 'home',
  path: '/',
  builder: (context, state) => const HomeView(),
  routes: [
    loginRoute
    //setupRoute
  ],
);