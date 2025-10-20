### **Developer Guide: How to Use the Dirty State Navigation Guard Framework**

#### **1. What is it? Why use it?**

This framework addresses a common problem: preventing accidental loss of unsaved changes when a user navigates away from a page where they have modified settings.

This framework provides a standardized solution that:
*   Automatically detects if the page state is "dirty" (modified but not saved).
*   Automatically prompts the user with a dialog when they attempt to leave a dirty page.
*   Offers standardized `fetch` and `save` templates, simplifying data reading and saving processes.

**In short: Any page that allows users to modify and save settings should use this framework.**

#### **2. How to Use: A Five-Step Guide**

Applying this framework to a new Feature is straightforward. Follow these five steps:

**Step 1: Define Data Models (`Settings` & `Status`)**
*   Create two `Equatable` classes for your feature.
*   `Settings` class: Holds all fields that **users can modify**.
*   `Status` class: Holds all **read-only** system states or data fetched from the backend that users do not directly modify.
*   Implement `toMap` and `fromMap` methods for both classes for serialization.

**Step 2: Define the Feature's `State`**
*   Create a `State` class that extends `FeatureState<YourSettings, YourStatus>`.
*   Implement the necessary `copyWith` and `toMap` methods.
*   **Optional: Override `isDirty`**: If certain fields in `YourSettings` should *not* trigger the dirty state (e.g., UI-only flags), override the `isDirty` getter in `YourState`. Compare `settings.original` and `settings.current` while ignoring the specified fields.

**Step 3: Create the `Notifier`**
*   Create a `Notifier` class that extends `Notifier<YourState>`.
*   Add `with PreservableNotifierMixin<YourSettings, YourStatus, YourState>`.

**Step 4: Implement `build`, `performFetch`, and `performSave`**
*   In your Notifier, implement the `build` method:
    *   `build()`: This method should be **synchronous**. Initialize an `initial` state (e.g., from other providers or default values). Then, **asynchronously trigger `fetch()`** (e.g., `Future.microtask(() => fetch());`) to load actual data without blocking the UI. Return the `initial` state.
*   Override and implement the two abstract methods from the Mixin:
    *   `performFetch()`: Write the logic to read data from your API or database. Finally, return a `Record` of `(YourSettings, YourStatus)`.
    *   `performSave()`: Write the logic to save the data from `state.settings.current` to your API or database.
*   **You do not need to manually update the state**; the `fetch()` and `save()` template methods in the Mixin will handle this automatically.

**Step 5: Configure the Route (`LinksysRoute`) and UI**
*   In your route configuration file, locate the route definition for the page.
*   Ensure it uses `LinksysRoute`.
*   Pass the `preservableProvider` parameter (pointing to your Notifier).
*   Set `enableDirtyCheck: true`.
*   **For Tabbed Interfaces (e.g., `StyledAppPageView`):** If your feature uses tabs, implement a listener on the `TabController` in your UI layer (e.g., `_YourViewState` for `YourView`). In this listener, check `ref.read(yourProvider.notifier).isDirty()`. If dirty, show a confirmation dialog (save/discard/cancel) before allowing the tab change.

#### **3. Code Example**

```dart
// 1. & 2. Define Model and State (with optional custom isDirty)
class MyFeatureSettings extends Equatable {
  final String name;
  final bool isEnabled;
  final bool uiOnlyFlag; // Example of a field to exclude from dirty check

  const MyFeatureSettings({required this.name, required this.isEnabled, this.uiOnlyFlag = false});

  @override
  List<Object?> get props => [name, isEnabled, uiOnlyFlag];

  MyFeatureSettings copyWith({String? name, bool? isEnabled, bool? uiOnlyFlag}) {
    return MyFeatureSettings(
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      uiOnlyFlag: uiOnlyFlag ?? this.uiOnlyFlag,
    );
  }
}

class MyFeatureStatus extends Equatable {
  final bool isOnline;
  const MyFeatureStatus({required this.isOnline});
  @override
  List<Object?> get props => [isOnline];
}

class MyFeatureState extends FeatureState<MyFeatureSettings, MyFeatureStatus> {
  const MyFeatureState({required super.settings, required super.status});

  @override
  MyFeatureState copyWith({
    Preservable<MyFeatureSettings>? settings,
    MyFeatureStatus? status,
  }) {
    return MyFeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  // Custom isDirty getter to exclude uiOnlyFlag
  @override
  bool get isDirty {
    final originalForComparison = settings.original.copyWith(uiOnlyFlag: false);
    final currentForComparison = settings.current.copyWith(uiOnlyFlag: false);
    return originalForComparison != currentForComparison;
  }
}

// 3. & 4. Create Notifier and implement template methods
final myFeatureProvider = NotifierProvider<MyFeatureNotifier, MyFeatureState>(() {
  return MyFeatureNotifier();
});
final preservableMyFeatureProvider = Provider<PreservableContract<MyFeatureSettings, MyFeatureStatus>>((ref) {
  return ref.watch(myFeatureProvider.notifier);
});

class MyFeatureNotifier extends Notifier<MyFeatureState>
    with PreservableNotifierMixin<MyFeatureSettings, MyFeatureStatus, MyFeatureState> {

  @override
  MyFeatureState build() {
    // Initialize with a default or loading state
    final initialSettings = MyFeatureSettings(name: 'Loading...', isEnabled: false);
    final initialStatus = MyFeatureStatus(isOnline: false);
    final initialState = MyFeatureState(
      settings: Preservable(original: initialSettings, current: initialSettings),
      status: initialStatus,
    );

    // Asynchronously trigger fetch to load actual data
    Future.microtask(() => fetch());
    return initialState;
  }

  @override
  Future<(MyFeatureSettings?, MyFeatureStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    // Write your API call logic here
    // Example:
    // final settings = await repository.getSettings();
    // final status = await repository.getStatus();
    // return (settings, status);
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    final fetchedSettings = MyFeatureSettings(name: 'Fetched Name', isEnabled: true);
    final fetchedStatus = MyFeatureStatus(isOnline: true);
    return (fetchedSettings, fetchedStatus);
  }

  @override
  Future<void> performSave() async {
    // Write your API save logic here
    // Example:
    // await repository.saveSettings(state.settings.current);
    await Future.delayed(const Duration(seconds: 1)); // Simulate API save
    print('Settings saved: ${state.settings.current}');
  }

  // Example setter
  void setName(String newName) {
    state = state.copyWith(
      settings: state.settings.update(state.settings.current.copyWith(name: newName)),
    );
  }
}

// 5. Configure the Route and UI
// In lib/route/route_menu.dart:
LinksysRoute(
  path: '/my-feature',
  preservableProvider: preservableMyFeatureProvider,
  enableDirtyCheck: true,
  builder: (context, state) => const MyFeatureView(), // MyFeatureView would be a ConsumerStatefulWidget
),

// In MyFeatureView (if it has tabs):
class MyFeatureView extends ConsumerStatefulWidget {
  const MyFeatureView({super.key});

  @override
  ConsumerState<MyFeatureView> createState() => _MyFeatureViewState();
}

class _MyFeatureViewState extends ConsumerState<MyFeatureView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _previousIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Assuming 3 tabs
    _previousIndex = _tabController.index;
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleTabChange() async {
    if (!_tabController.indexIsChanging) {
      return;
    }

    final notifier = ref.read(myFeatureProvider.notifier);
    if (notifier.isDirty()) {
      final shouldProceed = await showConfirmDiscardDialog(context); // Assuming showConfirmDiscardDialog is available
      if (shouldProceed == true) {
        await notifier.save();
      } else if (shouldProceed == false) {
        notifier.revert();
      } else {
        // User cancelled, prevent tab change
        _tabController.index = _previousIndex;
        return;
      }
    }
    _previousIndex = _tabController.index;
  }

  @override
  Widget build(BuildContext context) {
    // ... UI implementation using StyledAppPageView with _tabController ...
    return StyledAppPageView(
      // ... other properties ...
      tabController: _tabController,
      // ...
    );
  }
}