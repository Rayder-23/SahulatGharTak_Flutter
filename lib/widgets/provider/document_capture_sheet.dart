import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/provider_document_provider.dart';
import '../../screens/provider/live_camera_capture_screen.dart';
import '../../services/frame_validators/cnic_frame_validator.dart';
import '../../services/frame_validators/face_frame_validator.dart';
import '../message_dialog.dart';
import 'provider_tab_header.dart';

/// Shared entry point for picking a provider verification document
/// (profile photo, CNIC front/back): a bottom sheet offering the live
/// camera-with-detection flow, or a gallery pick cropped into the same
/// fixed aspect ratio. Used by both the first-time registration upload
/// screen and the later "view/replace documents" screen so they can't drift.
Future<void> showDocumentCaptureSheet(BuildContext context, {required ProviderDocumentSlot slot}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: Text('Select Image Source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: providerBrandBlue),
            title: const Text('Take Photo'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: providerBrandBlue),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return;

  File? picked;
  if (source == ImageSource.camera) {
    picked = await Navigator.of(context).push<File?>(
      MaterialPageRoute(builder: (_) => LiveCameraCaptureScreen(slot: slot)),
    );
  } else {
    picked = await _pickFromGalleryAndCrop(context, slot);
  }

  if (picked == null || !context.mounted) return;

  final provider = context.read<ProviderDocumentProvider>();
  await provider.setPickedImage(slot, picked);

  if (!context.mounted) return;
  if (provider.error != null) {
    await showMessageDialog(context, title: 'Something Went Wrong', message: provider.error!, type: MessageDialogType.error);
  }
}

Future<File?> _pickFromGalleryAndCrop(BuildContext context, ProviderDocumentSlot slot) async {
  final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (xFile == null || !context.mounted) return null;

  final isProfilePhoto = slot == ProviderDocumentSlot.profilePhoto;
  final title = switch (slot) {
    ProviderDocumentSlot.profilePhoto => 'Crop Profile Photo',
    ProviderDocumentSlot.cnicFront => 'Crop CNIC Front',
    ProviderDocumentSlot.cnicBack => 'Crop CNIC Back',
  };

  final cropped = await ImageCropper().cropImage(
    sourcePath: xFile.path,
    aspectRatio: isProfilePhoto ? const CropAspectRatio(ratioX: 1, ratioY: 1) : const CropAspectRatio(ratioX: 85.6, ratioY: 54),
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: title,
        toolbarColor: providerBrandBlue,
        toolbarWidgetColor: Colors.white,
        lockAspectRatio: true,
      ),
      IOSUiSettings(title: title, aspectRatioLockEnabled: true),
    ],
  );
  if (cropped == null) return null;
  final croppedFile = File(cropped.path);

  if (!context.mounted) return null;
  final isValid = await _validateStaticImage(context, slot, croppedFile);
  if (!context.mounted) return null;
  if (!isValid) {
    final message = switch (slot) {
      ProviderDocumentSlot.profilePhoto => 'No face was detected in that photo. Please choose a clearer one.',
      ProviderDocumentSlot.cnicFront => 'That doesn\'t look like a CNIC front. Please choose a clearer photo of the front.',
      ProviderDocumentSlot.cnicBack => 'That doesn\'t look like a CNIC back. Please choose a clearer photo of the back.',
    };
    await showMessageDialog(context, title: 'Photo Not Accepted', message: message, type: MessageDialogType.error);
    return null;
  }
  return croppedFile;
}

/// Runs the same face/CNIC checks used to gate the live-camera shutter
/// against a single already-cropped image, so a gallery upload can't skip
/// validation entirely. Shows a brief non-dismissible progress indicator
/// since on-device model inference can take a moment on a static image.
Future<bool> _validateStaticImage(BuildContext context, ProviderDocumentSlot slot, File file) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final inputImage = InputImage.fromFilePath(file.path);
    if (slot == ProviderDocumentSlot.profilePhoto) {
      final validator = FaceFrameValidator();
      try {
        return await validator.hasFace(inputImage);
      } finally {
        await validator.close();
      }
    } else {
      final validator = CnicFrameValidator();
      try {
        final result = await validator.validate(inputImage, isBack: slot == ProviderDocumentSlot.cnicBack);
        return result.isValid;
      } finally {
        await validator.close();
      }
    }
  } catch (_) {
    // If validation itself fails to run (e.g. a corrupt file), don't block
    // the upload on a client-side detector error - the server-side
    // verification step is still the final gate.
    return true;
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}
