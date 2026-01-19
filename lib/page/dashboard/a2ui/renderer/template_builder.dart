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

  static IComponentRegistry _createRegistry() {
    final registry = ComponentRegistry();
    // Register all standard UI Kit components
    UiKitCatalog.standardBuilders.forEach((name, builder) {
      registry.register(name, builder);
    });
    return registry;
  }

  /// Builds a widget tree from a template node.
  static Widget build({
    required A2UITemplateNode template,
    required DataPathResolver resolver,
    required WidgetRef ref,
  }) {
    return _buildNode(template, resolver, ref);
  }

  static Widget _buildNode(
    A2UITemplateNode node,
    DataPathResolver resolver,
    WidgetRef ref,
  ) {
    // 1. Resolve Properties (Data Binding)
    final resolvedProps = _resolveProperties(node.properties, resolver, ref);

    // 2. Resolve Children recursively
    final children = (node is A2UIContainerNode)
        ? node.children
            .map((child) => _buildNode(child, resolver, ref))
            .toList()
        : <Widget>[];

    // 3. Lookup Builder from Registry
    final builder = _registry.lookup(node.type);

    // Patch: UiKitCatalog expects 'text' to be String, but resolving data might return int/double.
    // We coerce it to String here to prevent standardBuilders crashing.
    if (node.type == 'AppText' && resolvedProps.containsKey('text')) {
      resolvedProps['text'] = resolvedProps['text']?.toString();
    }

    if (builder != null) {
      return builder(
        ref.context,
        resolvedProps,
        children: children,
        // TODO: Pass onAction callback when we support actions
        onAction: null,
      );
    }

    // 4. Fallback for unknown components
    return _buildFallback(node.type);
  }

  // --- Value Resolution ---

  static Map<String, dynamic> _resolveProperties(
    Map<String, dynamic> props,
    DataPathResolver resolver,
    WidgetRef ref,
  ) {
    final result = <String, dynamic>{};

    for (final entry in props.entries) {
      final value = entry.value;
      result[entry.key] = _resolveValue(value, resolver, ref);
    }

    return result;
  }

  static dynamic _resolveValue(
      dynamic prop, DataPathResolver resolver, WidgetRef ref) {
    if (prop == null) return null;

    // Check for bound value: {"$bind": "path"}
    if (prop is Map<String, dynamic> && prop.containsKey(r'$bind')) {
      final path = prop[r'$bind'] as String;

      // Try to watch first for reactive updates
      final provider = resolver.watch(path);
      if (provider != null) {
        return ref.watch(provider);
      }

      // Fallback to one-off resolution
      return resolver.resolve(path);
    }

    // Recursively resolve maps (e.g. nested objects)
    if (prop is Map<String, dynamic>) {
      return _resolveProperties(prop, resolver, ref);
    }

    // Recursively resolve lists
    if (prop is List) {
      return prop.map((e) => _resolveValue(e, resolver, ref)).toList();
    }

    // Static value
    return prop;
  }

  static Widget _buildFallback(String type) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red),
      ),
      child: Text('Unknown: $type',
          style: const TextStyle(color: Colors.red, fontSize: 10)),
    );
  }
}
