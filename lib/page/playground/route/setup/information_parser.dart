import 'package:flutter/material.dart';
import 'package:moab_poc/page/playground/route/setup/path_model.dart';

class SetupRouteInformationParser
    extends RouteInformationParser<SetupRoutePath> {
  @override
  Future<SetupRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    print(
        'SetupRouteInformationParser::parseRouteInformation: ${routeInformation.location}');
    final uri = Uri.parse(routeInformation.location ?? '');

    // Handle '/'
    if (uri.pathSegments.isEmpty) {
      return SetupRoutePath.setupParent();
    }
    if (uri.pathSegments[0] != 'setup') {
      return SetupRoutePath.unknown();
    }

    final sub = uri.pathSegments[1];
    print('SetupRouteInformationParser::parseRouteInformation:sub: $sub');
    switch (sub) {
      case SetupRoutePath.setupParentTag:
        return SetupRoutePath.setupParent();
      case SetupRoutePath.setupInternetCheckTag:
        return SetupRoutePath.setupInternetCheck();
      case SetupRoutePath.setupChildTag:
        return SetupRoutePath.setupChild();
      default:
        return SetupRoutePath.unknown();
    }
  }

  @override
  RouteInformation? restoreRouteInformation(SetupRoutePath configuration) {
    print(
        'SetupRouteInformationParser::restoreRouteInformation: ${configuration.path}');
    switch (configuration.path) {
      case SetupRoutePath.setupParentPrefix:
        return const RouteInformation(
            location: SetupRoutePath.setupParentPrefix);
      case SetupRoutePath.setupInternetCheckPrefix:
        return const RouteInformation(
            location: SetupRoutePath.setupInternetCheckPrefix);
      case SetupRoutePath.setupChildPrefix:
        return const RouteInformation(
            location: SetupRoutePath.setupChildPrefix);
      default:
        return null;
    }
  }
}
