import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_route_entry_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/services/static_routing_service.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';

final staticRoutingProvider =
    NotifierProvider<StaticRoutingNotifier, StaticRoutingState>(
  () => StaticRoutingNotifier(),
);

final preservableStaticRoutingProvider = Provider<PreservableContract>(
  (ref) => ref.watch(staticRoutingProvider.notifier),
);

/// Notifier for managing static routing settings state
///
/// This notifier handles all static routing operations including fetching settings
/// from the device, managing route list edits, and persisting changes back to the device.
///
/// It uses the [StaticRoutingService] to handle JNAP communication and data transformation,
/// maintaining a clean separation between the presentation layer (Provider) and the data layer (JNAP).
///
/// Implements [PreservableNotifierMixin] to provide dirty guard functionality - tracking
/// original vs current state to detect unsaved changes and enable undo/revert operations.
class StaticRoutingNotifier extends Notifier<StaticRoutingState>
    with
        PreservableNotifierMixin<StaticRoutingSettings, StaticRoutingStatus,
            StaticRoutingState> {
  @override
  StaticRoutingState build() => StaticRoutingState.empty();

  /// Fetch routing settings from device
  ///
  /// Retrieves current routing configuration and network context from the device
  /// via the [StaticRoutingService]. Combines routing settings (NAT, dynamic routing, routes)
  /// with network context (device IP, subnet mask, max route limit).
  ///
  /// Implementation details:
  /// - Calls [StaticRoutingService.fetchRoutingSettings] to handle JNAP communication
  /// - Service already transforms JNAP models to UI models
  /// - Returns (null, null) tuple on fetch failure (handled gracefully by service)
  ///
  /// Parameters:
  /// - [forceRemote]: If true, forces fetch from cloud; otherwise uses local cache
  /// - [updateStatusOnly]: Currently unused, provided by mixin interface
  ///
  /// Returns: Tuple of (StaticRoutingSettings, StaticRoutingStatus) on success
  @override
  Future<(StaticRoutingSettings?, StaticRoutingStatus?)> performFetch(
      {bool forceRemote = false, bool updateStatusOnly = false}) async {
    final service = ref.read(staticRoutingServiceProvider);
    final (uiSettings, status) = await service.fetchRoutingSettings(
      forceRemote: forceRemote,
    );

    if (uiSettings == null || status == null) {
      return (null, null);
    }

    // Service already provides UI models, use them directly
    final settings = StaticRoutingSettings(
      isNATEnabled: uiSettings.isNATEnabled,
      isDynamicRoutingEnabled: uiSettings.isDynamicRoutingEnabled,
      entries: uiSettings.entries,
    );

    return (settings, status);
  }

  /// Switch routing network mode
  ///
  /// Toggles between NAT and Dynamic Routing modes. Only one mode can be
  /// active at a time:
  /// - [RoutingSettingNetwork.nat]: Enables NAT, disables dynamic routing
  /// - [RoutingSettingNetwork.dynamicRouting]: Enables dynamic routing, disables NAT
  ///
  /// Marks the state as modified (dirty) for the dirty guard mechanism,
  /// ensuring the UI can prompt for unsaved changes if needed.
  ///
  /// Parameters:
  /// - [option]: The [RoutingSettingNetwork] mode to enable
  void updateSettingNetwork(RoutingSettingNetwork option) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(
          isNATEnabled: option == RoutingSettingNetwork.nat,
          isDynamicRoutingEnabled:
              option == RoutingSettingNetwork.dynamicRouting,
        ),
      ),
    );
  }

  /// Save routing settings to device
  ///
  /// Persists the current routing configuration back to the device via [StaticRoutingService].
  /// State entries are already UI models, so we use them directly for transmission.
  ///
  /// The method:
  /// - Creates StaticRoutingUISettings from current state
  /// - Calls [StaticRoutingService.saveRoutingSettings] to transmit to device
  /// - Marks state as saved after successful transmission (via mixin)
  /// - May throw on network errors or device rejection
  ///
  /// Throws: Exception if save fails (network error, device rejection, etc.)
  @override
  Future<void> performSave() async {
    final service = ref.read(staticRoutingServiceProvider);

    // State entries are already UI models, use them directly
    final uiSettings = StaticRoutingUISettings(
      isNATEnabled: state.settings.current.isNATEnabled,
      isDynamicRoutingEnabled: state.settings.current.isDynamicRoutingEnabled,
      entries: state.settings.current.entries,
    );

    await service.saveRoutingSettings(uiSettings);
  }

  /// Check if current route count exceeds device limit
  ///
  /// Compares the current number of routes against the device's reported maximum
  /// static route capacity.
  ///
  /// Returns: true if current route count equals max (limit reached), false otherwise
  bool isExceedMax() {
    return state.status.maxStaticRouteEntries ==
        state.settings.current.entries.length;
  }

  /// Add a new route to the current routing configuration
  ///
  /// Appends the given route entry to the list of static routes and marks
  /// the state as modified (dirty) for the dirty guard mechanism.
  ///
  /// Enforces the device's maximum route limit and validates:
  /// - Route name is not empty and ≤32 characters
  /// - Destination IP is not already in use (no duplicates)
  /// - Route name and destination fields pass validation
  ///
  /// Throws an exception if adding would exceed the device's capacity,
  /// if validation fails, or if destination is duplicate.
  ///
  /// Parameters:
  /// - [rule]: The [StaticRouteEntryUIModel] to add
  ///
  /// Throws: Exception if validation fails or max limit reached
  void addRule(StaticRouteEntryUIModel rule) {
    // Validate route name
    if (rule.name.isEmpty) {
      throw Exception('Route name cannot be empty');
    }
    if (rule.name.length > 32) {
      throw Exception('Route name must not exceed 32 characters');
    }

    // Check for duplicate destination
    final destinationExists = state.settings.current.entries.any(
      (entry) => entry.destinationIP == rule.destinationIP,
    );
    if (destinationExists) {
      throw Exception(
        'Route with destination ${rule.destinationIP} already exists',
      );
    }

    // Check max route limit
    if (state.settings.current.entries.length >=
        state.status.maxStaticRouteEntries) {
      throw Exception(
        'Cannot add route: maximum of ${state.status.maxStaticRouteEntries} routes allowed',
      );
    }

    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(
          entries: List.from(state.settings.current.entries)..add(rule),
        ),
      ),
    );
  }

  /// Edit an existing route in the current routing configuration
  ///
  /// Replaces the route at the specified index with the provided route entry
  /// and marks the state as modified (dirty) for the dirty guard mechanism.
  ///
  /// Parameters:
  /// - [index]: The zero-based index of the route to edit
  /// - [rule]: The updated [StaticRouteEntryUIModel] to replace at the index
  void editRule(int index, StaticRouteEntryUIModel rule) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(
          entries: List.from(state.settings.current.entries)
            ..replaceRange(index, index + 1, [rule]),
        ),
      ),
    );
  }

  /// Delete a route from the current routing configuration
  ///
  /// Removes the specified route entry from the list of static routes
  /// and marks the state as modified (dirty) for the dirty guard mechanism.
  ///
  /// Parameters:
  /// - [rule]: The [StaticRouteEntryUIModel] to remove (matched by object reference)
  void deleteRule(StaticRouteEntryUIModel rule) {
    state = state.copyWith(
      settings: state.settings.copyWith(
        current: state.settings.current.copyWith(
          entries: List.from(state.settings.current.entries)..remove(rule),
        ),
      ),
    );
  }

  /// Get validation errors for a potential new route
  ///
  /// Checks if a route can be added without violating constraints:
  /// - Route name is not empty and ≤32 characters
  /// - Destination is not already in use
  /// - Route limit has not been reached
  ///
  /// Returns: Map of validation errors. Empty map means validation passes.
  /// Keys are field names, values are user-friendly error messages.
  Map<String, String> getValidationErrors(StaticRouteEntryUIModel rule) {
    final errors = <String, String>{};

    // Check route name
    if (rule.name.isEmpty) {
      errors['name'] = 'Route name cannot be empty';
    } else if (rule.name.length > 32) {
      errors['name'] = 'Route name must not exceed 32 characters';
    }

    // Check for duplicate destination
    final destinationExists = state.settings.current.entries.any(
      (entry) => entry.destinationIP == rule.destinationIP,
    );
    if (destinationExists) {
      errors['destinationIP'] = 'Route with this destination already exists';
    }

    // Check max route limit
    if (state.settings.current.entries.length >=
        state.status.maxStaticRouteEntries) {
      errors['limit'] =
          'Maximum of ${state.status.maxStaticRouteEntries} routes allowed';
    }

    return errors;
  }
}
