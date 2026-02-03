// A2UI Widget Extension Module
//
// This module provides support for extending Dashboard with A2UI-defined widgets.
// It enables dynamic widget registration, data binding, and rendering.
//
// ## Usage
//
// ```dart
// import 'package:privacy_gui/page/dashboard/a2ui/_a2ui.dart';
// ```

// Models
export 'models/a2ui_constraints.dart';
export 'models/a2ui_template.dart';
export 'models/a2ui_widget_definition.dart';

// Registry
export 'registry/a2ui_widget_registry.dart';

// Resolver
export 'resolver/data_path_resolver.dart';
export 'resolver/jnap_data_resolver.dart';

// Renderer
export 'renderer/a2ui_widget_renderer.dart';
export 'renderer/template_builder.dart';
