# Mockito Usage Guidelines

To ensure consistency and maintainability of test code within the project, we adhere to the following guidelines for generating and using Mockito mocks.

## 1. Centralized Mockito Annotation Management

All `@GenerateNiceMocks` or `@GenerateMocks` annotations used for generating mock classes should be centralized in separate files under the `test/mocks/mockito_specs/` directory.

### Steps:

1.  **Create a Spec File**:
    *   For any class `MyClass` (e.g., `PnpService`) that needs to be mocked, create a new Dart file under the `test/mocks/mockito_specs/` directory, named `my_class_spec.dart` (e.g., `pnp_service_spec.dart`).
    *   This file should contain only the Mockito annotation and necessary `import` statements.

    **Example (`test/mocks/mockito_specs/pnp_service_spec.dart`):
    ```dart
    @GenerateNiceMocks([MockSpec<PnpService>()])
    import 'package:mockito/annotations.dart';
    import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';
    ```
    *   Note that we use `MockSpec<MyClass>()` to explicitly specify the class to be mocked.
    *   `@GenerateNiceMocks` generates "Nice Mocks," meaning that for behaviors not defined with `when`, it returns default values (e.g., `null`, empty lists) instead of throwing errors, which helps reduce boilerplate code in tests.

2.  **Update Test Files**:
    *   In the actual test file (e.g., `test/page/instant_setup/pnp_validation_test.dart`), remove any direct `@GenerateMocks` or `@GenerateNiceMocks` annotations.
    *   Remove the `import 'package:mockito/annotations.dart';` statement.
    *   Adjust the `import` path for the generated mock file to point to the `test/mocks/` directory.

    **Example (in `pnp_validation_test.dart`):
    ```dart
    // Remove this line: import 'package:mockito/annotations.dart';
    // Remove this line: @GenerateMocks([PnpService])

    // Replace with:
    import '../../mocks/pnp_service_mocks.dart'; // Assuming the PnpService mock file will be generated here
    ```

## 2. Generating Mock Files

After adding or modifying `_spec.dart` files, you need to run `build_runner` to generate the corresponding mock files.

### Steps:

1.  **Execute Command**: Run the following command in the project's root directory:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
    *   The `--delete-conflicting-outputs` flag ensures that any potentially conflicting old files are deleted before generating new ones.

2.  **File Naming and Location**:
    *   `build_runner` will generate the corresponding mock file in the `test/mocks/` directory based on the `_spec.dart` file's name.
    *   The naming convention is to replace `_spec.dart` with `_mocks.dart`.
    *   **Example**: `test/mocks/mockito_specs/pnp_service_spec.dart` will generate `test/mocks/pnp_service_mocks.dart`.

## 3. Using Generated Mocks in Tests

Once the mock files are generated, you can use them in your test files just like any other class.

### Example:

```dart
// Assuming pnp_service_mocks.dart has been generated and contains MockPnpService
import '../../mocks/pnp_service_mocks.dart';

void main() {
  group('My Test Group', () {
    late MockPnpService mockPnpService; // Use the generated Mock class

    setUp(() {
      mockPnpService = MockPnpService();
      // ... other setup
    });

    test('Test case', () {
      when(mockPnpService.someMethod()).thenReturn('mocked result');
      // ... execute test
      verify(mockPnpService.someMethod()).called(1);
    });
  });
}
```

By following these guidelines, we can ensure a consistent approach to Mockito usage across the project, improving the readability and maintainability of our test code.