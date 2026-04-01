# Screenshot Testing Workflow Guide

This document explains how to implement screenshot testing (golden testing) for new feature pages to ensure UI visual regression testing.

## Prerequisites

⚠️ **Important Note About Riverpod Notifier Mocks**: This project uses Riverpod providers which require:
1. **Mock Specification Files** - Create `test/mocks/mockito_specs/[feature]_notifier_spec.dart` with `@GenerateMocks` annotations
2. **Special Mock Class Signatures** - `@GenerateNiceMocks` will NOT work and will cause `_setElement` errors
3. **Manual Signature Fixes** - Generated mocks must be manually edited to extend `Notifier<State>`

Follow the complete process in Step 5 or tests will fail.

### 1. Identify New Feature Pages
- Check git branch additions: `git show --name-only [commit-hash]`
- Confirm new page locations: typically in `lib/page/[feature-name]/views/`
- Identify main View components and related Provider/Notifier classes

### 2. Understand Existing Test Architecture
- Review `test/page/` directory structure
- Reference existing `*_test.dart` files, especially tests under `localizations` directories
- Confirm mock file naming conventions: `test/mocks/[feature]_notifier_mocks.dart`

## File Structure Setup

### 3. Create Test Directory Structure
```bash
mkdir -p test/page/[feature-name]/views/localizations
```

**Note**: The `goldens/` directory will be automatically created when running tests - no manual creation needed.

### 4. Required Files List

**Mock Files** (generated from spec):
- `test/mocks/mockito_specs/[feature]_notifier_spec.dart` - **Mock specification file** (input for build_runner)
- `test/mocks/[feature]_notifier_mocks.dart` - Final mock implementation (generated + manually fixed)

**Test Files**:
- `test/page/[feature-name]/views/localizations/[feature]_views_test.dart` - Main test file
- `test/page/[feature-name]/views/localizations/[feature]_test_data.dart` - Test data

**Note**: The mock spec file is the starting point - without it, `build_runner` cannot generate the required mock classes.

## Mock and Test Data Preparation

### 5. Create Mock Specification File

**What is a Mock Spec File?**  
A Mock specification file is a Dart file that tells Mockito's `build_runner` which classes to generate mocks for. It doesn't contain actual mock implementations - just annotations that specify what to mock.

**Why do we need spec files?**  
This project uses `build_runner` to automatically generate mock classes instead of writing them manually. The spec file acts as a "blueprint" that tells the build system:
- Which classes need mock versions
- Where to import the original classes from
- How to generate the mock files

**Project Structure:**
- **Spec files**: `test/mocks/mockito_specs/[feature]_notifier_spec.dart` (input)
- **Generated mocks**: `test/mocks/mockito_specs/[feature]_notifier_spec.mocks.dart` (auto-generated)
- **Final location**: `test/mocks/[feature]_notifier_mocks.dart` (moved manually)

**Step 5.1**: Create Mock Specification File

Create `test/mocks/mockito_specs/[feature]_notifier_spec.dart`:

```dart
@GenerateMocks([
  [FeatureAuth]Notifier,  // e.g., DiagnosticAuthNotifier
  [Feature]Notifier,      // e.g., CsDiagnosticNotifier
])
import 'package:mockito/annotations.dart';
import 'package:privacy_gui/page/[feature]/providers/[feature]_auth_provider.dart';
import 'package:privacy_gui/page/[feature]/providers/[feature]_provider.dart';
```

**Important**: Use `@GenerateMocks` (NOT `@GenerateNiceMocks`) for Riverpod Notifiers as they require proper inheritance.

**Step 5.2**: Generate mock files using build_runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 5.3**: Move generated file to correct location:

```bash
mv test/mocks/mockito_specs/[feature]_notifier_spec.mocks.dart test/mocks/[feature]_notifier_mocks.dart
```

**Step 5.4**: **CRITICAL** - Fix Mock Class Signatures

The generated mocks will have incorrect signatures. You must manually edit the mock file to fix class inheritance:

```dart
// ❌ Generated (Incorrect):
class Mock[Feature]Notifier extends _i1.Mock
    implements _i3.[Feature]Notifier {

// ✅ Required (Correct):
class Mock[Feature]Notifier extends _i2.Notifier<_i3.[Feature]State>
    with _i1.Mock
    implements _i3.[Feature]Notifier {
```

**Example fixes**:
```dart
// Fix AuthNotifier class signature:
class MockDiagnosticAuthNotifier extends _i2.Notifier<_i3.DiagnosticAuthState>
    with _i1.Mock
    implements _i3.DiagnosticAuthNotifier {

// Fix main feature Notifier class signature:
class MockCsDiagnosticNotifier extends _i2.Notifier<_i4.CsDiagnosticState>
    with _i1.Mock
    implements _i6.CsDiagnosticNotifier {
```

**Why this manual fix is required**:
- Riverpod Notifiers require specific inheritance: `extends Notifier<State> with Mock implements NotifierClass`
- `build_runner` generates simpler `extends Mock implements NotifierClass`
- Without proper inheritance, tests will fail with `_setElement` method errors

### 6. Update Mock Index File

Add the new mock to `test/mocks/_index.dart`:
```dart
export '[feature]_notifier_mocks.dart';
```

### 7. Create Test Data

Create `test/page/[feature-name]/views/localizations/[feature]_test_data.dart`:

```dart
import 'package:privacy_gui/page/[feature]/providers/[feature]_state.dart';
import 'package:privacy_gui/page/[feature]/models/[model].dart';

// Normal state test data
const [feature]LoadedState = [FeatureState](
  loadState: [LoadState].loaded,
  // ... set various normal state properties
);

// Error or special state test data
const [feature]ErrorState = [FeatureState](
  loadState: [LoadState].error,
  errorMessage: 'Test error message',
  // ... set error state properties
);
```

## Test File Implementation

### 8. Main Test File Structure

Create `test/page/[feature-name]/views/localizations/[feature]_views_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/[feature]/providers/[providers].dart';
import 'package:privacy_gui/page/[feature]/views/[views].dart';

import '../../../../common/config.dart';
import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/_index.dart';
import '[feature]_test_data.dart';

void main() async {
  late Mock[Feature]Notifier mock[Feature]Notifier;
  // Other required mock notifiers...

  mockDependencyRegister();

  List<Override> overrideRegister() {
    return [
      [feature]Provider.overrideWith(() => mock[Feature]Notifier),
      // Other provider overrides...
    ];
  }

  setUp(() {
    mock[Feature]Notifier = Mock[Feature]Notifier();
    // Initialize other mock objects...
  });

  group('[Feature] Views - [TestGroup]', () {
    setUp(() {
      // Mock authentication state (if applicable)
      when(mock[Auth]Notifier.build()).thenReturn(
        const [Auth]State(status: [Auth]Status.authenticated),
      );
      when(mock[Auth]Notifier.logout()).thenReturn(null);
      
      // Mock main notifier state and methods
      when(mock[Feature]Notifier.build()).thenReturn([defaultTestState]);
      
      // **CRITICAL**: Mock all methods that might be called by the widget
      when(mock[Feature]Notifier.fetch()).thenAnswer((_) async {});
      when(mock[Feature]Notifier.toggleDegraded()).thenReturn(null);
      when(mock[Feature]Notifier.toggleMock()).thenReturn(null);
      when(mock[Feature]Notifier.useMock).thenReturn(false);
      when(mock[Feature]Notifier.useDegraded).thenReturn(false);
    });

    testLocalizations('[TestName] - [State]',
        (tester, locale) async {
      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const [ViewWidget](),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: [height])).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: [height])).toList()
    ]); // testLocalizations automatically adds 'loc' tag

    // Special case: Loading State Test
    testLocalizations('[TestName] - Loading State',
        (tester, locale) async {
      // Override state for this specific test
      when(mock[Feature]Notifier.build()).thenReturn(
        const [Feature]State(loadState: [LoadState].loading),
      );
      when(mock[Feature]Notifier.fetch()).thenAnswer((_) async {});

      await tester.pumpWidget(
        testableRouteShellWidget(
          child: const [ViewWidget](),
          locale: locale,
          overrides: overrideRegister(),
        ),
      );
      // Use pump() instead of pumpAndSettle() for loading states
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }, screens: [...]);
  });
}
```

### 9. Test Coverage Planning

Create tests for each main View and state:
- **Loading States** - Display loading indicators
- **Normal States** - Standard feature display
- **Error States** - Error messages and handling
- **Special States** - Feature-specific states (degraded, offline, etc.)
- **Interactive States** - modal, dialog, hover states

## Execution and Validation

### 10. Generate Mock Files (if needed)

**IMPORTANT**: Mock generation requires a **Mock Spec File** and is a multi-step process for Riverpod Notifiers:

**Prerequisites**: Ensure you have created the Mock Specification file (Step 5.1):
- `test/mocks/mockito_specs/[feature]_notifier_spec.dart` must exist
- It must contain `@GenerateMocks([...])` annotations
- It must import the classes you want to mock

```bash
# Step 1: Generate mocks from spec file
dart run build_runner build --delete-conflicting-outputs

# Step 2: Move generated file to correct location
mv test/mocks/mockito_specs/[feature]_notifier_spec.mocks.dart test/mocks/[feature]_notifier_mocks.dart

# Step 3: Manually fix mock class signatures (CRITICAL!)
# Edit the moved file to change class inheritance as shown in Step 5.4
```

**You must complete all 3 steps** or tests will fail with `_setElement` errors.

**Note**: The spec file (`.dart`) stays in `mockito_specs/`, only the generated mock file (`.mocks.dart`) gets moved.

### 11. Generate Golden Files Using Project Script

**Recommended Method**: Use the project's built-in script for the most complete execution:

```bash
# Generate golden files for specific test file
./run_generate_loc_snapshots.sh -f test/page/[feature-name]/views/localizations/[feature]_views_test.dart -l "en,zh,ja" -s "480,1280"

# Parameter descriptions:
# -f: Specify test file
# -l: Specify language list (comma-separated)  
# -s: Specify screen size list (comma-separated)
# -v: Specify version number (optional)
# -c: Copy mode instead of move (optional)
```

**Alternative Method**: Direct flutter test command:
```bash
flutter test test/page/[feature-name]/views/localizations/[feature]_views_test.dart --update-goldens --tags=loc --dart-define=locales="en,zh" --dart-define=screens="480,1280"
```

### 12. Script Execution Flow

The `run_generate_loc_snapshots.sh` script will:
1. Create `snapshots/` directory to collect results
2. Execute tests in language batches to avoid memory issues
3. Use `--tags=loc` tag for localization tests
4. Collect all files from `goldens/` directories to `snapshots/`
5. Execute post-processing scripts for result analysis

### 13. Verify Test Execution

After test generation is complete, verify normal operation:
```bash
flutter test test/page/[feature-name]/views/localizations/[feature]_views_test.dart --tags=loc
```

### 14. Check Generated Results

- Confirm `test/page/[feature-name]/views/localizations/goldens/` directory is auto-created
- Check all golden files collected in `snapshots/` directory
- File naming format: `[TestName]-[DeviceSize]-[Locale].png`
- Confirm coverage of specified language and device size combinations

## Best Practices

### Execution Method Selection
**Strongly recommend using the `run_generate_loc_snapshots.sh` script** because it provides:
- Memory management: Execute languages in batches to avoid OOM
- Result collection: Automatically organize all golden files
- Standardized process: Ensure all tests use the same parameters
- Post-processing: Automatically execute analysis and organization scripts

### Test Naming Conventions
- Use descriptive test names: `'[Component] - [State] - [Condition]'`
- Use consistent naming patterns for easy identification

### Screen Size Configuration
- Mobile: `480w`, `744w` 
- Desktop: `1080w`, `1280w`, `1440w`
- Script defaults: `480,1280` (covers main sizes)
- Adjust height based on content, typically:
  - Simple pages: 800px
  - Complex pages: 1200px-1400px

### Language Configuration
- Development phase: Use `en` or `en,zh` for quick verification
- Complete testing: Use `en,zh,ja` or more languages
- Script default: `en` (minimal test set)

### Mock Data Quality
- Use realistic data structures
- Include edge cases and error states
- Ensure data consistency and repeatability

### State Management
- Set clear initial state for each test group
- Use `when().thenReturn()` to explicitly specify mock behavior
- Avoid state leakage between tests

## Maintenance and Updates

### Golden Files Updates
When UI has intentional changes, **recommend using the script**:
```bash
# Update using script (recommended)
./run_generate_loc_snapshots.sh -f test/page/[feature-name]/views/localizations/[feature]_views_test.dart -l "en,zh" -s "480,1280"

# Or directly use flutter test (basic usage)
flutter test [test-file] --update-goldens --tags=loc
```

### Test Extension
- Add corresponding test cases promptly when adding new features
- Regularly check test coverage
- Consider adding interactive tests (tap, scroll, etc.)

### CI/CD Integration
Ensure CI pipeline includes golden testing:
```yaml
- name: Run Golden Tests
  run: flutter test --tags=loc

# Or use project script (if CI environment supports)
- name: Generate Screenshots
  run: ./run_generate_loc_snapshots.sh -l "en" -s "480,1280"
```

## Troubleshooting

### Common Issues

1. **Missing Mock Specification File**
   ```
   Error: No .dart files found for build_runner to generate from
   ```
   **Root Cause**: Mock spec file doesn't exist or is in wrong location
   
   **Solution**: 
   - Ensure `test/mocks/mockito_specs/[feature]_notifier_spec.dart` exists
   - Check file contains `@GenerateMocks([...])` annotations
   - Verify imports point to correct provider files
   - Example correct spec file:
   ```dart
   @GenerateMocks([DiagnosticAuthNotifier, CsDiagnosticNotifier])
   import 'package:mockito/annotations.dart';
   import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_auth_provider.dart';
   import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_provider.dart';
   ```

2. **Mock Class `_setElement` Method Error**
   ```
   Class 'MockXXXNotifier' has no instance method '_setElement'.
   ```
   **Root Cause**: Generated mock doesn't properly extend `Notifier<State>`
   
   **Solution**: 
   - Use `@GenerateMocks` (not `@GenerateNiceMocks`) in spec file
   - Manually fix class signatures after generation:
   ```dart
   // Change from:
   class MockFeatureNotifier extends _i1.Mock implements _i3.FeatureNotifier {
   
   // To:
   class MockFeatureNotifier extends _i2.Notifier<_i3.FeatureState>
       with _i1.Mock
       implements _i3.FeatureNotifier {
   ```

2. **`pumpAndSettle timed out` Error**
   **Root Cause**: Widget calls async methods (like `fetch()`) that aren't mocked
   
   **Solution**:
   - Mock all methods that widgets might call:
   ```dart
   when(mockNotifier.fetch()).thenAnswer((_) async {});
   when(mockNotifier.toggleMock()).thenReturn(null);
   when(mockNotifier.useMock).thenReturn(false);
   ```
   - For loading states, use `pump()` instead of `pumpAndSettle()`:
   ```dart
   await tester.pump();
   await tester.pump(const Duration(milliseconds: 100));
   ```

3. **Mock Class Signature Errors**
   - Ensure it extends `Notifier<StateClass>`
   - Mix in `Mock`
   - Implement the correct interface

4. **Test Execution Failures**
   - Check import statements
   - Confirm mock dependencies are registered
   - Verify test data correctness
   - Ensure all widget methods are mocked

5. **Golden Files Differences**
   - Font rendering differences: Confirm using test-specific fonts
   - Time-related content: Use fixed test data
   - Animation states: Ensure `pumpAndSettle()` completes

6. **Script Execution Issues**
   - Confirm script has execution permissions: `chmod +x run_generate_loc_snapshots.sh`
   - Check if helper scripts in `test_scripts/` directory exist
   - Memory insufficient: Reduce number of languages tested simultaneously
   - Result collection: Confirm `snapshots/` directory generates correctly

### Debugging Tips

**Mock Debugging**:
- Add `print()` statements in mock methods to verify they're being called
- Use `verify(mock.method()).called(times)` to check mock invocation count
- Check mock class signatures match expected inheritance patterns

**Test State Debugging**:
- Use `tester.pump()` instead of `pumpAndSettle()` to capture loading states
- Add debug output to understand widget lifecycle:
```dart
await tester.pumpWidget(...);
print('After pumpWidget: ${find.byType(YourWidget).evaluate()}');
await tester.pump();
print('After pump: ${find.byType(CircularProgressIndicator).evaluate()}');
```

**Mock Verification**:
```dart
// Check if mock methods are properly configured
setUp(() {
  when(mockNotifier.build()).thenReturn(testState);
  when(mockNotifier.fetch()).thenAnswer((_) async {});
  
  // Verify mock setup
  expect(mockNotifier.build(), equals(testState));
});
```

**Golden File Debugging**:
- Check actual golden file content to understand differences
- Use `flutter test --update-goldens` to regenerate single test
- Compare golden files in image viewer to spot UI changes

## Reference Examples

### Complete Implementation Examples

**Mock Specification Files**:
- `test/mocks/mockito_specs/cs_diagnostic_notifier_spec.dart` - Mock spec for CS Diagnostic
- `test/mocks/mockito_specs/dashboard_home_notifier_spec.dart` - Mock spec for Dashboard Home

**Generated Mock Files**:
- `test/mocks/cs_diagnostic_notifier_mocks.dart` - Final mock location
- `test/mocks/dashboard_home_notifier_mocks.dart` - Final mock location

**Test Files**:
- `test/page/cs_diagnostic/views/localizations/cs_diagnostic_views_test.dart` - Complete test implementation
- `test/page/dashboard/localizations/dashboard_home_view_test.dart` - Reference test implementation

### Script Usage Examples

```bash
# Development phase: Quick verification with single language
./run_generate_loc_snapshots.sh -f test/page/cs_diagnostic/views/localizations/cs_diagnostic_views_test.dart -l "en" -s "480"

# Complete testing: Multiple languages and sizes
./run_generate_loc_snapshots.sh -f test/page/cs_diagnostic/views/localizations/cs_diagnostic_views_test.dart -l "en,zh,ja" -s "480,1280" -v "1.0.0"

# Batch update all tests (without -f parameter)
./run_generate_loc_snapshots.sh -l "en,zh" -s "480,1280"
```

### Helper Tools
The project includes the following helper scripts (automatically called by `run_generate_loc_snapshots.sh`):
- `test_scripts/test_result_parser.dart` - Parse test results
- `test_scripts/combine_results.dart` - Combine result files
- `test_scripts/grep_loc_fils.dart` - Localization file processing

---

This workflow ensures consistent quality and maintainability for new feature screenshot testing. Using the project's built-in script significantly simplifies the execution process and avoids common issues.