import 'package:permission_handler/permission_handler.dart';

/// A mixin that provides utility methods for handling device permissions.
///
/// This mixin simplifies the process of checking and requesting permissions
/// required by the application, such as camera and location access. It uses
/// the `permission_handler` package to interact with the underlying platform's
/// permission system.
mixin Permissions {
  /// Checks if the application has been granted camera permission.
  ///
  /// If the permission has not been granted, it will be requested from the user.
  ///
  /// Returns a `Future<bool>` that completes with `true` if the permission is
  /// granted, and `false` otherwise.
  Future<bool> checkCameraPermissions() async {
    return checkPermission(Permission.camera);
  }

  /// Checks if the application has been granted location permission.
  ///
  /// If the permission has not been granted, it will be requested from the user.
  ///
  /// Returns a `Future<bool>` that completes with `true` if the permission is
  /// granted, and `false` otherwise.
  Future<bool> checkLocationPermissions() async {
    return checkPermission(Permission.location);
  }

  /// Checks if a specific permission has been granted.
  ///
  /// This method first checks the current status of the [permission]. If it is
  /// not already granted, it requests the permission from the user.
  ///
  /// [permission] The `Permission` to check and request.
  ///
  /// Returns a `Future<bool>` that completes with `true` if the permission is
  /// granted, and `false` otherwise.
  Future<bool> checkPermission(Permission permission) async {
    bool result = await permission.isGranted;
    if (!result) {
      result = await permission.request().isGranted;
    }
    return result;
  }

  /// Requests a list of permissions from the user.
  ///
  /// This method is useful for requesting multiple permissions at once, for
  /// example, during the app's initial setup.
  ///
  /// [permissions] A `List<Permission>` to be requested.
  ///
  /// Returns a `Future<Map<Permission, PermissionStatus>>` that completes with
  /// a map containing the status of each requested permission.
  Future<Map<Permission, PermissionStatus>> checkPermissions(
      List<Permission> permissions) async {
    return await permissions.request();
  }
}
