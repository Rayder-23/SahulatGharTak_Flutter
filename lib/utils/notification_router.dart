import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repositories/notification_repository.dart';
import '../models/push_event.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_service_request_provider.dart';
import '../providers/provider_bookings_provider.dart';
import '../providers/provider_dashboard_provider.dart';
import '../screens/home_screen.dart';
import '../screens/provider/jobs/booking_detail_screen.dart';
import '../screens/provider_dashboard_screen.dart';
import '../screens/request_detail_screen.dart';
import '../screens/service_requests_screen.dart';
import '../services/push_notification_service.dart';
import 'active_role_tracker.dart';
import 'provider_routes.dart';

/// Root navigator key so push taps can navigate without a BuildContext.
final navigatorKey = GlobalKey<NavigatorState>();

/// Refreshes whatever lists a push may have made stale (a request can go back
/// to "Requested", a job can be taken by someone else, etc.).
void refreshForPush(BuildContext context, PushEvent event) {
  if (!event.refreshesLists) return;
  final auth = context.read<AuthProvider>();
  if (!auth.isLoggedIn) return;
  final userType = activeRoleTracker.userTypeFor(auth);

  if (userType == 'Provider') {
    final providerUid = auth.currentUser?.providerUid;
    if (providerUid == null) return;
    context.read<ProviderBookingsProvider>().loadBookings(providerUid);
    context.read<ProviderDashboardProvider>().loadIncomingRequests(providerUid);
  } else {
    final clientUid = auth.clientUid;
    if (clientUid == null) return;
    context.read<CustomerServiceRequestProvider>().loadRequests(clientUid);
  }
}

/// Routes a tapped push (or inbox row) to the matching screen. `screen` /
/// ids come straight from the payload contract in `api.txt`.
Future<void> routeForPush(PushEvent event) async {
  final nav = navigatorKey.currentState;
  final context = navigatorKey.currentContext;
  if (nav == null || context == null) return;

  final auth = context.read<AuthProvider>();
  if (event.screen == 'app_update') {
    await _openStore(context);
    return;
  }
  if (!auth.isLoggedIn) return;

  final isProviderAccount = auth.role == 'Provider';

  switch (event.screen) {
    case 'request_details':
      final requestId = event.requestId;
      if (requestId == null) {
        nav.pushNamed(ServiceRequestsScreen.routeName);
      } else {
        nav.push(MaterialPageRoute(
            builder: (_) => RequestDetailScreen(requestUid: requestId)));
      }
    case 'provider_job_requests':
      if (!isProviderAccount) return;
      _openDashboardTab(nav, 1);
      refreshForPush(context, event);
    case 'my_bookings':
      if (!isProviderAccount) return;
      await _openBooking(nav, context, auth, event);
    default:
      nav.pushNamed(auth.role == 'Provider'
          ? ProviderRoutes.notifications
          : HomeScreen.routeName);
  }
}

void _openDashboardTab(NavigatorState nav, int tab) {
  var onDashboard = false;
  nav.popUntil((route) {
    onDashboard = route.settings.name == ProviderRoutes.dashboard;
    return onDashboard || route.isFirst;
  });
  if (!onDashboard) nav.pushNamed(ProviderDashboardScreen.routeName);
  ProviderDashboardScreen.requestTab(tab);
}

Future<void> _openBooking(NavigatorState nav, BuildContext context,
    AuthProvider auth, PushEvent event) async {
  final providerUid = auth.currentUser?.providerUid;
  final bookingId = event.bookingId;
  if (providerUid == null || bookingId == null) {
    _openDashboardTab(nav, 2);
    return;
  }
  try {
    final booking = await context
        .read<ProviderBookingsProvider>()
        .fetchBookingById(bookingId, providerUid);
    nav.push(MaterialPageRoute(
        builder: (_) => BookingDetailScreen(booking: booking)));
  } catch (_) {
    _openDashboardTab(nav, 2);
  }
}

Future<void> _openStore(BuildContext context) async {
  try {
    final config = await NotificationRepository()
        .fetchAppConfig(PushNotificationService.instance.platform);
    if (config.storeUrl.isEmpty) return;
    await launchUrl(Uri.parse(config.storeUrl),
        mode: LaunchMode.externalApplication);
  } catch (_) {
    // Nothing useful to show; the store link is best-effort.
  }
}

/// Call once the session is resolved and the first real screen is showing,
/// so a cold-start tap isn't swallowed by splash navigation.
Future<void> routeColdStartPush() async {
  final event = PushNotificationService.instance.takeInitialEvent();
  if (event != null) await routeForPush(event);
}
