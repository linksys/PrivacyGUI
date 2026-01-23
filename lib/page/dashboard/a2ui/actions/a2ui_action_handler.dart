import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'a2ui_action.dart';

/// Abstract base class for A2UI action handlers.
abstract class A2UIActionHandler {
  /// The action type this handler supports (e.g., 'router', 'device')
  String get actionType;

  /// Executes an action and returns the result
  Future<A2UIActionResult> handle(A2UIAction action, WidgetRef ref);

  /// Whether this handler can process the given action
  bool canHandle(A2UIAction action) {
    return action.action.startsWith('$actionType.');
  }

  /// Validates the action parameters
  bool validateAction(A2UIAction action) => true;
}

/// Router-related action handler
class RouterActionHandler extends A2UIActionHandler {
  @override
  String get actionType => 'router';

  @override
  Future<A2UIActionResult> handle(A2UIAction action, WidgetRef ref) async {
    try {
      if (!validateAction(action)) {
        return A2UIActionResult.failure(action, 'Invalid action parameters');
      }

      final actionName = action.action.split('.').last;

      switch (actionName) {
        case 'restart':
          return await _handleRestart(action, ref);
        case 'factoryReset':
          return await _handleFactoryReset(action, ref);
        case 'connect':
          return await _handleConnect(action, ref);
        case 'disconnect':
          return await _handleDisconnect(action, ref);
        default:
          return A2UIActionResult.failure(
              action, 'Unsupported router action: $actionName');
      }
    } catch (e, stackTrace) {
      debugPrint('RouterActionHandler error: $e');
      debugPrint('Stack trace: $stackTrace');
      return A2UIActionResult.failure(action, 'Action failed: $e');
    }
  }

  Future<A2UIActionResult> _handleRestart(
      A2UIAction action, WidgetRef ref) async {
    debugPrint('A2UI: Router restart requested');

    // TODO: Integrate with actual router service
    // final routerService = ref.read(routerServiceProvider);
    // await routerService.restart();

    // Simulate restart delay
    await Future.delayed(const Duration(seconds: 2));

    return A2UIActionResult.success(action, {
      'message': 'Router restart initiated',
      'estimatedTime': 120, // seconds
    });
  }

  Future<A2UIActionResult> _handleFactoryReset(
      A2UIAction action, WidgetRef ref) async {
    debugPrint('A2UI: Factory reset requested');

    // TODO: Integrate with actual router service
    // final routerService = ref.read(routerServiceProvider);
    // await routerService.factoryReset();

    return A2UIActionResult.success(action, {
      'message': 'Factory reset initiated',
      'estimatedTime': 300, // seconds
    });
  }

  Future<A2UIActionResult> _handleConnect(
      A2UIAction action, WidgetRef ref) async {
    debugPrint('A2UI: WAN connect requested');
    // Implementation for WAN connection
    return A2UIActionResult.success(
        action, {'message': 'Connection initiated'});
  }

  Future<A2UIActionResult> _handleDisconnect(
      A2UIAction action, WidgetRef ref) async {
    debugPrint('A2UI: WAN disconnect requested');
    // Implementation for WAN disconnection
    return A2UIActionResult.success(
        action, {'message': 'Disconnection initiated'});
  }

  @override
  bool validateAction(A2UIAction action) {
    final actionName = action.action.split('.').last;
    final validActions = ['restart', 'factoryReset', 'connect', 'disconnect'];
    return validActions.contains(actionName);
  }
}

/// Device management action handler
class DeviceActionHandler extends A2UIActionHandler {
  @override
  String get actionType => 'device';

  @override
  Future<A2UIActionResult> handle(A2UIAction action, WidgetRef ref) async {
    try {
      final actionName = action.action.split('.').last;

      switch (actionName) {
        case 'block':
          return await _handleBlock(action, ref);
        case 'unblock':
          return await _handleUnblock(action, ref);
        case 'setSpeedLimit':
          return await _handleSetSpeedLimit(action, ref);
        case 'showDetails':
          return await _handleShowDetails(action, ref);
        default:
          return A2UIActionResult.failure(
              action, 'Unsupported device action: $actionName');
      }
    } catch (e) {
      return A2UIActionResult.failure(action, 'Device action failed: $e');
    }
  }

  Future<A2UIActionResult> _handleBlock(
      A2UIAction action, WidgetRef ref) async {
    final deviceId = action.params['deviceId'] as String?;
    if (deviceId == null) {
      return A2UIActionResult.failure(action, 'Device ID is required');
    }

    debugPrint('A2UI: Blocking device $deviceId');

    // TODO: Integrate with device management service
    // final deviceService = ref.read(deviceManagerProvider);
    // await deviceService.blockDevice(deviceId);

    return A2UIActionResult.success(action, {
      'message': 'Device blocked successfully',
      'deviceId': deviceId,
    });
  }

  Future<A2UIActionResult> _handleUnblock(
      A2UIAction action, WidgetRef ref) async {
    final deviceId = action.params['deviceId'] as String?;
    if (deviceId == null) {
      return A2UIActionResult.failure(action, 'Device ID is required');
    }

    debugPrint('A2UI: Unblocking device $deviceId');
    return A2UIActionResult.success(action, {
      'message': 'Device unblocked successfully',
      'deviceId': deviceId,
    });
  }

  Future<A2UIActionResult> _handleSetSpeedLimit(
      A2UIAction action, WidgetRef ref) async {
    final deviceId = action.params['deviceId'] as String?;
    final speedLimit = action.params['speedLimit'] as int?;

    if (deviceId == null || speedLimit == null) {
      return A2UIActionResult.failure(
          action, 'Device ID and speed limit are required');
    }

    debugPrint(
        'A2UI: Setting speed limit for device $deviceId to ${speedLimit}Mbps');
    return A2UIActionResult.success(action, {
      'message': 'Speed limit set successfully',
      'deviceId': deviceId,
      'speedLimit': speedLimit,
    });
  }

  Future<A2UIActionResult> _handleShowDetails(
      A2UIAction action, WidgetRef ref) async {
    final deviceId = action.params['deviceId'] as String?;
    if (deviceId == null) {
      return A2UIActionResult.failure(action, 'Device ID is required');
    }

    // This is a UI action - should trigger navigation
    return A2UIActionResult.success(action, {
      'navigateTo': '/device-details/$deviceId',
      'deviceId': deviceId,
    });
  }
}

/// Navigation action handler
class NavigationActionHandler extends A2UIActionHandler {
  @override
  String get actionType => 'navigation';

  @override
  Future<A2UIActionResult> handle(A2UIAction action, WidgetRef ref) async {
    try {
      final actionName = action.action.split('.').last;

      switch (actionName) {
        case 'push':
          return await _handlePush(action, ref);
        case 'pop':
          return await _handlePop(action, ref);
        case 'replace':
          return await _handleReplace(action, ref);
        default:
          return A2UIActionResult.failure(
              action, 'Unsupported navigation action: $actionName');
      }
    } catch (e) {
      return A2UIActionResult.failure(action, 'Navigation action failed: $e');
    }
  }

  Future<A2UIActionResult> _handlePush(A2UIAction action, WidgetRef ref) async {
    final route = action.params['route'] as String?;
    if (route == null) {
      return A2UIActionResult.failure(action, 'Route is required');
    }

    debugPrint('A2UI: Navigating to named route $route');

    try {
      // ✅ Using pushNamed as requested for named routes
      final router = ref.read(routerProvider);
      router.pushNamed(route);

      return A2UIActionResult.success(action, {
        'message': 'Navigation completed successfully',
        'route': route,
      });
    } catch (e) {
      debugPrint('A2UI: Navigation failed: $e');
      return A2UIActionResult.failure(action, 'Navigation failed: $e');
    }
  }

  Future<A2UIActionResult> _handlePop(A2UIAction action, WidgetRef ref) async {
    debugPrint('A2UI: Popping navigation stack');

    try {
      final router = ref.read(routerProvider);
      router.pop();

      return A2UIActionResult.success(
          action, {'message': 'Navigation popped successfully'});
    } catch (e) {
      debugPrint('A2UI: Pop navigation failed: $e');
      return A2UIActionResult.failure(action, 'Pop navigation failed: $e');
    }
  }

  Future<A2UIActionResult> _handleReplace(
      A2UIAction action, WidgetRef ref) async {
    final route = action.params['route'] as String?;
    if (route == null) {
      return A2UIActionResult.failure(action, 'Route is required');
    }

    debugPrint('A2UI: Replacing with named route $route');

    try {
      final router = ref.read(routerProvider);
      router.pushReplacementNamed(route);

      return A2UIActionResult.success(action, {
        'message': 'Navigation replaced successfully',
        'route': route,
      });
    } catch (e) {
      debugPrint('A2UI: Replace navigation failed: $e');
      return A2UIActionResult.failure(action, 'Replace navigation failed: $e');
    }
  }
}

/// UI state action handler
class UIActionHandler extends A2UIActionHandler {
  @override
  String get actionType => 'ui';

  @override
  Future<A2UIActionResult> handle(A2UIAction action, WidgetRef ref) async {
    try {
      final actionName = action.action.split('.').last;

      switch (actionName) {
        case 'showConfirmation':
          return await _handleShowConfirmation(action, ref);
        case 'showSnackbar':
          return await _handleShowSnackbar(action, ref);
        case 'refresh':
          return await _handleRefresh(action, ref);
        default:
          return A2UIActionResult.failure(
              action, 'Unsupported UI action: $actionName');
      }
    } catch (e) {
      return A2UIActionResult.failure(action, 'UI action failed: $e');
    }
  }

  Future<A2UIActionResult> _handleShowConfirmation(
      A2UIAction action, WidgetRef ref) async {
    final title = action.params['title'] as String? ?? 'Confirmation';
    final message = action.params['message'] as String? ?? 'Are you sure?';

    debugPrint('A2UI: Showing confirmation dialog: $title');

    return A2UIActionResult.success(action, {
      'dialogType': 'confirmation',
      'title': title,
      'message': message,
    });
  }

  Future<A2UIActionResult> _handleShowSnackbar(
      A2UIAction action, WidgetRef ref) async {
    final message = action.params['message'] as String? ?? 'Action completed';

    debugPrint('A2UI: Showing snackbar: $message');

    return A2UIActionResult.success(action, {
      'snackbarMessage': message,
    });
  }

  Future<A2UIActionResult> _handleRefresh(
      A2UIAction action, WidgetRef ref) async {
    debugPrint('A2UI: Refreshing data');

    // TODO: Trigger data refresh for relevant providers
    // This could invalidate specific providers based on action.params

    return A2UIActionResult.success(action, {
      'message': 'Data refresh initiated',
    });
  }
}
