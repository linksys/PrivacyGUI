import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/util/logger.dart';

class MoabRouteInformationParser extends RouteInformationParser<BasePath> {
  @override
  Future<BasePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    logger.d(
        'SetupRouteInformationParser::parseRouteInformation: ${routeInformation.location}');
    final uri = Uri.parse(routeInformation.location ?? '');

    // Handle '/'
    if (uri.pathSegments.isEmpty) {
      return SynchronousFuture(HomePath());
    }

    return SynchronousFuture(UnknownPath());
  }

  @override
  RouteInformation? restoreRouteInformation(BasePath configuration) {
    // print(
    //     'SetupRouteInformationParser::restoreRouteInformation: ${configuration.name}');
    return null;
  }
}
