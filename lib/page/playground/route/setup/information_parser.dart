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
      return SetupRoutePath.home();
    }

    final sub = uri.pathSegments[0];
    print('SetupRouteInformationParser::parseRouteInformation:sub: $sub');
    switch (sub) {
      case SetupRoutePath.setupWelcomeEulaTag:
        return SetupRoutePath.welcome();
      case SetupRoutePath.setupParentTag:
        return SetupRoutePath.setupParent();
      case SetupRoutePath.setupParentWiredTag:
        return SetupRoutePath.setupParentWired();
      case SetupRoutePath.setupParentConnectToModemTag:
        return SetupRoutePath.setupConnectToModem();
      case SetupRoutePath.placeParentNodeTag:
        return SetupRoutePath.placeParentNode();
      case SetupRoutePath.setupParentPermissionPrimerTag:
        return SetupRoutePath.permissionPrimer();
      case SetupRoutePath.setupParentManualSSIDTag:
        return SetupRoutePath.setupManualParentSSID();
      case SetupRoutePath.setupNthChildTag:
        return SetupRoutePath.setupNthChild();
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
