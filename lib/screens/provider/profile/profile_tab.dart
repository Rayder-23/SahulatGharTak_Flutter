import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/category.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/provider_categories_provider.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../providers/provider_document_provider.dart';
import '../../../providers/time_format_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/date_time_formatter.dart';
import '../../../utils/provider_availability_helper.dart';
import '../../../utils/privacy_policy_launcher.dart';
import '../../../utils/provider_routes.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/curved_profile_header.dart';
import '../../../widgets/delete_account_dialog.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/provider/provider_tab_header.dart' show providerBrandDark, providerBrandBlue, providerBrandAccent;
import '../../../widgets/primary_category_dialog.dart';
import '../../../widgets/provider/tab_state_placeholder.dart';
import '../../category_picker_screen.dart';
import '../../home_screen.dart';
import '../../landing_screen.dart';

const _verifiedGreen = Color(0xFF16A34A);

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  static const double _avatarRadius = 46;
  static const double _headerHeight = 150;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  void _loadProfile() {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid != null) {
      final dashboard = context.read<ProviderDashboardProvider>();
      dashboard.loadProviderDetail(providerUid);
      dashboard.loadAvailabilityStatus(providerUid);
      context.read<ProviderDocumentProvider>().loadDocuments(providerUid);
      context.read<ProviderCategoriesProvider>().load(providerUid);
    }
  }

  Future<void> _editCategories(BuildContext context) async {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid == null) return;

    final categoriesProvider = context.read<ProviderCategoriesProvider>();
    final currentIds = categoriesProvider.categories.map((c) => c.categoryUid).toSet();

    final result = await Navigator.of(context).push<List<Category>>(
      MaterialPageRoute(builder: (_) => CategoryPickerScreen(selectedCategoryIds: currentIds)),
    );
    if (result == null || result.isEmpty || !context.mounted) return;

    final primaryMatches = categoriesProvider.categories.where((c) => c.isPrimary);
    final currentPrimary = primaryMatches.isEmpty ? null : primaryMatches.first.categoryUid;

    int primaryCategoryId;
    if (result.length == 1) {
      primaryCategoryId = result.first.id;
    } else {
      final chosen = await showPrimaryCategoryDialog(context, categories: result, initialPrimaryId: currentPrimary);
      if (chosen == null || !context.mounted) return;
      primaryCategoryId = chosen;
    }

    await _saveCategories(context, providerUid, categoryIds: result.map((c) => c.id).toList(), primaryCategoryId: primaryCategoryId);
  }

  /// Lets the provider change which of their *already-selected* categories is
  /// primary at any time, without going through the full add/remove picker —
  /// a standalone entry point to [showPrimaryCategoryDialog] alongside
  /// [_editCategories]'s full "Edit" flow.
  Future<void> _editPrimaryCategory(BuildContext context) async {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid == null) return;

    final categoriesProvider = context.read<ProviderCategoriesProvider>();
    final categories = categoriesProvider.categories;
    if (categories.length < 2) return;

    final asCategories = categories
        .map((c) => Category(id: c.categoryUid, serviceId: 0, serviceName: '', name: c.categoryName, description: null, createdOn: DateTime.now()))
        .toList();
    final primaryMatches = categories.where((c) => c.isPrimary);
    final currentPrimary = primaryMatches.isEmpty ? null : primaryMatches.first.categoryUid;

    final chosen = await showPrimaryCategoryDialog(context, categories: asCategories, initialPrimaryId: currentPrimary);
    if (chosen == null || chosen == currentPrimary || !context.mounted) return;

    await _saveCategories(context, providerUid, categoryIds: categories.map((c) => c.categoryUid).toList(), primaryCategoryId: chosen);
  }

  Future<void> _saveCategories(BuildContext context, int providerUid, {required List<int> categoryIds, required int primaryCategoryId}) async {
    final categoriesProvider = context.read<ProviderCategoriesProvider>();
    final success = await categoriesProvider.save(providerUid, categoryIds: categoryIds, primaryCategoryId: primaryCategoryId);
    if (!context.mounted) return;

    if (success) {
      showAppToast(context, 'Categories updated', type: AppToastType.success);
    } else {
      showAppToast(context, categoriesProvider.error ?? 'Failed to update categories', type: AppToastType.error);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out of your account?',
      confirmLabel: 'Log Out',
      icon: Icons.logout_rounded,
      color: providerBrandBlue,
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    context.read<TimeFormatProvider>().reset();
    Navigator.of(context).pushNamedAndRemoveUntil(LandingScreen.routeName, (route) => false);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final password = await showDeleteAccountDialog(context);
    if (password == null || !context.mounted) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.deleteAccount(password);
    if (!context.mounted) return;

    if (success) {
      await showMessageDialog(
        context,
        title: 'Account Deleted',
        message: 'Account deleted successfully.',
        type: MessageDialogType.success,
      );
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(LandingScreen.routeName, (route) => false);
    } else {
      await showMessageDialog(
        context,
        title: 'Delete Failed',
        message: authProvider.error ?? 'Failed to delete account',
        type: MessageDialogType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final dashboard = context.watch<ProviderDashboardProvider>();
    final detail = dashboard.providerDetail;
    final documents = context.watch<ProviderDocumentProvider>();
    final profilePhotoUrl = documents.profilePhotoUrl;

    if (dashboard.profileLoading && detail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (dashboard.profileError != null && detail == null) {
      return Scaffold(
        body: TabStatePlaceholder(
          icon: Icons.wifi_off_rounded,
          color: Colors.red,
          title: 'Couldn\'t load profile',
          message: dashboard.profileError,
          onRetry: _loadProfile,
        ),
      );
    }

    if (detail == null) {
      return Scaffold(
        body: TabStatePlaceholder(
          icon: Icons.person_off_outlined,
          color: providerBrandBlue,
          title: 'No profile data found',
          onRetry: _loadProfile,
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Provider Profile'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: CurvedProfileHeader(
        color: providerBrandBlue,
        headerColors: const [providerBrandDark, providerBrandBlue],
        headerHeight: _headerHeight,
        avatarRadius: _avatarRadius,
        onRefresh: () async => _loadProfile(),
        avatar: CircleAvatar(
          backgroundColor: providerBrandBlue,
          backgroundImage: profilePhotoUrl != null ? NetworkImage(profilePhotoUrl) : null,
          child: profilePhotoUrl == null ? const Icon(Icons.person, color: Colors.white, size: 42) : null,
        ),
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, _avatarRadius + 20, 20, 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    detail.fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF14213D), letterSpacing: -0.2),
                  ),
                ),
                if (documents.isVerified) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified_rounded, color: providerBrandBlue, size: 20)),
              ],
            ),
            const SizedBox(height: 4),
            Text(detail.categoryName, style: TextStyle(color: Colors.black.withValues(alpha: 0.45), fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text('${detail.averageRating.toStringAsFixed(1)} (${detail.totalReviews} reviews)', style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
              ],
            ),
            if (currentUser != null) ...[
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: ProfileStatBadge(
                      icon: Icons.verified_user_rounded,
                      label: 'ACCOUNT TYPE',
                      value: currentUser.role,
                      color: providerBrandBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProfileStatBadge(
                      icon: Icons.tag_rounded,
                      label: 'USER ID',
                      value: '${currentUser.userId}',
                      color: providerBrandAccent,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            const _SectionHeader('Provider Details'),
            _InfoCard(
              children: [
                ListTile(leading: const Icon(Icons.badge_rounded, color: providerBrandBlue), title: const Text('Provider ID'), subtitle: Text('${detail.uid}')),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.phone_rounded, color: providerBrandBlue), title: const Text('Mobile Number'), subtitle: Text(detail.mobileNo)),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.credit_card_rounded, color: providerBrandBlue), title: const Text('CNIC'), subtitle: Text(detail.cnic)),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.wc_rounded, color: providerBrandBlue), title: const Text('Gender'), subtitle: Text(detail.gender)),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.work_history_rounded, color: providerBrandBlue), title: const Text('Experience'), subtitle: Text('${detail.experienceYears} years')),
                if (detail.city != null && detail.city!.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.location_city_rounded, color: providerBrandBlue), title: const Text('City'), subtitle: Text(detail.city!)),
                ],
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.category_rounded, color: providerBrandBlue), title: const Text('Category'), subtitle: Text('${detail.categoryName} (ID: ${detail.categoryId})')),
                if (detail.description.isNotEmpty) ...[
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.description_rounded, color: providerBrandBlue), title: const Text('Description'), subtitle: Text(detail.description)),
                ],
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.task_alt_rounded, color: providerBrandBlue), title: const Text('Jobs Completed'), subtitle: Text('${detail.totalJobsCompleted}')),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.verified_user_rounded, color: documents.isVerified ? _verifiedGreen : Colors.orange),
                  title: const Text('Verification Status'),
                  subtitle: !documents.isVerified && documents.verificationRemarks != null && documents.verificationRemarks!.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(documents.verificationRemarks!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        )
                      : null,
                  trailing: _VerificationBadge(isVerified: documents.isVerified),
                ),
                const Divider(height: 1),
                ListTile(leading: const Icon(Icons.event_rounded, color: providerBrandBlue), title: const Text('Member Since'), subtitle: Text(formatLocalDateTime(detail.createdOn, kDatePattern))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: _SectionHeader('My Categories')),
                Consumer<ProviderCategoriesProvider>(
                  builder: (context, categoriesProvider, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (categoriesProvider.categories.length > 1) ...[
                          TextButton.icon(
                            onPressed: categoriesProvider.isSaving ? null : () => _editPrimaryCategory(context),
                            icon: const Icon(Icons.star_rounded, size: 16),
                            label: const Text('Edit Primary', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                            style: TextButton.styleFrom(foregroundColor: providerBrandBlue, padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          ),
                          const SizedBox(width: 14),
                        ],
                        TextButton.icon(
                          onPressed: categoriesProvider.isSaving ? null : () => _editCategories(context),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(foregroundColor: providerBrandBlue, padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Consumer<ProviderCategoriesProvider>(
              builder: (context, categoriesProvider, _) {
                if (categoriesProvider.isLoading && categoriesProvider.categories.isEmpty) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Center(child: CircularProgressIndicator()));
                }
                if (categoriesProvider.categories.isEmpty) {
                  return _InfoCard(
                    children: [
                      ListTile(leading: const Icon(Icons.category_rounded, color: providerBrandBlue), title: const Text('Category'), subtitle: Text('${detail.categoryName} (ID: ${detail.categoryId})')),
                    ],
                  );
                }
                return _InfoCard(
                  children: [
                    for (var i = 0; i < categoriesProvider.categories.length; i++) ...[
                      if (i != 0) const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.category_rounded, color: providerBrandBlue),
                        title: Text(categoriesProvider.categories[i].categoryName),
                        trailing: categoriesProvider.categories[i].isPrimary
                            ? const Chip(label: Text('Primary', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)), visualDensity: VisualDensity.compact)
                            : null,
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const _SectionHeader('Preferences'),
            Consumer<TimeFormatProvider>(
              builder: (context, timeFormat, _) {
                return _InfoCard(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.schedule_rounded, color: providerBrandBlue),
                      title: const Text('24-hour time'),
                      subtitle: Text(timeFormat.use24Hour ? 'e.g. 14:30' : 'e.g. 2:30 PM'),
                      value: timeFormat.use24Hour,
                      activeThumbColor: providerBrandBlue,
                      onChanged: (v) => timeFormat.setUse24Hour(v),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const _SectionHeader('Availability'),
            _InfoCard(
              children: [
                ListTile(
                  leading: Icon(dashboard.isOnline ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded, color: dashboard.isOnline ? Colors.green : Colors.grey),
                  title: const Text('Status'),
                  subtitle: Text(dashboard.isOnline ? 'Online — receiving new requests' : 'Offline'),
                  trailing: dashboard.availabilityLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Switch(
                          value: dashboard.isOnline,
                          activeThumbColor: Colors.green,
                          onChanged: (v) => toggleProviderOnlineStatus(context, v),
                        ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule_rounded, color: providerBrandBlue),
                  title: const Text('Available Timing'),
                  subtitle: Text(dashboard.availableTiming ?? detail.availableTiming ?? 'Not set'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: kProminentOutlinedButtonStyle(providerBrandBlue),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Profile'),
                onPressed: () => Navigator.of(context).pushNamed(ProviderRoutes.editProfile),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: kProminentOutlinedButtonStyle(providerBrandBlue),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('My Documents'),
                onPressed: () => Navigator.of(context).pushNamed(ProviderRoutes.verificationDocuments),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: kProminentFilledButtonStyle(providerBrandBlue),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Switch to Customer'),
                // pushReplacementNamed: don't leave the provider dashboard
                // on the stack to pop back into with stale data — switching
                // back the other way uses the mirrored "Switch to Provider"
                // button, which rebuilds it fresh.
                onPressed: () => Navigator.of(context).pushReplacementNamed(HomeScreen.routeName),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: kProminentOutlinedButtonStyle(Colors.red),
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Delete Account'),
                onPressed: () => _deleteAccount(context),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                icon: Icon(Icons.privacy_tip_outlined, color: Colors.grey[600]),
                onPressed: () => openPrivacyPolicy(context),
                label: Text('Privacy Policy', style: TextStyle(color: Colors.grey[600])),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(color: providerBrandBlue, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF14213D), letterSpacing: -0.1)),
          ],
        ),
      ),
    );
  }
}

/// White, shadowed container used for grouped [ListTile] rows, matching the
/// customer profile screen's card style (see `screens/profile_screen.dart`).
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: providerBrandDark.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// Small pill badge for the Verification Status row - green with a check
/// for a verified provider, amber/orange with an hourglass while pending.
class _VerificationBadge extends StatelessWidget {
  final bool isVerified;
  const _VerificationBadge({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? _verifiedGreen : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isVerified ? Icons.check_circle_rounded : Icons.hourglass_top_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verified' : 'Pending',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
