import 'package:permission_handler/permission_handler.dart';

mixin Permissions {
  Future<bool> checkCameraPermissions() async {
    return checkPermission(Permission.camera);
  }

  Future<bool> checkLocationPermissions() async {
    return checkPermission(Permission.location);
  }

  Future<bool> checkPermission(Permission permission) async {
    bool result = await permission.isGranted;
    if (!result) {
      result = await permission.request().isGranted;
    }
    return result;
  }

  Future<Map<Permission, PermissionStatus>> checkPermissions(
      List<Permission> permissions) async {
    return await permissions.request();
  }
}
