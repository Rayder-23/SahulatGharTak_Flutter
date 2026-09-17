import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/provider_dashboard_provider.dart';
import '../providers/provider_document_provider.dart';
import '../utils/provider_routes.dart';
import '../widgets/provider/provider_bottom_nav.dart';
import 'provider/dashboard/provider_home_tab.dart';
import 'provider/jobs/jobs_tab.dart';
import 'provider/profile/profile_tab.dart';
import 'provider/requests/requests_tab.dart';
import 'provider/verification_pending_screen.dart';
import 'provider/wallet/wallet_tab.dart';

class ProviderDashboardScreen extends StatefulWidget {
  static const routeName = ProviderRoutes.dashboard;
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _index = 0;

  // Re-checked here (not just at the entry points that route to this
  // screen) so a deep link, or a provider whose verification gets revoked
  // mid-session (e.g. after re-uploading a document from the Profile tab),
  // can never end up looking at dashboard tabs they shouldn't have access
  // to. Starts true so the tabs (which eagerly build via IndexedStack,
  // including the Profile tab's own document fetch) never mount before this
  // resolves.
  bool _checkingVerification = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVerification());
  }

  Future<void> _checkVerification() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    final providerUid = currentUser?.providerUid;
    if (providerUid == null) return;

    final dashboard = context.read<ProviderDashboardProvider>();
    final documents = context.read<ProviderDocumentProvider>();
    dashboard.loadProviderDetail(providerUid);
    dashboard.loadIncomingRequests(providerUid);
    dashboard.loadAvailabilityStatus(providerUid);
    await documents.loadDocuments(providerUid);
    if (!mounted) return;

    if (!documents.isVerified) {
      Navigator.of(context).pushReplacementNamed(VerificationPendingScreen.routeName);
      return;
    }
    setState(() => _checkingVerification = false);
  }

  void _goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    if (_checkingVerification) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Reactive follow-up to the initial check above: if verification is
    // revoked while the provider is already sitting inside this screen
    // (e.g. they replace a CNIC photo from the Profile tab, which resets
    // IsVerified server-side until re-reviewed), bounce them out instead of
    // leaving the tabs usable until they happen to leave and come back.
    final documents = context.watch<ProviderDocumentProvider>();
    // Ignore mid-fetch states (`isLoadingExisting`) - another screen sharing
    // this singleton (e.g. "My Documents") may be reloading, and `isVerified`
    // only reflects the authoritative server value once that finishes.
    // Reacting mid-fetch previously bounced providers out of screens they'd
    // just opened even though nothing was actually revoked.
    if (!documents.isVerified && !documents.isLoadingExisting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pushReplacementNamed(VerificationPendingScreen.routeName);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = [
      ProviderHomeTab(onNavigateToTab: _goToTab),
      const RequestsTab(),
      const BookingsTab(),
      const WalletTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: ProviderBottomNavigation(
        currentIndex: _index,
        onTabSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}
