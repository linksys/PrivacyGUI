import 'package:flutter/material.dart';
import 'package:moab_poc/route/route.dart';

class SetupRouteInformationParser extends RouteInformationParser<BasePath> {
  @override
  Future<BasePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    // print(
    //     'SetupRouteInformationParser::parseRouteInformation: ${routeInformation.location}');
    final uri = Uri.parse(routeInformation.location ?? '');

    // Handle '/'
    if (uri.pathSegments.isEmpty) {
      return HomePath();
    }

    return UnknownPath();
  }

  @override
  RouteInformation? restoreRouteInformation(BasePath configuration) {
    // print(
    //     'SetupRouteInformationParser::restoreRouteInformation: ${configuration.name}');
    return null;
  }
}
