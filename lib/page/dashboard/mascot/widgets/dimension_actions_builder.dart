import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../health/health_dimension.dart';
import '../health/health_score.dart';

/// Builds MascotDialogNode for a dimension's action list.
class DimensionActionsBuilder {
  /// Build a dialog node showing dimension details and actions.
  static MascotDialogNode buildActionsNode({
    required HealthDimension dimension,
    required HealthScore? score,
    required BuildContext context,
  }) {
    final actions = dimension.getActions(context);
    final tierLabel = score?.tierLabel ?? 'Unknown';
    final scoreValue = score?.score ?? 100;

    return MascotDialogNode(
      id: 'dimension_${dimension.type.name}',
      text: '${dimension.displayName}\nScore: $scoreValue ($tierLabel)',
      options: [
        ...actions.map((action) => MascotDialogOption(
              id: action.id,
              label: action.label,
              icon: action.icon,
            )),
        MascotDialogOption(
          id: 'back_to_cloud',
          label: loc(context).back,
          icon: Icons.arrow_back,
        ),
      ],
    );
  }

  /// Get the route name for an action ID.
  static String? getRouteForAction(
    HealthDimension dimension,
    String actionId,
    BuildContext context,
  ) {
    final actions = dimension.getActions(context);
    try {
      final action = actions.firstWhere((a) => a.id == actionId);
      return action.routeName;
    } catch (_) {
      return null;
    }
  }
}
