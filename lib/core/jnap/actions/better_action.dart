part 'jnap_action.dart';

part 'jnap_service.dart';

/// What every action URL starts with. JNAPAction declares the rest.
const _jnap = 'http://linksys.com/jnap/';

// The better action map
var _betterActionMap = <JNAPAction, String>{};

/// The services of the router the action table was last built for, as its
/// GetDeviceInfo reports them. isServiceSupport answers from these too, so a
/// gate and the URL it guards never disagree (#1923).
Set<String> _routerServices = const {};

/// The services the action table was last built for: empty before any router
/// is known.
Set<String> get routerServices => _routerServices;

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
  _routerServices = const {};
  for (final action in JNAPAction.values) {
    final path = action._path;
    if (path != null) {
      _betterActionMap[action] = '$_jnap$path';
    }
  }
}

void buildBetterActions(List<String> routerServices) {
  initBetterActions();
  final reported = Set<String>.unmodifiable(routerServices);
  _routerServices = reported;
  // JNAPService lists each family of services from its lowest version up,
  // and no action takes a URL from two families, so applying a router's
  // services in that order lets the newest version win (#1923).
  for (final service in JNAPService.values) {
    if (reported.contains(service.value)) {
      _updateBetterActions(service);
    }
  }
}

/// Builds the action table again when the router reports other services than
/// the table was built for, as after a firmware update. Polling calls it with
/// each GetDeviceInfo it reads (#1923).
void refreshBetterActions(List<String> routerServices) {
  final reported = routerServices.toSet();
  if (reported.length == _routerServices.length &&
      reported.containsAll(_routerServices)) {
    return;
  }
  buildBetterActions(routerServices);
}
