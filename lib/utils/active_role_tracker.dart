import 'dart:async';

import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import 'provider_routes.dart';

/// Which role a dual-role (Provider) account is currently *using*. The auth
/// role alone can't say - a provider can open the customer shell and back -
/// so [RoleNavigatorObserver] derives it from which root screen is on top.
class ActiveRoleTracker extends ChangeNotifier {
  String? _role;
  String? get role => _role;

  void set(String? role) {
    if (role == null || role == _role) return;
    _role = role;
    // Navigator observers fire mid-build; defer so listeners can rebuild.
    scheduleMicrotask(notifyListeners);
  }

  void reset() {
    if (_role == null) return;
    _role = null;
    scheduleMicrotask(notifyListeners);
  }

  /// The `userType` notifications should use for [auth]'s account.
  String userTypeFor(AuthProvider auth) =>
      auth.role == 'Provider' ? (_role ?? 'Provider') : 'Client';
}

final activeRoleTracker = ActiveRoleTracker();

class RoleNavigatorObserver extends NavigatorObserver {
  RoleNavigatorObserver(this._tracker);
  final ActiveRoleTracker _tracker;

  void _visit(Route<dynamic>? route) {
    switch (route?.settings.name) {
      case ProviderRoutes.dashboard:
        _tracker.set('Provider');
      case HomeScreen.routeName:
        _tracker.set('Client');
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _visit(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _visit(newRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _visit(previousRoute);
}
