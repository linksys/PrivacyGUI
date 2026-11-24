import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';

/// Instant Test ships only in builds that ask for it
/// (`--dart-define=enable_instant_test=true`, the Instant AI lanes). Run this
/// file both ways: a default build must register no Instant Test route, and a
/// flagged build must register exactly one.
void main() {
  Iterable<LinksysRoute> instantTestRoutes() => menus
      .whereType<LinksysRoute>()
      .where((route) => route.name == RouteNamed.menuInstantTest);

  test('default build: no Instant Test route in the Menu routes', () {
    expect(BuildConfig.enableInstantTest, isFalse);
    expect(instantTestRoutes(), isEmpty);
  }, skip: BuildConfig.enableInstantTest ? 'default-build check' : false);

  test('enable_instant_test build: the Instant Test route is registered', () {
    expect(instantTestRoutes(), hasLength(1));
    expect(identical(instantTestRoutes().single, instantTestRoute), isTrue);
  },
      skip: BuildConfig.enableInstantTest
          ? false
          : 'run with --dart-define=enable_instant_test=true');

  test('the mock-data preview is off unless its own define is set', () {
    // force=local is the router-hosted mode of every firmware GUI, so it must
    // not be what registers the no-login /instant-prototype route.
    expect(BuildConfig.enableInstantTestPrototype, isFalse);
  }, skip: BuildConfig.enableInstantTestPrototype ? 'prototype build' : false);
}
