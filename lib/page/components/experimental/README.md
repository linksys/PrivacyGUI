# Experimental UI Kit Page View

This directory contains the experimental UI Kit integration layer for PrivacyGUI, providing 100% API compatibility with `StyledAppPageView` while internally using the UI Kit `AppPageView` component.

## Components Overview

### Core Components

1. **`ExperimentalUiKitPageView`** - Main drop-in replacement for `StyledAppPageView`
2. **`UiKitPageViewAdapter`** - Parameter conversion layer from PrivacyGUI to UI Kit format
3. **`PrivacyGuiWrappers`** - Domain-specific business logic wrappers

### Test Suite

- **`adapter_test.dart`** - Tests for parameter conversion logic
- **`compatibility_test.dart`** - API compatibility verification
- **`experimental_ui_kit_page_view_test.dart`** - Integration tests for the main component

## Usage

### Basic Usage (Drop-in Replacement)

Replace any existing `StyledAppPageView` with `ExperimentalUiKitPageView`:

```dart
// Before (Original PrivacyGUI)
StyledAppPageView(
  title: 'Settings Page',
  appBarStyle: AppBarStyle.back,
  child: (context, constraints) => SettingsContent(),
  bottomBar: PageBottomBar(
    isPositiveEnabled: true,
    positiveLabel: 'Save',
    onPositiveTap: () => _saveSettings(),
  ),
)

// After (Experimental UI Kit)
ExperimentalUiKitPageView(
  title: 'Settings Page',
  appBarStyle: AppBarStyle.back,
  child: (context, constraints) => SettingsContent(),
  bottomBar: PageBottomBar(
    isPositiveEnabled: true,
    positiveLabel: 'Save',
    onPositiveTap: () => _saveSettings(),
  ),
)
```

### Migration Extension

Use the migration extension for gradual rollout:

```dart
// Existing StyledAppPageView
final originalPageView = StyledAppPageView(
  title: 'Dashboard',
  menu: PageMenu(
    title: 'Navigation',
    items: [
      PageMenuItem(label: 'Overview', icon: Icons.dashboard, onTap: () {}),
      PageMenuItem(label: 'Settings', icon: Icons.settings, onTap: () {}),
    ],
  ),
  child: (context, constraints) => DashboardContent(),
);

// Convert to experimental version
final experimentalPageView = originalPageView.toExperimentalUiKit();
```

### Inner Page Factory

For inner pages without app bar:

```dart
ExperimentalUiKitPageView.innerPage(
  child: (context, constraints) => InnerContent(),
  bottomBar: PageBottomBar(
    isPositiveEnabled: true,
    positiveLabel: 'Apply Changes',
    onPositiveTap: () => _applyChanges(),
  ),
  padding: const EdgeInsets.all(16),
  scrollable: true,
)
```

## Features

### 100% API Compatibility

- **Constructor Parameters**: All `StyledAppPageView` parameters supported
- **Factory Constructors**: `innerPage` factory method available
- **Parameter Types**: Exact type matching with original API
- **Behavioral Compatibility**: Same UI behavior and interactions

### Automatic Parameter Conversion

The adapter automatically converts between PrivacyGUI and UI Kit formats:

- **AppBar Configuration**: `AppBarStyle` + `StyledBackState` → `PageAppBarConfig`
- **Bottom Bar Configuration**: `PageBottomBar` → `PageBottomBarConfig` (including destructive detection)
- **Menu Configuration**: `PageMenu` → `PageMenuConfig` (with responsive behavior)
- **Layout Parameters**: Padding, scrolling, SafeArea configuration
- **Tab Navigation**: Tab controller and content view management

### PrivacyGUI Domain Logic Integration

Automatic integration of PrivacyGUI-specific business logic:

- **Connection State Handling**: Shows no-connection UI when network unavailable
- **Banner Management**: Displays system banners and notifications
- **Scroll Behavior**: Handles bottom navigation visibility and scroll events
- **Localization**: Automatic label translation using PrivacyGUI localization system
- **Navigation**: Integration with GoRouter navigation patterns

### Edge Case Handling

Robust error handling for malformed configurations:

- **Mismatched Tab Counts**: Automatically truncates to matching length
- **Empty Menu Items**: Filters out invalid menu entries
- **Malformed Bottom Bar**: Provides sensible defaults for incomplete configuration
- **Invalid Toolbar Heights**: Clamps to reasonable bounds

## Architecture

### Parameter Flow

```
StyledAppPageView Parameters
           ↓
UiKitPageViewAdapter.convertXXXConfig()
           ↓
PageXXXConfig (UI Kit format)
           ↓
PrivacyGuiWrappers.wrapWithXXX()
           ↓
AppPageView (UI Kit Component)
```

### Domain Logic Layers

1. **Compatibility Layer**: `ExperimentalUiKitPageView` - API compatibility
2. **Conversion Layer**: `UiKitPageViewAdapter` - Parameter format conversion
3. **Business Logic Layer**: `PrivacyGuiWrappers` - Domain-specific behaviors
4. **UI Layer**: UI Kit `AppPageView` - Actual rendering

## Testing

### Test Coverage

- **Unit Tests**: Parameter conversion logic
- **Widget Tests**: Component rendering and behavior
- **Integration Tests**: End-to-end compatibility verification
- **Edge Case Tests**: Error handling and malformed input

### Running Tests

```bash
# Run all experimental component tests
flutter test test/page/components/experimental/

# Run specific test files
flutter test test/page/components/experimental/adapter_test.dart
flutter test test/page/components/experimental/experimental_ui_kit_page_view_test.dart
flutter test test/page/components/experimental/compatibility_test.dart
```

## Limitations and TODOs

### Current Limitations

1. **UI Kit Dependency**: Requires UI Kit library to be added as dependency
2. **Provider Integration**: Connection state and banner providers need actual implementation
3. **Localization Keys**: Some localization keys may need to be added to PrivacyGUI
4. **Theme Integration**: UI Kit themes need to be configured for PrivacyGUI app

### TODO Items

```dart
// Connection state provider integration
// TODO: Replace with actual PrivacyGUI connection state provider
// final connectionState = ref.watch(connectionStateProvider);

// Banner state provider integration
// TODO: Replace with actual PrivacyGUI banner provider
// final bannerState = ref.watch(bannerStateProvider);

// Bottom navigation controller integration
// TODO: Integrate with PrivacyGUI bottom navigation controller
// final bottomNavController = ref.read(bottomNavigationControllerProvider.notifier);

// Menu title localization
// TODO: Add menu title localization mapping if needed
// final titleMap = {
//   'Navigation': context.loc.navigation,
//   'Settings': context.loc.settings,
//   'Options': context.loc.options,
// };
```

## Migration Strategy

### Phase 1: Experimental Usage
- Use `ExperimentalUiKitPageView` for new pages
- Test compatibility with existing PrivacyGUI patterns
- Gather feedback and iterate on implementation

### Phase 2: Gradual Migration
- Use migration extension to convert existing pages
- Run A/B tests between original and experimental versions
- Monitor performance and user experience

### Phase 3: Full Rollout
- Replace `StyledAppPageView` imports with `ExperimentalUiKitPageView`
- Deprecate original `StyledAppPageView` component
- Complete UI Kit theme integration

### Phase 4: Stabilization
- Remove "Experimental" prefix from component name
- Move from experimental directory to stable component directory
- Update all documentation and examples

## Support and Feedback

For issues, questions, or feedback regarding the experimental UI Kit integration:

1. Check existing test coverage for expected behavior
2. Review parameter conversion logic in `UiKitPageViewAdapter`
3. Verify domain logic wrappers in `PrivacyGuiWrappers`
4. Create test cases to reproduce any issues
5. Submit feedback with specific use cases and requirements