# Quick Start: Firewall Refactor Implementation

**Reference**: This is a companion to `plan.md` and `data-model.md`. Use this for quick implementation guidance.

---

## 30-Second Overview

**Goal**: Extract JNAP logic from Provider into Service layer, introduce UI models, implement three-layer testing

**Pattern**: Copy DMZ refactor (002) or Administration refactor (001)

**Files to Create**:
1. `FirewallSettingsService` (Service layer)
2. `FirewallSettingsTestData` (Test helpers)
3. Comprehensive tests (Service, Provider, State)

**Files to Modify**:
1. `FirewallNotifier` - remove JNAP, delegate to Service
2. `firewall_state.dart` - add FirewallUISettings, IPv6PortServiceRuleUI

**Verification**:
```bash
grep -r "import.*jnap/models" lib/page/advanced_settings/firewall/
# Should return 0 results
```

---

## Implementation Checklist

### Phase A: Create Service Layer

- [ ] Create `lib/page/advanced_settings/firewall/services/firewall_settings_service.dart`
- [ ] Implement `fetchFirewallSettings()` method
- [ ] Implement `saveFirewallSettings()` method
- [ ] Add private transformation methods (`_parseLANSettings()`, `_parseFirewallSettings()`, etc.)
- [ ] Add comprehensive DartDoc comments
- [ ] Create `firewall_settings_service_test_data.dart` for mock data builders

**Key Pattern**:
```dart
class FirewallSettingsService {
  /// Fetch firewall settings and transform to UI models
  Future<(FirewallUISettings?, EmptyStatus?)> fetchFirewallSettings(
    Ref ref,
    {bool forceRemote = false},
  ) async {
    final repo = ref.read(routerRepositoryProvider);
    // Call repository
    // Transform JNAP → Data models → UI models
    // Return UI models only
  }
}
```

### Phase B: Create UI Models

- [ ] Add `FirewallUISettings` class to `firewall_state.dart`
- [ ] Add `IPv6PortServiceRuleUI` class to `ipv6_port_service_rule_state.dart`
- [ ] Implement `Equatable`, `copyWith()`, serialization
- [ ] Add DartDoc comments

**Key Pattern** (from firewall_state.dart):
```dart
/// UI model for firewall settings - bridges Data layer and Presentation layer
class FirewallUISettings extends Equatable {
  final bool blockAnonymousRequests;
  // ... other fields

  const FirewallUISettings({required this.blockAnonymousRequests, ...});

  @override
  List<Object> get props => [blockAnonymousRequests, ...];

  FirewallUISettings copyWith({...}) { ... }

  // Serialization for tests
  Map<String, dynamic> toMap() { ... }
  factory FirewallUISettings.fromMap(Map<String, dynamic> map) { ... }
}
```

### Phase C: Refactor Provider

- [ ] Update `FirewallNotifier.performFetch()` - call Service instead of Repository
- [ ] Update `FirewallNotifier.performSave()` - call Service instead of Repository
- [ ] Update `FirewallState` to use `FirewallUISettings` instead of `FirewallSettings`
- [ ] Remove all JNAP imports from Provider file
- [ ] Add new Service import
- [ ] Verify no remaining JNAP references

**Key Change**:
```dart
// BEFORE:
@override
Future<(FirewallSettings?, EmptyStatus?)> performFetch(...) {
  final result = await ref.read(routerRepositoryProvider).send(...);
  return (FirewallSettings.fromMap(result.output), ...);
}

// AFTER:
@override
Future<(FirewallUISettings?, EmptyStatus?)> performFetch(...) {
  final service = FirewallSettingsService();
  return await service.fetchFirewallSettings(ref);
}
```

### Phase D: Write Service Layer Tests

- [ ] Create `test/page/advanced_settings/firewall/services/firewall_settings_service_test.dart`
- [ ] Test `fetchFirewallSettings()` with mock JNAP response
- [ ] Test transformation of JNAP → UI models
- [ ] Test error cases (null values, invalid data, API failure)
- [ ] Test edge cases (empty lists, special characters, boundary values)
- [ ] Target: ≥90% coverage

**Key Test Pattern**:
```dart
test('transforms JNAP response to UI model', () async {
  final mockRef = setupMockRef();
  final mockResponse = FirewallSettingsTestData.createSuccessfulResponse();

  when(() => mockRepository.send(...))
      .thenAnswer((_) async => mockResponse);

  final service = FirewallSettingsService();
  final (settings, status) = await service.fetchFirewallSettings(mockRef);

  expect(settings?.blockAnonymousRequests, true);
  expect(settings?.isIPv4FirewallEnabled, false);
});
```

### Phase E: Write Provider Tests

- [ ] Create `test/page/advanced_settings/firewall/providers/firewall_provider_test.dart`
- [ ] Test Provider delegates to Service
- [ ] Test state updates on success
- [ ] Test error propagation
- [ ] Target: ≥85% coverage

### Phase F: Write State Model Tests

- [ ] Create `test/page/advanced_settings/firewall/providers/firewall_state_test.dart`
- [ ] Test construction with all fields
- [ ] Test copyWith() creates new instances
- [ ] Test Equatable equality (⚠️ often forgotten)
- [ ] Test serialization/deserialization (⚠️ most often forgotten)
- [ ] Test round-trip: object → toMap() → fromMap() → equals original
- [ ] Target: ≥90% coverage

**Critical Serialization Tests**:
```dart
test('round-trip serialization preserves equality', () {
  const original = FirewallUISettings(...);
  final map = original.toMap();
  final restored = FirewallUISettings.fromMap(map);

  expect(restored, equals(original));
});
```

### Phase G: Refactor IPv6 Port Service Rules

- [ ] Repeat Phases A-F for IPv6 port service rules
- [ ] Create `IPv6PortServiceRuleUI` model
- [ ] Create service for port rule operations
- [ ] Update IPv6PortServiceRuleNotifier
- [ ] Write comprehensive tests

### Phase H: Verification & Cleanup

- [ ] Run all tests: `flutter test test/page/advanced_settings/firewall/`
- [ ] Check coverage: `flutter test --coverage`
- [ ] Verify no JNAP imports in Provider: `grep -r "import.*jnap/models" lib/page/advanced_settings/firewall/providers/`
- [ ] Verify no JNAP imports in Views: `grep -r "import.*jnap/models" lib/page/advanced_settings/firewall/views/`
- [ ] Run lint: `flutter analyze lib/page/advanced_settings/firewall/`
- [ ] Run format: `dart format lib/page/advanced_settings/firewall/ test/page/advanced_settings/firewall/`
- [ ] Verify screenshot tests use UI models: `grep -n "DMZSourceRestriction\|IPv6PortServiceRule\|FirewallSettings" test/page/advanced_settings/firewall/views/`

---

## Key Architectural Decisions

| Decision | Why | Do This |
|----------|-----|---------|
| UI models in Application layer | Decouple Presentation from Protocol | Create UI model classes in `providers/` folder |
| Service handles transformation | Single responsibility | All Data→UI and UI→Data logic in Service only |
| Provider delegates to Service | Clear dependency flow | Provider methods call Service methods |
| ≥90% Service coverage | Transformation logic is critical | Test all paths, edge cases, error scenarios |
| Test with UI models only | Enforce architecture | View/Provider tests import UI models, never JNAP models |

---

## Common Pitfalls to Avoid

❌ **Mistake 1**: Leaving JNAP imports in Provider
```dart
// ❌ WRONG
import 'package:privacy_gui/core/jnap/models/firewall_settings.dart';
```
✅ **Fix**: Remove - use UI models instead

---

❌ **Mistake 2**: Hardcoding transformations in Provider
```dart
// ❌ WRONG - in Provider
final jnapSettings = FirewallSettings.fromMap(response);
final uiSettings = FirewallUISettings(...);
```
✅ **Fix**: Move to Service layer

---

❌ **Mistake 3**: Forgetting serialization tests
```dart
// ❌ WRONG - State tests missing toMap/fromMap verification
test('constructs with all fields', () { ... });
// No serialization test!
```
✅ **Fix**: Add round-trip serialization tests

---

❌ **Mistake 4**: Using JNAP models in View tests
```dart
// ❌ WRONG - View test using Data model
const settings = DMZUISettings(
  sourceRestriction: DMZSourceRestriction(...),  // Wrong model!
);
```
✅ **Fix**: Use UI model (DMZSourceRestrictionUI)

---

## File Modification Reference

### Files to CREATE

```
lib/page/advanced_settings/firewall/services/
├── firewall_settings_service.dart              [NEW]
└── firewall_settings_service_test_data.dart    [NEW]

test/page/advanced_settings/firewall/services/
├── firewall_settings_service_test.dart         [NEW]
└── firewall_settings_service_test_data.dart    [NEW]

test/page/advanced_settings/firewall/providers/
├── firewall_provider_test.dart                 [NEW]
├── firewall_state_test.dart                    [NEW]
├── ipv6_port_service_rule_provider_test.dart   [NEW]
├── ipv6_port_service_rule_state_test.dart      [NEW]
└── ... (other state tests as needed)
```

### Files to MODIFY

```
lib/page/advanced_settings/firewall/
├── providers/firewall_provider.dart            [REFACTOR]
├── providers/firewall_state.dart               [ADD UI MODELS]
├── providers/ipv6_port_service_rule_provider.dart [REFACTOR]
└── providers/ipv6_port_service_rule_state.dart    [ADD UI MODELS]
```

### Files to VERIFY (no changes needed)

```
lib/page/advanced_settings/firewall/views/*.dart
- Verify: No new JNAP imports
- Verify: Uses only UI models
```

---

## Testing Commands

```bash
# Run all firewall tests
flutter test test/page/advanced_settings/firewall/

# Run specific test file
flutter test test/page/advanced_settings/firewall/services/firewall_settings_service_test.dart

# Check coverage
flutter test --coverage
lcov --list coverage/lcov.info | grep firewall

# Verify architecture
grep -r "import.*jnap/models" lib/page/advanced_settings/firewall/providers/
grep -r "import.*jnap/models" lib/page/advanced_settings/firewall/views/

# Format and analyze
dart format lib/page/advanced_settings/firewall/
flutter analyze lib/page/advanced_settings/firewall/
```

---

## Success Criteria

✅ **Implementation is complete when**:

1. All tests pass: `flutter test test/page/advanced_settings/firewall/`
2. Coverage meets targets: Service ≥90%, Provider ≥85%, State ≥90%
3. No JNAP imports in Provider: `grep -r "import.*jnap/models" lib/page/advanced_settings/firewall/providers/` returns 0
4. No JNAP imports in Views: `grep -r "import.*jnap/models" lib/page/advanced_settings/firewall/views/` returns 0
5. Lint passes: `flutter analyze lib/page/advanced_settings/firewall/` shows 0 warnings
6. Format passes: `dart format lib/page/advanced_settings/firewall/` makes no changes
7. All UI models used consistently: View tests import only UI models
8. Documentation complete: All public APIs have DartDoc

---

## Next Steps

1. **Review this quickstart** with the team
2. **Run `/speckit.tasks`** to generate detailed task list
3. **Begin Phase A** (Create Service Layer)
4. **Follow task list** from `/speckit.tasks` output
