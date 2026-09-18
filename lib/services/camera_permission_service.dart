import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionResult { granted, denied, permanentlyDenied }

/// Thin wrapper around `permission_handler` for the camera permission the
/// live document-capture flow needs. The gallery+crop path deliberately
/// requests no photos/storage permission - it goes through the system
/// Android Photo Picker via `image_picker`, which needs none (Google Play
/// policy requires apps with infrequent gallery access to use the picker
/// instead of requesting broad media permissions). Kept separate from
/// `ProviderDocumentProvider` so that provider stays unaware of *how* a
/// permission was granted.
class CameraPermissionService {
  Future<CameraPermissionResult> ensureCameraPermission() => _ensure(Permission.camera);

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
