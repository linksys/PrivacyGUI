# Dirty State Navigation Guard Framework

## 1. Problem Statement

In a complex application, users frequently make changes to settings on a page. If the user accidentally navigates away (e.g., by clicking the browser's back button, or using a menu to go to another page) before saving, their changes are lost without warning.

The existing approach of handling this via a custom `onBackTap` callback on a page's app bar is insufficient, as it does not cover all navigation scenarios. A robust, application-wide solution is needed to intercept any navigation attempt away from a "dirty" (modified but unsaved) page and prompt the user for confirmation.

## 2. Core Requirement

To design and implement a generic, reusable, and declarative framework that:
1.  Can be easily applied to any feature/page that has saveable settings.
2.  Reliably detects if a page's state is "dirty".
3.  Separates user-configurable "settings" from transient system "status" to prevent false-positive dirty checks.
4.  Integrates seamlessly with `go_router` to intercept all forms of navigation (pops, `go`, `push`).
5.  Provides a simple, declarative API for developers to enable this feature on a per-route basis.

## 3. Architectural Solution

The proposed solution is a three-part framework that leverages Riverpod for state management and `go_router` for navigation, built on a principle of composition.

### Part 1: `Preservable<T>` - The Core Wrapper

This is a generic wrapper class responsible for tracking the state of user-configurable settings. It holds two copies of the data: `original` (the state when the page was loaded or last saved) and `current` (the state after user modifications). It contains the core `isDirty` logic.

**File:** `lib/providers/preservable.dart`
```dart
import 'package:equatable/equatable.dart';

/// A generic wrapper for data that needs dirty-checking.
/// `T` represents the settings data class.
class Preservable<T extends Equatable> extends Equatable {
  final T original;
  final T current;

  const Preservable({required this.original, required this.current});

  /// True if the current data is different from the original.
  bool get isDirty => original != current;

  /// Returns a new instance with an updated `current` value.
  Preservable<T> update(T newCurrent) => copyWith(current: newCurrent);

  /// Returns a new instance where `original` is updated to match `current`.
  /// This is called after a successful save operation.
  Preservable<T> saved() => copyWith(original: current);

  Preservable<T> copyWith({T? original, T? current}) {
    return Preservable<T>(
      original: original ?? this.original,
      current: current ?? this.current,
    );
  }

  @override
  List<Object?> get props => [original, current];
}
```

### Part 2: `FeatureState<S, T>` - The State Template

This abstract class provides a standardized structure for a feature's state object. It enforces the separation of concerns between `settings` (which are wrapped by `Preservable<T>`) and `status` (transient, read-only data).

**File:** `lib/providers/feature_state.dart`
```dart
import 'package:equatable/equatable.dart';
import 'preservable.dart';

/// An abstract base class for feature states that separates
/// preservable settings from transient status.
///
/// [TSettings] is the type for user-configurable data.
/// [TStatus] is the type for read-only system status data.
abstract class FeatureState<TSettings extends Equatable, TStatus extends Equatable> extends Equatable {
  final Preservable<TSettings> settings;
  final TStatus status;

  const FeatureState({required this.settings, required this.status});

  /// Checks if the settings have been modified.
  bool get isDirty => settings.isDirty;

  @override
  List<Object?> get props => [settings, status];
}
```

### Part 3: `LinksysRoute` - The Smart Router

This custom `GoRoute` subclass encapsulates the navigation guard logic. By making it generic and aware of the feature's provider, it can automatically enable the `onExit` dirty check in a declarative way.

**File:** `lib/route/linksys_route.dart` (Example Path)
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/providers/feature_state.dart';

class LinksysRoute<S extends FeatureState> extends GoRoute {
  
  LinksysRoute({
    required super.path,
    required super.builder,
    NotifierProviderBase<dynamic, S>? provider,
    bool enableDirtyCheck = false,
    FutureOr<bool> Function(BuildContext)? onExit,
    // ... other GoRoute parameters
  }) : super(
          onExit: (context) async {
            // First, run any custom onExit logic provided by the developer.
            if (onExit != null) {
              if (!await onExit(context)) {
                return false; // Custom logic blocked navigation.
              }
            }

            // If dirty checking is enabled and a provider is given...
            if (enableDirtyCheck && provider != null) {
              final container = ProviderScope.containerOf(context);
              final currentState = container.read(provider);

              if (currentState.isDirty) {
                final bool? confirmed = await showUnsavedAlert(context);
                if (confirmed != true) {
                  return false; // User cancelled, block navigation.
                }
              }
            }

            // Allow navigation to proceed.
            return true;
          },
        );
}
```

## 4. Implementation Guide

To apply this framework to a new or existing feature (e.g., a "VPN" page):

**Step 1: Define Data Classes**
Create separate, `Equatable` classes for your settings and status.
```dart
class VPNSettings extends Equatable { /* ... */ }
class VPNStatus extends Equatable { /* ... */ }
```

**Step 2: Create the Feature State**
Create your state class by extending `FeatureState`.
```dart
class VPNState extends FeatureState<VPNSettings, VPNStatus> {
  const VPNState({required super.settings, required super.status});

  // Implement initial state factory and copyWith
  factory VPNState.initial() { ... }
  VPNState copyWith({ ... }) { ... }
}
```

**Step 3: Implement the Notifier**
Your `StateNotifier` will manage the `VPNState`.
```dart
class VPNNotifier extends StateNotifier<VPNState> {
  // ...
  Future<void> fetch() async {
    // On fetch, initialize both original and current settings
    state = state.copyWith(
      settings: Preservable(original: settingsData, current: settingsData),
      status: statusData,
    );
  }

  void updateSomeSetting(String value) {
    // When updating, use the .update() helper on the settings
    state = state.copyWith(
      settings: state.settings.update(
        state.settings.current.copyWith(someValue: value),
      ),
    );
  }

  Future<void> save() async {
    await _repo.save(state.settings.current);
    // After saving, use the .saved() helper to reset the dirty state
    state = state.copyWith(settings: state.settings.saved());
  }
}
```

**Step 4: Configure the Route**
In your router configuration, use the `LinksysRoute` and enable the dirty check.
```dart
// router.dart
final routes = [
  LinksysRoute<VPNState>(
    path: '/vpn',
    builder: (context, state) => const VPNView(),
    provider: vpnProvider,      // Pass the provider
    enableDirtyCheck: true,   // Enable the guard
  ),
];
```

## 5. Conclusion

This framework provides a robust, scalable, and maintainable solution for handling unsaved changes. It centralizes complex logic, reduces boilerplate code, and provides a simple, declarative API for developers, significantly improving both code quality and developer experience.
