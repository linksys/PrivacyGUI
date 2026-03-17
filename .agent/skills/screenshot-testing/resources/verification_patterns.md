# UI Verification Patterns

## DO ✅

```dart
// Specific widget types (from ui_kit_library)
expect(find.byType(AppButton), findsOneWidget);
expect(find.byType(AppLoader), findsOneWidget);
expect(find.byType(AppTextField), findsOneWidget);

// Localized text (never hardcode strings)
expect(find.text(testHelper.loc(context).welcome), findsOneWidget);

// Widget with text
expect(
  find.widgetWithText(AppButton, testHelper.loc(context).login),
  findsOneWidget,
);

// By Key (most reliable)
expect(find.byKey(const Key('my_feature_button')), findsOneWidget);

// Scoped search in dialogs
expect(
  find.descendant(
    of: find.byType(AlertDialog),
    matching: find.text(testHelper.loc(context).title),
  ),
  findsOneWidget,
);
```

## DON'T ❌

```dart
// Hardcoded strings
expect(find.text('Welcome'), findsOneWidget);

// Generic types
expect(find.byType(Widget), findsOneWidget);

// Wrong widget type (not from ui_kit)
expect(find.byType(Button), findsOneWidget); // Should be AppButton
```

## Common Widget Mappings

| Old (privacygui_widgets) | New (ui_kit_library) |
|-------------------------|----------------------|
| `CustomButton` | `AppButton` |
| `LoadingSpinner` | `AppLoader` |
| `CustomTextField` | `AppTextField` |
| `CustomExpansionCard` | `AppExpansionPanel` |
