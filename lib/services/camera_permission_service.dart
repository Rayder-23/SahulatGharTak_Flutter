import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionResult { granted, denied, permanentlyDenied }

/// Thin wrapper around `permission_handler` for the permissions the live
/// document-capture flow needs (camera for the live scanner, photos for the
/// gallery+crop path). Kept separate from `ProviderDocumentProvider` so that
/// provider stays unaware of *how* a permission was granted.
class CameraPermissionService {
  Future<CameraPermissionResult> ensureCameraPermission() => _ensure(Permission.camera);

  Future<CameraPermissionResult> ensurePhotosPermission() => _ensure(Permission.photos);

  Future<CameraPermissionResult> _ensure(Permission permission) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return CameraPermissionResult.granted;

    status = await permission.request();
    if (status.isGranted || status.isLimited) return CameraPermissionResult.granted;
    if (status.isPermanentlyDenied) return CameraPermissionResult.permanentlyDenied;
    return CameraPermissionResult.denied;
  }

  Future<bool> openSettings() => openAppSettings();
}
