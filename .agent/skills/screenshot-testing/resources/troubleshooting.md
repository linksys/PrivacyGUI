# Troubleshooting Guide

## Widget Not Found

1. Read implementation file to verify correct widget type
2. Check if widget is inside ScrollView (use `skipOffstage: false`)
3. Add `Key` to implementation if needed:
   ```dart
   // Implementation
   Container(key: const Key('my_feature_button'), ...)
   
   // Test
   expect(find.byKey(const Key('my_feature_button')), findsOneWidget);
   ```

## Timeout / Hang

- Animations disabled by default via `testHelper.disableAnimations`
- Ensure all async operations have `await`
- Check for unfinished `Future`s

## Overflow Warning

1. Check golden file visually
2. **Critical** (content not visible): Fix implementation
3. **Minor** (<5px): Record and ignore
4. Increase test viewport if content legitimately needs more space:
   ```dart
   final _tallScreens = responsiveDesktopScreens
       .map((s) => s.copyWith(height: 1600))
       .toList();
   ```

## Mock Not Working

```dart
// Verify mock is registered in testHelper.defaultOverrides
// Ensure both build() and state are mocked:
when(testHelper.mockMyNotifier.build()).thenReturn(MyState());
when(testHelper.mockMyNotifier.state).thenReturn(MyState());
```

## Adding New Mocks

1. Create spec: `test/mocks/mockito_specs/{name}_spec.dart`
2. Generate: `dart run build_runner build --delete-conflicting-outputs`
3. Copy to `test/mocks/` and fix inheritance:
   ```dart
   class MockMyNotifier extends Notifier<MyState> with Mock
       implements MyNotifier {
   ```
4. Add to TestHelper setup and defaultOverrides

See `doc/testing/mock_generation_guide.md` for complete instructions.
