# Package Widget Action System Documentation

## Overview

The Package Widget Action System provides comprehensive support for user interactions in JSON-based widget templates. This system allows widgets to respond to user actions such as button presses, form changes, and card taps.

## Architecture

### Components

1. **UiKitTemplateRenderer** - Core template engine with action handling support
2. **PackageWidgetRenderer** - Integration layer that processes actions
3. **UI Kit Catalog** - Standard components with built-in action support
4. **Action Handlers** - Business logic for processing different action types

### Flow

```
User Interaction → UI Component → Action Data → PackageWidgetRenderer → Handler Logic
```

## Supported Actions

### Button Actions

Components: `AppButton`, `AppIconButton`

**JSON Template:**
```json
{
  "type": "AppButton",
  "props": {
    "label": "Save Settings",
    "onTap": {
      "$action": "save_settings",
      "section": "network",
      "validate": true
    }
  }
}
```

**Generated Action Data:**
```dart
{
  "action": "save_settings",
  "section": "network",
  "validate": true
}
```

### Form Input Actions

Components: `AppTextField`, `AppCheckbox`, `AppSwitch`, `AppSlider`

**JSON Template:**
```json
{
  "type": "AppTextField",
  "props": {
    "label": "Device Name",
    "onChanged": {
      "$action": "field_changed",
      "field": "deviceName"
    }
  }
}
```

**Generated Action Data:**
```dart
{
  "action": "field_changed",
  "field": "deviceName",
  "value": "user_input"  // Added by component
}
```

### Card Tap Actions

Components: `AppCard`, `AppListTile`

**JSON Template:**
```json
{
  "type": "AppCard",
  "props": {
    "onTap": {
      "$action": "navigate",
      "destination": "settings",
      "params": {"section": "wifi"}
    },
    "children": [...]
  }
}
```

### Selection Actions

Components: `AppDropdown`, `AppTabs`, `AppRadioList`

**JSON Template:**
```json
{
  "type": "AppTabs",
  "props": {
    "tabs": [...],
    "onTabChanged": {
      "$action": "tab_selected",
      "context": "main_nav"
    }
  }
}
```

## Built-in Action Types

### 1. `save_settings`
Validates and persists configuration changes.

**Parameters:**
- `section`: Configuration section name
- `validate`: Whether to validate before saving

**Handler Logic:**
- Validates form data if requested
- Calls USP API to persist changes
- Shows success/error feedback

### 2. `navigate`
Handles navigation to other pages or dialogs.

**Parameters:**
- `destination`: Target page/dialog identifier
- `params`: Optional navigation parameters

**Handler Logic:**
- Uses GoRouter for page navigation
- Shows modal dialogs when appropriate

### 3. `refresh_data`
Triggers widget data refresh.

**Handler Logic:**
- Calls USP GET for subscription-based widgets
- Triggers HTTP fetch for CGI-based widgets
- Updates widget data provider

### 4. Generic Actions
- `pressed`/`tapped`: Basic interaction events
- `changed`/`toggled`: Form value changes
- `selected`: Selection changes

## Implementation Details

### UiKitTemplateRenderer Integration

```dart
final renderer = UiKitTemplateRenderer(
  template: template,
  data: data,
  builders: {
    ...UiKitCatalog.standardBuilders,
    ...PackageWidgetBuilders.all,
  },
  onAction: _handleWidgetAction,  // ← Action handler
);
```

### Action Handler Method

```dart
void _handleWidgetAction(Map<String, dynamic> actionData) {
  final actionType = actionData['action'] as String?;

  switch (actionType) {
    case 'save_settings':
      _handleSaveSettingsAction(actionData);
      break;
    case 'navigate':
      _handleNavigationAction(actionData);
      break;
    case 'refresh_data':
      _handleRefreshDataAction(actionData);
      break;
    // ... other cases
  }
}
```

### Custom Action Types

To add custom action types, extend the switch statement in `_handleWidgetAction`:

```dart
case 'custom_action':
  _handleCustomAction(actionData);
  break;

void _handleCustomAction(Map<String, dynamic> actionData) {
  // Implement custom logic here
  final customParam = actionData['customParam'];
  // Process the action...
}
```

## Testing

### Action Integration Tests

Comprehensive test coverage ensures actions work correctly:

- **Button Actions**: Verify press events are handled
- **Form Actions**: Test input change processing
- **Navigation Actions**: Confirm routing works
- **Data Integration**: Ensure actions work with data binding

### Test Example

```dart
testWidgets('Button action triggers handler', (tester) async {
  final template = PackageWidgetTemplate(
    template: {
      'type': 'AppButton',
      'props': {
        'label': 'Test Button',
        'onTap': {'$action': 'test_action'}
      }
    },
  );

  await tester.pumpWidget(PackageWidgetRenderer(template: template));
  await tester.tap(find.byType(AppButton));

  // Verify action was processed without errors
});
```

## JSON Template Guidelines

### Action Structure

Always use the `$action` key for action type:

```json
{
  "onTap": {
    "$action": "action_name",
    "param1": "value1",
    "param2": "value2"
  }
}
```

### Parameter Naming

- Use camelCase for parameter names
- Make parameters descriptive and specific
- Include validation parameters when relevant

### Error Handling

Actions that fail are logged but don't crash the widget:

```
[W] [PkgWidget] Error handling action save_settings: Network timeout
```

## Best Practices

### 1. Action Granularity
- Keep actions focused on single responsibilities
- Use specific action names (`save_wifi_settings` vs `save`)
- Pass relevant context in parameters

### 2. User Feedback
- Show loading states for async actions
- Provide success/error feedback
- Maintain UI responsiveness

### 3. Testing Strategy
- Test each action type independently
- Verify error handling paths
- Test actions with data binding

### 4. Performance
- Avoid heavy processing in action handlers
- Use async/await for API calls
- Implement proper cancellation for disposed widgets

## Migration from Static Widgets

To add actions to existing static widgets:

1. **Identify Interactive Elements**
   ```json
   // Before: Static button
   {"type": "AppButton", "props": {"label": "Save"}}

   // After: Interactive button
   {
     "type": "AppButton",
     "props": {
       "label": "Save",
       "onTap": {"$action": "save_settings"}
     }
   }
   ```

2. **Add Action Handlers**
   Implement corresponding handler methods in `PackageWidgetRenderer`

3. **Update Tests**
   Add action integration tests for new interactive behavior

## Future Enhancements

Planned improvements to the action system:

1. **Action Validation** - JSON schema validation for action parameters
2. **Action Middleware** - Pre/post-processing hooks for actions
3. **Action Analytics** - Usage tracking and performance metrics
4. **Visual Designer** - Drag-and-drop action assignment in Phase 3

The action system provides a solid foundation for interactive Package Widgets and is ready for the upcoming visual designer implementation.