import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/usp_widget_specs.dart';
import '../models/widget_spec.dart';
import 'package_widget_loader.dart';

/// Merged list of all widget specs: native (17) + package widgets.
///
/// Single source of truth for "what widgets are available".
/// Used by:
/// - [UspLayoutSettingsPanel] (available widgets list)
/// - [UspLayoutController] (addWidget lookup)
/// - [UspSliverDashboardView] (resize constraint enforcement)
///
/// Returns native specs immediately. When package loader resolves,
/// the merged list updates with package specs appended.
final allWidgetSpecsProvider = Provider<List<WidgetSpec>>((ref) {
  final packageTemplates = ref.watch(packageWidgetLoaderProvider);

  return packageTemplates.when(
    data: (templates) => [
      ...UspWidgetSpecs.all,
      ...templates.values.map((t) => t.toWidgetSpec()),
    ],
    loading: () => UspWidgetSpecs.all,
    error: (_, __) => UspWidgetSpecs.all,
  );
});
