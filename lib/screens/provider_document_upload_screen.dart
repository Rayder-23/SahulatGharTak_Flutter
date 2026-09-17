import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/provider_document_provider.dart';
import '../utils/constants.dart';
import '../widgets/auth_card_scaffold.dart';
import '../widgets/message_dialog.dart';
import '../widgets/provider/document_capture_sheet.dart';
import '../widgets/provider/document_image_slot.dart';
import 'provider/verification_pending_screen.dart';
import 'provider_dashboard_screen.dart';

class ProviderDocumentUploadArgs {
  final int providerUid;
  const ProviderDocumentUploadArgs({required this.providerUid});
}

class ProviderDocumentUploadScreen extends StatefulWidget {
  static const routeName = '/provider-document-upload';
  const ProviderDocumentUploadScreen({super.key});

  @override
  State<ProviderDocumentUploadScreen> createState() => _ProviderDocumentUploadScreenState();
}

class _ProviderDocumentUploadScreenState extends State<ProviderDocumentUploadScreen> {
  ProviderDocumentUploadArgs? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args ??= ModalRoute.of(context)!.settings.arguments as ProviderDocumentUploadArgs;
  }

  Future<void> _upload() async {
    final provider = context.read<ProviderDocumentProvider>();
    final success = await provider.upload(_args!.providerUid);

    if (!mounted) return;

    if (success) {
      await showMessageDialog(
        context,
        title: 'Documents Uploaded',
        message: 'Your documents were uploaded successfully.',
        type: MessageDialogType.success,
      );
      if (!mounted) return;
      // A brand-new registration's first submission is always pending admin
      // review, so this normally lands on the pending-verification page
      // rather than the dashboard - but `provider.isVerified` (fresh from
      // this very upload response) is checked rather than assumed, in case
      // an already-verified provider is replacing a document.
      final target = provider.isVerified ? ProviderDashboardScreen.routeName : VerificationPendingScreen.routeName;
      Navigator.of(context).pushNamedAndRemoveUntil(target, (route) => false);
    } else {
      await showMessageDialog(
        context,
        title: 'Upload Failed',
        message: provider.error ?? 'Failed to upload documents',
        type: MessageDialogType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderDocumentProvider>();

    return AuthCardScaffold(
      title: 'Verify Your Identity',
      subtitle: 'Upload your profile photo and CNIC to complete registration',
      avatarIcon: Icons.badge_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          authFieldLabel('Profile Photo'),
          DocumentImageSlot(
            file: provider.profilePhoto,
            placeholderIcon: Icons.person_outline,
            label: 'Add profile photo',
            onTap: () => showDocumentCaptureSheet(context, slot: ProviderDocumentSlot.profilePhoto),
            onRemove: () => context.read<ProviderDocumentProvider>().removeImage(ProviderDocumentSlot.profilePhoto),
          ),
          const SizedBox(height: 20),
          authFieldLabel('CNIC Front'),
          DocumentImageSlot(
            file: provider.cnicFront,
            placeholderIcon: Icons.credit_card,
            label: 'Add CNIC front image',
            onTap: () => showDocumentCaptureSheet(context, slot: ProviderDocumentSlot.cnicFront),
            onRemove: () => context.read<ProviderDocumentProvider>().removeImage(ProviderDocumentSlot.cnicFront),
          ),
          const SizedBox(height: 20),
          authFieldLabel('CNIC Back'),
          DocumentImageSlot(
            file: provider.cnicBack,
            placeholderIcon: Icons.credit_card,
            label: 'Add CNIC back image',
            onTap: () => showDocumentCaptureSheet(context, slot: ProviderDocumentSlot.cnicBack),
            onRemove: () => context.read<ProviderDocumentProvider>().removeImage(ProviderDocumentSlot.cnicBack),
          ),
          const SizedBox(height: 28),
          if (provider.isUploading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: provider.uploadProgress > 0 ? provider.uploadProgress : null,
                minHeight: 8,
                backgroundColor: const Color(0xFFF5F5F7),
                valueColor: const AlwaysStoppedAnimation(kPrimaryColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uploading... ${(provider.uploadProgress * 100).clamp(0, 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 20),
          ],
          AuthPrimaryButton(
            label: 'Upload & Continue',
            isLoading: provider.isUploading,
            onPressed: provider.canUpload ? _upload : null,
          ),
          if (!provider.canUpload)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Profile photo, CNIC front and CNIC back are all required.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
