import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../renderer/a2ui_widget_renderer.dart';
import 'a2ui_constraint_validator.dart';

/// Provider for A2UIConstraintValidator with injected dependencies.
final a2uiConstraintValidatorProvider =
    Provider<A2UIConstraintValidator>((ref) {
  final registry = ref.watch(a2uiWidgetRegistryProvider);
  return A2UIConstraintValidator(registry);
});
