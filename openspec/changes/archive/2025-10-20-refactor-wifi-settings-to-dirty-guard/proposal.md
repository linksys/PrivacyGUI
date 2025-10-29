## Why
The current Wi-Fi Settings feature has a complex and error-prone state management implementation. State is scattered across multiple providers, and dirty-checking logic is duplicated manually in each of the three sub-views (Wi-Fi, Advanced, MAC Filtering). This makes the code difficult to maintain and introduces bugs, such as inconsistent unsaved changes warnings.

## What Changes
This proposal outlines the refactoring of the entire Wi-Fi Settings feature (`/incredible-wifi`) to use the existing, robust `dirty-guard` framework.

The core changes are:
- **Consolidate State:** Combine the state from `WifiListNotifier`, `WifiAdvancedSettingsNotifier`, and `InstantPrivacyNotifier` into a single, unified `WifiBundleNotifier`.
- **Compositional Data Models:** The new notifier's state will be built by *composing* the existing data models, not by duplicating fields, to ensure code reuse and high cohesion.
- **Adopt the Framework:** The new `WifiBundleNotifier` will use the `PreservableNotifierMixin` to gain automatic state preservation and dirty-checking capabilities.
- **Simplify UI:** All manual dirty-checking logic will be removed from the UI layer. A single, page-level save button will be implemented. The `LinksysRoute` will be configured to automatically handle navigation guards for the entire feature, and an additional tab-level navigation guard will be implemented within `WiFiMainView` to enforce saving or discarding changes before switching tabs.

## Impact
- **Affected Specs:** `wifi-settings` (delta spec for this change).
- **Affected Code:**
  - `lib/page/wifi_settings/**`: All providers and views in this directory will be significantly refactored and simplified.
  - `lib/route/route_menu.dart`: The route for `/incredible-wifi` will be updated to enable the dirty-guard.
- **Outcome:** The refactoring will result in a much cleaner, more maintainable, and more robust implementation that aligns with the project's established architecture for handling user settings.
