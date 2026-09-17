import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/provider_document_provider.dart';
import '../../utils/constants.dart';
import '../../utils/provider_routes.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/provider/provider_tab_header.dart' show providerBrandBlue;
import '../home_screen.dart';

/// Full-page block shown instead of the Provider Dashboard while a
/// provider's documents haven't been verified by admin staff yet.
/// Registering and (re)uploading documents are the only Provider actions
/// allowed before verification - this page is the only way in or out of
/// that state, offering a path to fix documents or step back to the
/// Customer Dashboard instead of leaving the user stuck.
class VerificationPendingScreen extends StatefulWidget {
  static const routeName = ProviderRoutes.pendingVerification;

  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid != null) {
      context.read<ProviderDocumentProvider>().loadDocuments(providerUid);
    }
  }

  Future<void> _checkStatus() async {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid == null) return;

    setState(() => _checking = true);
    final documents = context.read<ProviderDocumentProvider>();
    await documents.loadDocuments(providerUid);
    if (!mounted) return;
    setState(() => _checking = false);

    if (documents.isVerified) {
      Navigator.of(context).pushReplacementNamed(ProviderRoutes.dashboard);
    } else {
      showAppToast(context, 'Still pending verification. Please check back later.', type: AppToastType.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = context.watch<ProviderDocumentProvider>();
    final remarks = documents.verificationRemarks;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: const Icon(Icons.hourglass_top_rounded, size: 48, color: Colors.orange),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Pending Verification',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A2233)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your provider account is under review. Our team is verifying your profile photo and CNIC - this usually takes a short while. '
                        'You\'ll be able to access the Provider Dashboard as soon as you\'re verified.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
                      ),
                      if (remarks != null && remarks.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: Colors.red, size: 18),
                                  SizedBox(width: 8),
                                  Text('Feedback from our team', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(remarks, style: TextStyle(color: Colors.red.shade700, fontSize: 13, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: kProminentFilledButtonStyle(providerBrandBlue),
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('Update Documents'),
                  onPressed: () => Navigator.of(context).pushNamed(ProviderRoutes.verificationDocuments),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: kProminentOutlinedButtonStyle(providerBrandBlue),
                  icon: _checking
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Check Verification Status'),
                  onPressed: _checking ? null : _checkStatus,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: Icon(Icons.home_outlined, color: Colors.grey[700]),
                  label: Text('Go to Customer Dashboard', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                  onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(HomeScreen.routeName, (route) => false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
