import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../models/a2ui_template.dart';
import '../resolver/data_path_resolver.dart';

/// Builds Flutter widgets from A2UI template nodes using [UiKitCatalog].
///
/// This builder acts as a bridge between the A2UI template format (specific to Dashboard)
/// and the Generative UI component registry (shared with Chat).
class TemplateBuilder {
  TemplateBuilder._();

  // Lazy-loaded registry to ensure UiKitCatalog is initialized
  static final IComponentRegistry _registry = _createRegistry();

  /// Resolves component type aliases (e.g., "Button" -> "AppButton").
  static String _resolveComponentType(String type) {
    debugPrint('🔍 A2UI: Resolving component type: "$type"');

    // 1. Check if type exists directly
    if (_registry.lookup(type) != null) {
      debugPrint('✅ A2UI: Found direct match: "$type"');
      return type;
    }

    // 2. Try adding 'App' prefix
    if (!type.startsWith('App')) {
      final prefixed = 'App$type';
      debugPrint('🔍 A2UI: Trying matching prefix: "$prefixed"');
      if (_registry.lookup(prefixed) != null) {
        debugPrint('✅ A2UI: Found alias match: "$prefixed"');
        return prefixed;
      }
    }

    debugPrint(
        '❌ A2UI: No match found for "$type" (Registry count: ${_registeredKeys.length})');
    return type;
  }

  // Helper to expose keys for debugging
  static Set<String> get _registeredKeys {
    // This assumes ComponentRegistry exposes something to check keys,
    // strictly speaking standard IComponentRegistry might not.
    // If we can't get keys easily, we just rely on the count from createRegistry log.
    return {};
  }

  static IComponentRegistry _createRegistry() {
    debugPrint('🔨 A2UI: Creating TemplateBuilder Registry...');
    final registry = ComponentRegistry();
    // Register all standard UI Kit components
    int count = 0;
    UiKitCatalog.standardBuilders.forEach((name, builder) {
      debugPrint('  - Registering: $name');
      registry.register(name, builder);
      count++;
    });
    debugPrint('✅ A2UI: Registry created with $count components.');
    return registry;
  }

  /// Builds a widget tree from a template node.
  static Widget build({
    required A2UITemplateNode template,
    required DataPathResolver resolver,
    required WidgetRef ref,
  }) {
    try {
      return _buildNode(template, resolver, ref);
    } catch (e, stackTrace) {
      debugPrint('A2UI Template build error: $e');
      debugPrint('Stack trace: $stackTrace');
      return _buildErrorWidget(template.type, 'Build failed: $e', ref.context);
    }
  }

  static Widget _buildNode(
    A2UITemplateNode node,
    DataPathResolver resolver,
    WidgetRef ref,
  ) {
    try {
      // 1. Resolve Properties (Data Binding)
      final resolvedProps = _resolveProperties(node.properties, resolver, ref);

      // 2. Resolve Children recursively
      final children = <Widget>[];
      if (node is A2UIContainerNode) {
        for (final child in node.children) {
          try {
            children.add(_buildNode(child, resolver, ref));
          } catch (e) {
            debugPrint('Error building child component "${child.type}": $e');
            // Add error widget for this child but continue with others
            children.add(_buildErrorWidget(
                child.type, 'Child build failed: $e', ref.context));
          }
        }
      }

      // 3. Lookup Builder from Registry
      final componentType = _resolveComponentType(node.type);
      final builder = _registry.lookup(componentType);

      // Patch: UiKitCatalog expects 'text' to be String, but resolving data might return int/double.
      // We coerce it to String here to prevent standardBuilders crashing.
      if (node.type == 'AppText' && resolvedProps.containsKey('text')) {
        resolvedProps['text'] = resolvedProps['text']?.toString();
      }

      if (builder != null) {
        try {
          return builder(
            ref.context,
            resolvedProps,
            children: children,
            // TODO: Pass onAction callback when we support actions
            onAction: null,
          );
        } catch (e) {
          debugPrint('Error calling builder for "${node.type}": $e');
          return _buildErrorWidget(
              node.type, 'Builder failed: $e', ref.context);
        }
      }

      // 4. Fallback for unknown components
      return _buildFallback(node.type, ref.context);
    } catch (e) {
      debugPrint('Error in _buildNode for "${node.type}": $e');
      return _buildErrorWidget(node.type, 'Node build failed: $e', ref.context);
    }
  }

  // --- Value Resolution ---

  static Map<String, dynamic> _resolveProperties(
    Map<String, dynamic> props,
    DataPathResolver resolver,
    WidgetRef ref,
  ) {
    final result = <String, dynamic>{};

    for (final entry in props.entries) {
      try {
        final value = entry.value;
        result[entry.key] = _resolveValue(value, resolver, ref);
      } catch (e) {
        debugPrint('Error resolving property "${entry.key}": $e');
        // Use a placeholder value to prevent widget crash
        result[entry.key] =
            _getPropertyFallback(entry.key, entry.value, ref.context);
      }
    }

    return result;
  }

  static dynamic _resolveValue(
      dynamic prop, DataPathResolver resolver, WidgetRef ref) {
    if (prop == null) return null;

    try {
      // Check for bound value: {"$bind": "path"}
      if (prop is Map<String, dynamic> && prop.containsKey(r'$bind')) {
        final path = prop[r'$bind'] as String;

        try {
          // Try to watch first for reactive updates
          final provider = resolver.watch(path);
          if (provider != null) {
            return ref.watch(provider);
          }

          // Fallback to one-off resolution
          return resolver.resolve(path);
        } catch (e) {
          debugPrint('Error resolving data binding "$path": $e');
          return 'Loading...'; // Fallback for data binding failures
        }
      }

      // Recursively resolve maps (e.g. nested objects)
      if (prop is Map<String, dynamic>) {
        return _resolveProperties(prop, resolver, ref);
      }

      // Recursively resolve lists
      if (prop is List) {
        return prop.map((e) {
          try {
            return _resolveValue(e, resolver, ref);
          } catch (e) {
            debugPrint('Error resolving list item: $e');
            return 'Error'; // Fallback for list item failures
          }
        }).toList();
      }

      // Static value
      return prop;
    } catch (e) {
      debugPrint('Error in _resolveValue: $e');
      return prop; // Return original value if resolution fails
    }
  }

  /// Gets fallback value for property resolution failures.
  static dynamic _getPropertyFallback(
      String propertyName, dynamic originalValue, BuildContext context) {
    return switch (propertyName) {
      'text' => 'Loading data...',
      'icon' => 'Icons.error',
      'color' => Theme.of(context).colorScheme.onSurfaceVariant,
      'mainAxisAlignment' => 'center',
      'crossAxisAlignment' => 'center',
      _ => originalValue, // Use original value as fallback
    };
  }

  /// Builds error widget for component failures using UI Kit components.
  static Widget _buildErrorWidget(
      String componentType, String error, BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      margin: const EdgeInsets.all(AppSpacing.xxs),
      style: SurfaceStyle(
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        borderColor: Theme.of(context).colorScheme.error,
        borderWidth: 1,
        borderRadius: 8,
        contentColor: Theme.of(context).colorScheme.onErrorContainer,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          AppGap.xs(),
          AppText(
            'Component Error: $componentType',
            variant: AppTextVariant.labelSmall,
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          AppGap.xxs(),
          AppText(
            error,
            variant: AppTextVariant.bodySmall,
            color: Theme.of(context).colorScheme.error,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds fallback widget for unknown components using UI Kit components.
  static Widget _buildFallback(String type, BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      style: SurfaceStyle(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderColor: Theme.of(context).colorScheme.outline,
        borderWidth: 1,
        borderRadius: 8,
        contentColor: Theme.of(context).colorScheme.onSurface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.help_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 18,
          ),
          AppGap.xxs(),
          AppText(
            'Unknown: $type',
            variant: AppTextVariant.bodySmall,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
