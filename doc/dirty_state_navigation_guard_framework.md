# "Dirty State" Navigation Guard Framework

## 1. Problem Statement

In a complex application, users frequently make changes to settings on a page. If the user accidentally navigates away (e.g., by clicking the browser's back button, or using a menu to go to another page) before saving, their changes are lost without warning.

A robust, application-wide solution is needed to intercept any navigation attempt away from a "dirty" (modified but unsaved) page and prompt the user for confirmation.

## 2. Core Requirement

To design and implement a generic, reusable, and declarative framework that:
1.  Can be easily applied to any feature/page that has saveable settings.
2.  Reliably detects if a page's state is "dirty".
3.  Separates user-configurable "settings" from transient system "status" to prevent false-positive dirty checks.
4.  Integrates seamlessly with `go_router` to intercept all forms of navigation.
5.  Provides a simple, declarative API for developers to enable this feature on a per-route basis.

## 3. Architectural Solution

The proposed solution is a framework built on a principle of composition and contracts, consisting of four main parts.

### Part 1: `Preservable<T>` - The Core Data Wrapper

This generic class tracks the state of user-configurable settings. It holds `original` and `current` versions of the data and contains the core `isDirty` logic.

**File:** `lib/providers/preservable.dart`
```dart
import 'package:equatable/equatable.dart';

class Preservable<T extends Equatable> extends Equatable {
  final T original;
  final T current;

  const Preservable({required this.original, required this.current});

  bool get isDirty => original != current;

  Preservable<T> update(T newCurrent) => copyWith(current: newCurrent);
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

This abstract class provides a standardized structure for a feature's state object, separating `settings` from `status`. We add an abstract `copyWith` method to ensure subclasses can be updated immutably.

**File:** `lib/providers/feature_state.dart`
```dart
import 'package:equatable/equatable.dart';
import 'preservable.dart';

abstract class FeatureState<TSettings extends Equatable, TStatus extends Equatable> extends Equatable {
  final Preservable<TSettings> settings;
  final TStatus status;

  const FeatureState({required this.settings, required this.status});

  bool get isDirty => settings.isDirty;

  // Contract to ensure subclasses are copyable.
  FeatureState<TSettings, TStatus> copyWith({
    Preservable<TSettings>? settings,
    TStatus? status,
  });

  @override
  List<Object?> get props => [settings, status];
}
```

### Part 3: The Notifier Contract & Implementation (Interface + Mixin)

To provide reusable logic (`revert`, `isDirty`) while allowing `LinksysRoute` to safely interact with any Notifier, we use a combination of an interface and a mixin.

**File:** `lib/providers/preservable_notifier.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'feature_state.dart';
import 'preservable.dart';

// The Interface (The "What")
// This defines the contract that LinksysRoute will check for.
abstract class PreservableContract {
  void revert();
  bool isDirty();
}

// The Mixin (The "How")
// This provides the reusable implementation for any Notifier.
mixin PreservableNotifierMixin<
    TSettings extends Equatable,
    TStatus extends Equatable,
    TState extends FeatureState<TSettings, TStatus>> on Notifier<TState> implements PreservableContract {
  @override
  void revert() {
    state = state.copyWith(
      settings: state.settings.copyWith(current: state.settings.original),
    ) as TState;
  }

  @override
  bool isDirty() => state.isDirty;

  void markAsSaved() {
    state = state.copyWith(settings: state.settings.saved()) as TState;
  }
}
```

### Part 4: `LinksysRoute` - The Smart Router

The custom route class is updated to check for the `PreservableContract` and call `revert` when needed.

**File:** `lib/route/route_model.dart`
```dart
// ... imports ...
import 'package:privacy_gui/providers/preservable_notifier.dart';

class LinksysRoute extends GoRoute {
  // ... constructor ...
  LinksysRoute({
    // ... other parameters
    ProviderListenable<FeatureState>? provider,
    bool enableDirtyCheck = false,
  }) : super(
          onExit: (context, state) async {
            if (enableDirtyCheck && provider != null) {
              final container = ProviderScope.containerOf(context);
              final notifier = container.read(provider.notifier);

              // Check if the notifier follows the contract
              if (notifier is PreservableContract && notifier.isDirty()) {
                final bool? confirmed = await showUnsavedAlert(context);
                if (confirmed == true) {
                  // User wants to discard, so revert the state.
                  notifier.revert();
                  return true; // Allow navigation
                } else {
                  return false; // User cancelled, block navigation.
                }
              }
            }
            return true; // Allow navigation
          },
        );
  // ...
}
```

## 4. Implementation Guide

To apply this framework to a new feature:

1.  **Define Data Classes**: Create `Equatable` classes for your `Settings` and `Status`.
2.  **Create Feature State**: Extend `FeatureState` and implement the `copyWith` method.
3.  **Create Notifier**: Create a `Notifier` that `extends Notifier<YourState>` and add `with PreservableNotifierMixin`.
4.  **Update Route**: Use `LinksysRoute` in your router configuration, passing the `provider` and setting `enableDirtyCheck: true`.

**Example `InstantSafetyNotifier`:**
```dart
class InstantSafetyNotifier extends Notifier<InstantSafetyState>
    with PreservableNotifierMixin<InstantSafetySettings, InstantSafetyStatus, InstantSafetyState> {
  
  // Implement build, fetch, and save methods...

  // revert() and isDirty() are now provided automatically by the mixin!
}
```

## 5. Conclusion

This framework, combining a data wrapper, a state template, an interface, and a mixin, provides a highly reusable, robust, and developer-friendly solution for managing unsaved changes and navigation guards across the application.