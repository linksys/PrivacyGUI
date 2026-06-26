# Screenshot Testing Guide

## 1. Commands

```bash
# Run all screenshot tests
sh run_generate_loc_snapshots.sh -c true

# Run a single test file
sh run_generate_loc_snapshots.sh -c true -f test/path/to/test.dart

# Parameters
# -l : locale (default: en)
# -s : screen sizes (default: 480,1280)
# -f : target single test file
# -c : true = copy instead of move screenshots
# -v : version number
```

## 2. Mock File Workflow

### 2.1 Directory Structure

```
test/mocks/
├── mockito_specs/          # Mockito spec files + auto-generated .mocks.dart
│   ├── wifi_list_notifier_spec.dart
│   └── wifi_list_notifier_spec.mocks.dart  (auto-generated)
└── wifi_list_notifier_mocks.dart           # Final mock file (manually moved + modified)
```

### 2.2 Generate Mocks

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 2.3 ⚠️ Important: Notifier/Provider Mock Signature Modification

When moving from `mockito_specs/` to `mocks/`, **Notifier-type mocks must have their class signature modified**:

```dart
// ❌ Original generated (mockito_specs/*.mocks.dart)
class MockWifiListNotifier extends _i1.Mock implements _i4.WifiListNotifier {

// ✅ Modified (mocks/*_mocks.dart)
class MockWifiListNotifier extends _i2.Notifier<_i3.WiFiState> 
    with _i1.Mock implements _i4.WifiListNotifier {
```

**Modification Steps**:
1. Change `extends _i1.Mock` to `extends _i2.Notifier<StateType>`
2. Add `with _i1.Mock`
3. Keep the `implements` clause
4. Verify import aliases (`_i2`, `_i3`, etc.) map to correct packages

**Reason**: Riverpod's Notifier requires the correct inheritance chain to work properly in tests.

### 2.4 Non-Notifier Type Mocks

Regular classes (e.g., `ServiceHelper`) don't need signature modification - just move the file directly.

## 3. Common Errors & Solutions

### 3.1 `type 'Null' is not a subtype of type 'X' in type cast`

**Cause**: Test data missing required fields

**Solution**: Check the corresponding `fromMap()` method and add missing fields to test data

**Examples**:
```dart
// WiFiState.fromMap() requires simpleModeWifi field
// NodeDetailState.fromMap() requires macAddress field
```

### 3.2 `Bad state: Cannot call 'when' within a stub response`

**Cause**: Previous test's `when()` failed with an exception, leaving Mockito in an inconsistent state

**Solution**: Fix the first failing test (usually a data parsing issue) - subsequent tests will recover automatically

### 3.3 `Bad state: No element`

**Cause**: Test cannot find expected UI element

**Common Scenarios**:
- `isSimpleMode` set incorrectly, causing wrong View to display (SimpleModeView vs AdvancedModeView)
- `semanticLabel` mismatch

**Solution**: Verify test data's `isSimpleMode` value matches test expectations

### 3.4 Mock Method Returns Null

**Cause**: Mock class doesn't include newly added methods

**Solution**:
1. Re-run `dart run build_runner build`
2. Move new mock from `mockito_specs/` to `mocks/`
3. If it's a Notifier type, remember to modify the signature

## 4. Test Data Locations

```
test/test_data/
├── _index.dart                              # Exports all test data
├── wifi_list_test_state.dart                # WiFi list test data
├── wifi_advanced_settings_test_state.dart   # WiFi advanced settings test data
├── node_details_data.dart                   # Node details test data
├── dashboard_home_test_state.dart           # Dashboard test data
└── ...
```

## 5. New Test Case Checklist

- [ ] Verify test data contains all required fields
- [ ] Verify Mock class includes all needed methods
- [ ] If Notifier mock, confirm signature is correctly modified
- [ ] Run single test file to confirm pass
- [ ] Run all tests to confirm no regression
