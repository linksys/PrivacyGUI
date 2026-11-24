import 'package:collection/collection.dart';

part 'jnap_action.dart';

part 'jnap_service.dart';

/// What every action URL starts with. JNAPAction declares the rest.
const _jnap = 'http://linksys.com/jnap/';

// The better action map
var _betterActionMap = <JNAPAction, String>{};

// Update actions to better actions by the given service: each action that
// [service] defines at a newer version takes that version's URL.
void _updateBetterActions(JNAPService service) {
  for (final action in JNAPAction.values) {
    final path = action._upgrades[service];
    if (path != null) {
      _betterActionMap[action] = '$_jnap$path';
    }
  }
}

// Set an initial value (lowest version) to each JNAP action
void initBetterActions() {
  // Start from scratch: an action that only a service defines must not keep
  // the URL the last router gave it (#1923).
  _betterActionMap.clear();
  for (final action in JNAPAction.values) {
    final path = action._path;
    if (path != null) {
      _betterActionMap[action] = '$_jnap$path';
    }
  }
}

void buildBetterActions(List<String> routerServices) {
  initBetterActions();
  final List<JNAPService> supportedServices = routerServices
      .where((routerService) => JNAPService.appSupportedServices
          .any((supportedService) => routerService == supportedService.value))
      .map((service) => JNAPService.appSupportedServices
          .firstWhere((supportedService) => supportedService.value == service))
      .toList();
  final serviceMap = groupAndSortJNAPServices(supportedServices);
  final sortedServiceList =
      serviceMap.values.reduce((all, value) => all..addAll(value));
  for (final service in sortedServiceList) {
    _updateBetterActions(service);
  }
}

Map<String, List<JNAPService>> groupAndSortJNAPServices(
    List<JNAPService> services) {
  final groupedServices = groupBy<JNAPService, String>(services, (service) {
    final name = service.name;
    final match = RegExp(r'(\d+)').firstMatch(name);
    if (match != null) {
      return name.substring(0, name.indexOf(match.group(0)!));
    }
    return name;
  });

  final sortedGroupedServices = <String, List<JNAPService>>{};

  groupedServices.forEach((key, value) {
    sortedGroupedServices[key] = value.sorted((a, b) {
      final aMatch = RegExp(r'(\d+)').firstMatch(a.name);
      final bMatch = RegExp(r'(\d+)').firstMatch(b.name);

      if (aMatch != null && bMatch != null) {
        return int.parse(aMatch.group(1)!)
            .compareTo(int.parse(bMatch.group(1)!));
      } else if (aMatch != null) {
        return 1;
      } else if (bMatch != null) {
        return -1;
      } else {
        return a.name.compareTo(b.name);
      }
    }).toList();
  });

  return sortedGroupedServices;
}
