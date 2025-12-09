import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/providers/feature_state.dart';
import 'package:privacy_gui/route/route_model.dart';

class LinksysRoute extends GoRoute {
  final LinksysRouteConfig? config;

  LinksysRoute({
    required super.path,
    super.name,
    super.builder,
    super.routes,
    this.config,
    // New optional parameters for dirty checking
    ProviderListenable<FeatureState>? provider,
    bool enableDirtyCheck = false,
    FutureOr<bool> Function(BuildContext, GoRouterState)? onExit,
  }) : super(
          onExit: (context, state) async {
            // First, run any custom onExit logic provided by the developer.
            if (onExit != null) {
              if (!await onExit(context, state)) {
                return false; // Custom logic blocked navigation.
              }
            }

            // If dirty checking is enabled and a provider is given...
            if (enableDirtyCheck && provider != null) {
              final container = ProviderScope.containerOf(context);
              final currentState = container.read(provider);

              if (currentState.isDirty) {
                final bool? confirmed = await showUnsavedAlert(context);
                if (confirmed != true) {
                  return false; // User cancelled, block navigation.
                }
              }
            }

            // Allow navigation to proceed.
            return true;
          },
        );
}
