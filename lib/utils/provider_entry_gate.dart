import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/provider_document_provider.dart';
import '../screens/provider/verification_pending_screen.dart';
import '../screens/provider_dashboard_screen.dart';

/// Resolves which route a Provider-role user should actually land on:
/// [ProviderDashboardScreen] once their documents are verified by admin
/// staff, or [VerificationPendingScreen] otherwise. Registering and
/// (re)uploading documents are the only Provider actions allowed before
/// verification - everything else, including the dashboard itself, is
/// gated on this check.
///
/// Every entry point that used to navigate straight to
/// [ProviderDashboardScreen.routeName] (cold start, login, OTP-verify
/// auto-login, "Switch to Provider") should await this first and navigate
/// to the returned route name instead, so a future new entry point can't
/// accidentally bypass the check by navigating to the dashboard directly.
/// [ProviderDashboardScreen] itself also re-checks on entry as a second
/// line of defense (e.g. if a provider's verification is revoked after
/// re-uploading a document while already inside).
Future<String> resolveProviderEntryRoute(BuildContext context) async {
  final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
  if (providerUid == null) return ProviderDashboardScreen.routeName;

  final documents = context.read<ProviderDocumentProvider>();
  await documents.loadDocuments(providerUid);

  return documents.isVerified ? ProviderDashboardScreen.routeName : VerificationPendingScreen.routeName;
}
