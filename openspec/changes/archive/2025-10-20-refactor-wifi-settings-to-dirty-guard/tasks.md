## Phase 1: Consolidate Data Models
- [x] 1.1: Analyze `WiFiState` and split it into `WiFiListSettings` (containing `mainWiFi`, `guestWiFi`, `isSimpleMode`, `simpleModeWifi`) and `WiFiListStatus` (containing `canDisableMainWiFi`).
- [x] 1.2: Analyze `InstantPrivacyState` and split it into `InstantPrivacySettings` (containing `mode`, `denyMacAddresses`) and `InstantPrivacyStatus`.
- [x] 1.3: Create the composite settings model `WifiBundleSettings`, which will hold instances of `WiFiListSettings`, `WifiAdvancedSettingsState`, and `InstantPrivacySettings`.
- [x] 1.4: Create the composite status model `WifiBundleStatus`, which will hold instances of `WiFiListStatus` and `InstantPrivacyStatus`.
- [x] 1.5: Create the final `WifiBundleState` that extends `FeatureState<WifiBundleSettings, WifiBundleStatus>`.

## Phase 2: Implement Consolidated Notifier
- [x] 2.1: Create the new `WifiBundleNotifier` and its corresponding `wifiBundleProvider` and `preservableWifiSettingsProvider`.
- [x] 2.2: Implement the `performFetch` method in `WifiBundleNotifier`. This method will use `Future.wait` to run the data-fetching logic from the original three notifiers in parallel and combine their results into the new composite state models.
- [x] 2.3: Implement the `performSave` method. This method will compare the `original` and `current` composite settings objects to determine which parts have changed and conditionally execute the appropriate save logic for each part.
- [x] 2.4: Migrate all user-facing setter methods (e.g., `setWiFiSSID`, `setClientSteeringEnabled`, `setMacFilterMode`) from the old notifiers into the new `WifiBundleNotifier`, updating them to modify the new `WifiBundleState`.

## Phase 3: Refactor UI Layer
- [x] 3.1: Refactor `WiFiMainView` to remove the manual `TabController` listener and `onBackTap` dirty-checking logic.
- [x] 3.2: Add a single, page-level `PageBottomBar` to `WiFiMainView`, with its save button's `onPositiveTap` connected to the new `wifiBundleProvider.notifier.save()` method and `isPositiveEnabled` bound to the provider's `isDirty` state.
- [x] 3.3: Refactor `WiFiListView`, `WifiAdvancedSettingsView`, and `MacFilteringView` to watch the single `wifiBundleProvider` for their state and to call its notifier for all UI actions.
- [x] 3.4: Remove all local `_preservedState` variables and manual dirty-checking logic from the sub-views.
- [x] 3.5: Once the refactoring is complete and verified, delete the now-obsolete provider files: `wifiViewProvider.dart`, `wifi_list_provider.dart`, `wifi_advanced_provider.dart`, and the parts of `instant_privacy_provider.dart` that have been consolidated.

## Phase 4: Refactor and Update Tests
- [x] 4.1: Create new test data structures in `test/test_data/` that match the consolidated `WifiBundleSettings` and `WifiBundleStatus` models by composing existing test data.
- [x] 4.2: Create a new mock notifier, `MockWifiBundleNotifier`, for the `WifiBundleNotifier`.
- [x] 4.3: Refactor widget tests in `test/page/wifi_settings/**` to remove dependencies on old notifiers and their providers.
- [x] 4.4: Update the widget tests to override the new `wifiBundleProvider` with the `MockWifiBundleNotifier` and use the new consolidated test data for setting up test states.
- [x] 4.5: Update test assertions to check against the new `WifiBundleState` structure.

## Phase 5: Update Routing & Finalize
- [x] 5.1: In `lib/route/route_menu.dart`, find the `LinksysRoute` for the Wi-Fi Settings page (`RoutePath.menuIncredibleWiFi`).
- [x] 5.2: Configure the route with `enableDirtyCheck: true` and pass the new `preservableWifiSettingsProvider` to the `preservableProvider` parameter.
- [x] 5.3: Run all relevant integration and unit tests to verify that the new implementation works as expected and that the navigation guard is functioning correctly.