# Mascot Health System

## Overview

The Mascot Health System provides a visual dashboard showing the overall health of the router system. It consists of:

1. **Health Status View** — Problem-first display highlighting issues at top, healthy items as chips
2. **Toolbar** — Quick access to utilities (print, theme, FAQ, AI Assistant)
3. **Health Evaluation** — Extensible dimension scoring with 6 built-in dimensions
4. **Event Triggers** — SSE-driven proactive notifications

## Architecture

```
lib/page/dashboard/mascot/
├── mascot_config.dart           # Centralized configuration
├── mascot_providers.dart        # Coordinator + trigger integration
├── health_dialog_provider.dart  # Health dashboard dialog UI
│
├── health/
│   ├── health_dimension.dart         # Abstract interface + models
│   ├── health_score.dart             # Score model + HealthTier
│   ├── health_dimension_registry.dart # Static registry (HealthDimensions)
│   ├── system_health_provider.dart   # Aggregated health state
│   └── dimensions/                   # 6 built-in dimensions
│       ├── internet_dimension.dart
│       ├── wifi_dimension.dart
│       ├── devices_dimension.dart
│       ├── security_dimension.dart
│       ├── system_dimension.dart
│       └── firmware_dimension.dart
│
├── triggers/
│   ├── mascot_trigger.dart           # Trigger model + cooldown
│   ├── trigger_definitions.dart      # 9 predefined triggers
│   └── mascot_trigger_provider.dart  # SSE listener + state detection
│
└── widgets/
    ├── health_status_view.dart        # Problem-first health display
    ├── dimension_detail_view.dart     # Dimension detail with actions
    ├── dimension_tooltip_content.dart # Tooltip summary
    ├── dimension_actions_builder.dart # Action list builder
    └── mascot_toolbar.dart            # Utility toolbar
```

## Health Dimensions

| Dimension | What it evaluates | Score mapping |
|-----------|------------------|---------------|
| Internet | WAN up/down | 100 (up) / 0 (down) |
| WiFi | Radio enable status | 100 (all on) / 80 (some off) / 0 (all off) |
| Devices | Online device ratio | 100 (all) / 80 (>80%) / 60 (>50%) / 40 (>20%) / 20 |
| Security | Firewall + DMZ | 100 (FW on, no DMZ) / 80 (FW on, DMZ) / 20 (FW off) |
| System | CPU/Memory usage | 100 (<50%) / 80 (<70%) / 60 (<85%) / 40 (<95%) / 20 |
| Firmware | Update availability | 100 (none) / 60 (available) |

### Adding a New Dimension

1. Create `lib/page/dashboard/mascot/health/dimensions/my_dimension.dart`:

```dart
class MyHealthDimension extends HealthDimension {
  @override
  HealthDimensionType get type => HealthDimensionType.myDimension;

  @override
  String get displayName => 'My Dimension';

  @override
  IconData get icon => Icons.my_icon;

  @override
  Set<InvalidationDomain> get watchedDomains => {
    InvalidationDomain.myDomain,
  };

  @override
  int evaluate(HealthEvaluationContext context) {
    // Return 0-100 score
    return 100;
  }

  @override
  DimensionSummary getSummary(HealthEvaluationContext context) {
    return DimensionSummary(
      status: 'Healthy',
      items: [SummaryItem('Key', 'Value')],
      hint: 'Tap for actions',
    );
  }

  @override
  List<HealthAction> getActions(BuildContext context) {
    return [
      HealthAction(
        id: 'my_action',
        label: 'My Action',
        icon: Icons.settings,
        routeName: RouteNamed.myRoute,
      ),
    ];
  }
}
```

2. Add enum value to `HealthDimensionType` in `health_dimension.dart`
3. Add data to `HealthEvaluationContext` if needed
4. Register in `HealthDimensionRegistry`

## Event Triggers

### Predefined Triggers

| Trigger | Priority | Cooldown | Interrupt |
|---------|----------|----------|-----------|
| WAN Down | Critical | 5 min | Yes |
| WAN Restored | High | 1 min | No |
| New Device | Medium | 30 sec | No |
| CPU High | High | 10 min | No |
| Memory High | High | 10 min | No |
| Firmware Available | Low | 24 hr | No |
| WiFi Disabled | Medium | 5 min | No |
| Firewall Disabled | High | 30 min | Yes |
| DMZ Enabled | Medium | 1 hr | No |

### Adding a New Trigger

1. Add factory method in `trigger_definitions.dart`:

```dart
static MascotTrigger myTrigger() => const MascotTrigger(
  id: 'my_trigger',
  message: 'Something happened!',
  priority: TriggerPriority.medium,
  cooldown: Duration(minutes: 5),
  animation: MascotAnimationKey.think,
);
```

2. Add cooldown constant in `mascot_config.dart`:

```dart
abstract final class TriggerCooldowns {
  // ...existing...
  static const Duration myTrigger = Duration(minutes: 5);
}
```

3. Add evaluation logic in `mascot_trigger_provider.dart`

## Configuration

All timing constants are centralized in `mascot_config.dart`:

```dart
// Health evaluation
const kHealthEvaluationInterval = Duration(minutes: 5);
const kHealthDebounceDelay = Duration(milliseconds: 500);

// Dimension thresholds
abstract final class SystemThresholds { ... }
abstract final class DevicesThresholds { ... }

// Trigger cooldowns
abstract final class TriggerCooldowns { ... }

// Random speech timing
const kRandomSpeechMinInterval = Duration(seconds: 10);
const kRandomSpeechMaxInterval = Duration(seconds: 30);
```

## Testing

```bash
# Run all mascot tests
flutter test test/page/dashboard/mascot/

# Run specific test groups
flutter test test/page/dashboard/mascot/health/
flutter test test/page/dashboard/mascot/triggers/
flutter test test/page/dashboard/mascot/widgets/
```

## SSE Integration

Health dimensions declare which `InvalidationDomain` they watch. When SSE events arrive:

1. `system_health_provider` checks if domain matches any dimension's `watchedDomains`
2. If match, debounced re-evaluation is triggered (500ms delay)
3. Word cloud UI updates automatically via Riverpod

Trigger system:
1. `mascot_trigger_provider` listens to `sseInvalidationProvider`
2. On matching domain, evaluates state changes (WAN up→down, device count change, etc.)
3. If change detected and not in cooldown, fires notification via `MascotController`
