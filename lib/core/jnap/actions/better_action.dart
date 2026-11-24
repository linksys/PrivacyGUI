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
  final reported = routerServices.toSet();
  // JNAPService lists each family of services from its lowest version up,
  // and no action takes a URL from two families, so applying a router's
  // services in that order lets the newest version win (#1923).
  for (final service in JNAPService.values) {
    if (reported.contains(service.value)) {
      _updateBetterActions(service);
    }
  }
}
