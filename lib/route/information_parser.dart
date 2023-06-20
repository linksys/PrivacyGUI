import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/core/utils/logger.dart';

class LinksysRouteInformationParser
    extends RouteInformationParser<List<BasePath>> {
  @override
  Future<List<BasePath>> parseRouteInformation(
      RouteInformation routeInformation) async {
    logger.d(
        'SetupRouteInformationParser::parseRouteInformation: ${routeInformation.location}');
    final uri = Uri.parse(routeInformation.location ?? '');

    // Handle '/'
    if (uri.pathSegments.isEmpty) {
      return SynchronousFuture([HomePath()]);
    }

    return SynchronousFuture([UnknownPath()]);
  }

  @override
  RouteInformation? restoreRouteInformation(List<BasePath> configuration) {
    // print(
    //     'SetupRouteInformationParser::restoreRouteInformation: ${configuration.name}');
    return null;
  }
}
