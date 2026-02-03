import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../models/a2ui_template.dart';
import '../resolver/data_path_resolver.dart';
import '../actions/a2ui_action_manager.dart';

/// Enhanced TemplateBuilder with full action support.
///
/// This is the updated version of TemplateBuilder that integrates the A2UI action system.
class TemplateBuilderEnhanced {
  TemplateBuilderEnhanced._();

  // Lazy-loaded registry to ensure UiKitCatalog is initialized
  static final IComponentRegistry _registry = _createRegistry();

  static IComponentRegistry _createRegistry() {
    final registry = ComponentRegistry();
    // Register all standard UI Kit components
    UiKitCatalog.standardBuilders.forEach((name, builder) {
      registry.register(name, builder);
    });
    return registry;
  }

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

    debugPrint('❌ A2UI: No match found for "$type"');
    return type;
  }

  /// Builds a widget tree from a template node with action support.
  static Widget build({
    required A2UITemplateNode template,
    required DataPathResolver resolver,
    required WidgetRef ref,
    String? widgetId,
  }) {
    debugPrint('🧪 A2UI: resolver hash: ${identityHashCode(resolver)}');
    try {
      return _buildNode(template, resolver, ref, widgetId);
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
    String? widgetId,
  ) {
    try {
      debugPrint(
          '🏗️ A2UI: Building node type "${node.type}" for widget $widgetId');

      // 1. Resolve Properties (Data Binding + Action Processing)
      final resolvedProps = _resolveProperties(node.properties, resolver, ref);

      // 2. Process Actions and create action callback
      final actionCallback =
          _createActionCallback(resolvedProps, ref, widgetId);

      if (actionCallback != null) {
        debugPrint(
            '🔗 A2UI: Action callback created for ${node.type} in widget $widgetId');
      } else {
        debugPrint(
            '🚫 A2UI: No action callback for ${node.type} in widget $widgetId');
      }

      // 3. Build Children
      final children = node is A2UIContainerNode
          ? node.children
              .map((child) => _buildNode(child, resolver, ref, widgetId))
              .toList()
          : <Widget>[];

      // 4. Build using component registry with action callback
      final componentType = _resolveComponentType(node.type);
      final builder = _registry.lookup(componentType);
      if (builder != null) {
        try {
          debugPrint(
              '🎨 A2UI: Calling builder for "${node.type}" with ${resolvedProps.keys.length} props and ${actionCallback != null ? 'WITH' : 'WITHOUT'} action callback');

          return builder(
            ref.context,
            resolvedProps,
            children: children,
            onAction: actionCallback, // ✅ Now properly implemented!
          );
        } catch (e) {
          debugPrint('❌ A2UI: Error calling builder for "${node.type}": $e');
          return _buildErrorWidget(
              node.type, 'Builder failed: $e', ref.context);
        }
      }

      // 5. Fallback for unknown components
      debugPrint(
          '⚠️ A2UI: No builder found for "${node.type}", using fallback');
      return _buildFallback(node.type, ref.context);
    } catch (e) {
      debugPrint('💥 A2UI: Error in _buildNode for "${node.type}": $e');
      return _buildErrorWidget(node.type, 'Node build failed: $e', ref.context);
    }
  }

  // --- Enhanced Property Resolution with Action Support ---

  static Map<String, dynamic> _resolveProperties(
    Map<String, dynamic> props,
    DataPathResolver resolver,
    WidgetRef ref,
  ) {
    final result = <String, dynamic>{};

    debugPrint('🔄 A2UI: Resolving properties: ${props.keys.toList()}');

    for (final entry in props.entries) {
      try {
        final value = entry.value;
        result[entry.key] = _resolveValue(value, resolver, ref);

        // Special debug logging for action properties
        if (entry.key == 'onTap' &&
            value is Map<String, dynamic> &&
            value.containsKey(r'$action')) {
          debugPrint('🎯 A2UI: Found onTap action definition: ${entry.value}');
          debugPrint('🎯 A2UI: Resolved onTap to: ${result[entry.key]}');
        }
      } catch (e) {
        debugPrint('❌ A2UI: Error resolving property "${entry.key}": $e');
        // Use a placeholder value to prevent widget crash
        result[entry.key] =
            _getPropertyFallback(entry.key, entry.value, ref.context);
      }
    }

    debugPrint('✅ A2UI: Resolved ${result.length} properties');
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

      // Check for action binding: {"$action": "router.restart", "params": {...}}
      if (prop is Map<String, dynamic> && prop.containsKey(r'$action')) {
        // Return the action definition as-is, it will be processed by _createActionCallback
        return prop;
      }

      // Check for conditional action: {"$action": {"$bind": "condition ? 'action1' : 'action2'"}}
      if (prop is Map<String, dynamic> &&
          prop.containsKey(r'$action') &&
          prop[r'$action'] is Map<String, dynamic>) {
        final actionDef = prop[r'$action'] as Map<String, dynamic>;
        if (actionDef.containsKey(r'$bind')) {
          // Resolve the conditional action
          final resolvedAction = _resolveValue(actionDef, resolver, ref);
          return {r'$action': resolvedAction, ...prop}..remove(r'$action');
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

      // Return primitive values as-is
      return prop;
    } catch (e) {
      debugPrint('Error resolving value: $e');
      return 'Error'; // Fallback for any resolution failures
    }
  }

  // --- Action System Integration ---

  /// Creates a universal action callback for UI Kit components
  static void Function(Map<String, dynamic>)? _createActionCallback(
    Map<String, dynamic> resolvedProps,
    WidgetRef ref,
    String? widgetId,
  ) {
    final actionManager = ref.read(a2uiActionManagerProvider);

    // Check if there are any action properties in the resolved props
    bool hasActions = false;
    for (final entry in resolvedProps.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic> && value.containsKey(r'$action')) {
        hasActions = true;
        break;
      }
    }

    if (!hasActions) {
      return null;
    }

    // ✅ Use the universal callback from Action Manager
    return actionManager.createActionCallback(
      ref,
      widgetId: widgetId,
    );
  }

  // --- Fallback and Error Handling ---

  static dynamic _getPropertyFallback(
      String key, dynamic originalValue, BuildContext context) {
    // Provide sensible defaults for common properties
    switch (key) {
      case 'text':
        return 'Error loading text';
      case 'color':
        return Theme.of(context).colorScheme.error;
      case 'backgroundColor':
        return Theme.of(context).colorScheme.errorContainer;
      case 'size':
        return 16.0;
      case 'width':
      case 'height':
        return 100.0;
      case 'padding':
      case 'margin':
        return 8.0;
      case 'visible':
      case 'enabled':
        return false;
      default:
        return originalValue?.toString() ?? 'N/A';
    }
  }

  static Widget _buildFallback(String componentType, BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      style: SurfaceStyle(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        contentColor: Theme.of(context).colorScheme.onSurfaceVariant,
        borderColor: Theme.of(context).colorScheme.outline,
        borderWidth: 1,
        borderRadius: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.widgets,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          AppGap.xs(),
          AppText(
            'Unknown Component: $componentType',
            variant: AppTextVariant.bodySmall,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildErrorWidget(
      String componentType, String error, BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      style: SurfaceStyle(
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        borderColor: Theme.of(context).colorScheme.error,
        borderWidth: 1,
        borderRadius: 12,
        contentColor: Theme.of(context).colorScheme.onErrorContainer,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          AppGap.sm(),
          AppText(
            'Error in $componentType',
            variant: AppTextVariant.titleMedium,
            color: Theme.of(context).colorScheme.error,
            textAlign: TextAlign.center,
          ),
          AppGap.xs(),
          AppText(
            error,
            variant: AppTextVariant.bodySmall,
            color: Theme.of(context).colorScheme.onErrorContainer,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
