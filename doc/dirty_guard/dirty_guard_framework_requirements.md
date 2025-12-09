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

This generic class tracks the state of user-configurable settings. It holds `original` and `current` versions of the data and contains the core `isDirty` logic. It also includes serialization helpers.

**File:** `lib/providers/preservable.dart`
```dart
import 'dart:convert';
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

  factory Preservable.fromMap(
    Map<String, dynamic> map,
    T Function(dynamic map) fromMapT,
  ) {
    return Preservable<T>(
      original: fromMapT(map['original']),
      current: fromMapT(map['current']),
    );
  }

  Map<String, dynamic> toMap(Map<String, dynamic> Function(T value) toMapT) {
    return {
      'original': toMapT(original),
      'current': toMapT(current),
    };
  }

  String toJson(Map<String, dynamic> Function(T value) toMapT) =>
      json.encode(toMap(toMapT));

  factory Preservable.fromJson(
    String source,
    T Function(dynamic map) fromMapT,
  ) =>
      Preservable.fromMap(json.decode(source), fromMapT);

  @override
  List<Object?> get props => [original, current];
}
```

### Part 2: `FeatureState<S, T>` - The State Template

This abstract class provides a standardized structure for a feature's state object, separating `settings` from `status`. It now includes contracts for `copyWith` and serialization.

**File:** `lib/providers/feature_state.dart`
```dart
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'preservable.dart';

abstract class FeatureState<TSettings extends Equatable, TStatus extends Equatable> extends Equatable {
  final Preservable<TSettings> settings;
  final TStatus status;

  const FeatureState({required this.settings, required this.status});

  bool get isDirty => settings.isDirty;

  FeatureState<TSettings, TStatus> copyWith({
    Preservable<TSettings>? settings,
    TStatus? status,
  });

  Map<String, dynamic> toMap();

  String toJson() => json.encode(toMap());

  @override
  List<Object?> get props => [settings, status];
}
```

### Part 3: The Notifier Contract & Template Method Mixin

To provide reusable logic and a clear contract, we use an interface (`PreservableContract`) and a mixin (`PreservableNotifierMixin`) that implements the Template Method design pattern for `fetch` and `save` operations.

**File:** `lib/providers/preservable_contract.dart`
```dart
import 'package:equatable/equatable.dart';

abstract class PreservableContract<TSettings extends Equatable, TStatus extends Equatable> {
  void revert();
  bool isDirty();

  // Methods to be implemented by the concrete notifier for the template.
  Future<(TSettings?, TStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  });
  Future<void> performSave();
}
```

**File:** `lib/providers/preservable_notifier_mixin.dart`
```dart
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feature_state.dart';
import 'preservable.dart';
import 'preservable_contract.dart';

mixin PreservableNotifierMixin<
    TSettings extends Equatable,
    TStatus extends Equatable,
    TState extends FeatureState<TSettings, TStatus>> on Notifier<TState> implements PreservableContract<TSettings, TStatus> {

  Future<void> fetch({bool forceRemote = false, bool updateStatusOnly = false}) async {
    final (newSettings, newStatus) = await performFetch(
      forceRemote: forceRemote,
      updateStatusOnly: updateStatusOnly,
    );
    if (updateStatusOnly) {
      if (newStatus != null) {
        state = state.copyWith(status: newStatus) as TState;
      }
    } else {
      if (newSettings != null) {
        state = state.copyWith(
          settings: Preservable(original: newSettings, current: newSettings),
          status: newStatus ?? state.status,
        ) as TState;
      }
    }
  }

  Future<void> save() async {
    await performSave();
    markAsSaved();
    await fetch();
  }

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
import 'package:privacy_gui/providers/preservable_contract.dart';

class LinksysRoute extends GoRoute {
  // ... constructor ...
  LinksysRoute({
    // ... other parameters
    Provider<PreservableContract>? preservableProvider, // The provider is now generic
    bool enableDirtyCheck = false,
  }) : super(
          onExit: (context, state) async {
            if (enableDirtyCheck && preservableProvider != null) {
              final container = ProviderScope.containerOf(context);
              final notifier = container.read(preservableProvider);

              if (notifier.isDirty()) {
                final bool? confirmed = await showUnsavedAlert(context);
                if (confirmed == true) {
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

1.  **Define Data Classes**: Create `Equatable` classes for your `Settings` and `Status`. Implement `toMap` and `fromMap` for each.
2.  **Create Feature State**: Extend `FeatureState` and implement the `copyWith` and `toMap` methods.
3.  **Create Notifier**: Create a `Notifier` that `extends Notifier<YourState>` and add `with PreservableNotifierMixin`.
4.  **Implement Template Methods**: In your Notifier, implement the required `performFetch` and `performSave` methods with your feature-specific logic.
5.  **Update Route**: Use `LinksysRoute` in your router configuration, passing the `provider` (which should expose the `PreservableContract`) and setting `enableDirtyCheck: true`.

**Example `InstantSafetyNotifier`:**
```dart
class InstantSafetyNotifier extends Notifier<InstantSafetyState>
    with PreservableNotifierMixin<InstantSafetySettings, InstantSafetyStatus, InstantSafetyState> {
  
  @override
  InstantSafetyState build() {
    fetch(); // Call the template method from the mixin
    return InstantSafetyState.initial();
  }

  @override
  Future<(InstantSafetySettings?, InstantSafetyStatus?)> performFetch({ ... }) async {
    // 1. Call your repository to get the raw data (e.g., lanSettings)
    // 2. Create new settings and status objects from the raw data
    // 3. Return (newSettings, newStatus)
  }

  @override
  Future<void> performSave() async {
    // 1. Get current settings from state.settings.current
    // 2. Build the payload for your API call
    // 3. Call your repository to save the data
  }

  // ... other UI-specific methods like setSafeBrowsingEnabled()
}
```

## 5. Conclusion

This framework, combining a data wrapper, a state template, a contract, and a template method mixin, provides a highly reusable, robust, and developer-friendly solution for managing state, persistence, and navigation guards across the application.
