# DMZ Settings Refactor - Architecture Decision

**Date**: 2025-12-08
**Decision**: Implement strict model separation between layers

## Problem

Initial implementation had Provider layer directly using Data models from `core/jnap/models/`:
- Provider imported `DMZSettings` and `DMZSourceRestriction` from JNAP layer
- This violated the three-layer architecture principle

## Solution

Implement separate UI models in the Application layer to act as an adapter between layers.

## Architecture Layers & Models

```
┌─────────────────────────────────────────────────────────────┐
│ Data Layer (core/jnap/models/)                              │
│ - DMZSettings (JNAP domain model)                           │
│ - DMZSourceRestriction (JNAP domain model)                  │
│ - DMZSettings.toMap() / fromMap() for JNAP protocol        │
└────────────────────┬────────────────────────────────────────┘
                     │ Only Service knows about these
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ Service Layer (dmz/services/)                               │
│ - DMZSettingsService                                         │
│ - Converts Data models ↔ UI models                          │
│ - All JNAP protocol handling                                │
└────────────────────┬────────────────────────────────────────┘
                     │ Service returns only UI models
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ Application Layer (dmz/providers/)                          │
│ - DMZUISettings (UI-specific model)                         │
│ - DMZSourceRestrictionUI (UI-specific model)                │
│ - DMZSettingsState (Riverpod state)                         │
│ - DMZSettingsNotifier (State management)                    │
└────────────────────┬────────────────────────────────────────┘
                     │ Only UI models exposed
                     ↓
┌─────────────────────────────────────────────────────────────┐
│ Presentation Layer (dmz/views/)                             │
│ - DMZSettingsView                                            │
│ - Only knows about UI models                                │
└─────────────────────────────────────────────────────────────┘
```

## Key Principles

### 1. Provider Layer Purity
- **Provider imports**: ONLY from `dmz/providers/`, `dmz/services/`, Riverpod
- **NO imports**: `core/jnap/`, `core/models/`
- **NO direct access**: JNAP protocol details, data models

### 2. Service Layer Translation
The Service layer is the **only** place where Data models and UI models meet:

```dart
// In Service layer: Convert Data → UI
DMZUISettings _parseDMZSettings(JNAPSuccess result) {
  final dmzSettings = jnap_models.DMZSettings.fromMap(output);  // Data model
  final sourceRestrictionUI = DMZSourceRestrictionUI(  // UI model
    firstIPAddress: dmzSettings.sourceRestriction!.firstIPAddress,
    lastIPAddress: dmzSettings.sourceRestriction!.lastIPAddress,
  );
  // Return only UI models to Provider
  return DMZUISettings(sourceRestriction: sourceRestrictionUI, ...);
}

// In Service layer: Convert UI → Data
Future<void> saveDmzSettings(Ref ref, DMZUISettings settings) async {
  final sourceRestrictionData = jnap_models.DMZSourceRestriction(
    firstIPAddress: settings.sourceRestriction!.firstIPAddress,
    lastIPAddress: settings.sourceRestriction!.lastIPAddress,
  );
  final domainSettings = jnap_models.DMZSettings(
    sourceRestriction: sourceRestrictionData, ...
  );
  // Send Data model to JNAP
}
```

### 3. UI Model Structure
All UI models inherit from the Application layer (`dmz/providers/dmz_settings_state.dart`):
- `DMZSourceRestrictionUI` - Mirrors `DMZSourceRestriction` but for Application layer
- `DMZUISettings` - Uses UI models, NOT data models
- Never serialized from JNAP directly; always converted by Service

## Benefits

1. **Clear Separation**: Each layer has distinct responsibilities
2. **Testability**: Provider tests don't need to know about JNAP
3. **Maintainability**: Adding new JNAP fields doesn't affect Provider
4. **Security**: UI layer can't accidentally misuse protocol-level models
5. **Reusability**: Service layer can be mocked independently

## Trade-offs

- **Minimal overhead**: Extra model classes and conversion logic
- **Worth it**: Prevents architectural drift and ensures clean boundaries

## Affected Files

- ✅ `lib/page/advanced_settings/dmz/providers/dmz_settings_state.dart` - Added `DMZSourceRestrictionUI`
- ✅ `lib/page/advanced_settings/dmz/providers/dmz_settings_provider.dart` - Removed JNAP imports
- ✅ `lib/page/advanced_settings/dmz/services/dmz_settings_service.dart` - Added model conversions
- ✅ `test/page/advanced_settings/dmz/services/dmz_settings_service_test.dart` - Uses UI models

## Verification

Run this command to verify Provider layer has no JNAP references:
```bash
grep -E "import.*core|DMZSettings[^UI]|DMZSourceRestriction[^UI]" \
  lib/page/advanced_settings/dmz/providers/dmz_settings_provider.dart
# Should return: 0 results (no JNAP references)
```
