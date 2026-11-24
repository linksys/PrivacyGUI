import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/generated/subscriptions.g.dart' as generated;

/// Re-exports the auto-generated core SSE subscription list so that
/// non-service layers (e.g. orchestrators) don't import codegen directly.
const coreSubscriptions = generated.coreSubscriptions;

/// Core subscriptions whose path only exists on firmware with a capability.
///
/// `mac-filter-mode-valuechange` names an overlay leaf that firmware without
/// the MAC filter (#1635) does not serve. The router refuses that subscription,
/// and Remote Assistance counts a refused core subscription as a failure, so
/// every session there would end on the "partial" snackbar (#1755).
const _requiredCapability = {
  'mac-filter-mode-valuechange': DeviceCapability.wifiMacFilter,
};

/// The core subscriptions this router can serve: every row of
/// [coreSubscriptions] except those whose capability it lacks.
List<(String, String, String)> coreSubscriptionsFor(
        DeviceCapabilities capabilities) =>
    coreSubscriptions.where((row) {
      final needed = _requiredCapability[row.$1];
      return needed == null || capabilities.has(needed);
    }).toList();
