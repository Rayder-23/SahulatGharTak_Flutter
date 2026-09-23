import 'package:permission_handler/permission_handler.dart';

enum LocationPermissionResult { granted, denied, permanentlyDenied }

/// Thin wrapper around `permission_handler` for the device-location
/// permission the GPS pin-drop flow needs, mirroring
/// `CameraPermissionService`'s shape/result enum.
class LocationPermissionService {
  Future<LocationPermissionResult> ensureLocationPermission() => _ensure(Permission.locationWhenInUse);

  Future<LocationPermissionResult> _ensure(Permission permission) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return LocationPermissionResult.granted;

    status = await permission.request();
    if (status.isGranted || status.isLimited) return LocationPermissionResult.granted;
    if (status.isPermanentlyDenied) return LocationPermissionResult.permanentlyDenied;
    return LocationPermissionResult.denied;
  }

  Future<bool> openSettings() => openAppSettings();
}
