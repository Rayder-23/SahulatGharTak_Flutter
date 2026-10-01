import 'package:flutter/foundation.dart';

import '../data/repositories/notification_repository.dart';
import '../models/app_notification.dart';
import '../utils/api_error.dart';

/// UI state for the notification inbox and the unread badge. Scoped to one
/// (userId, userType) pair at a time - [bind] switches it on login, logout and
/// role switches so a dual-role account only ever sees the active role's inbox.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider(
      {required NotificationRepository repository, this.pageSize = 20})
      : _repository = repository;

  final NotificationRepository _repository;
  final int pageSize;

  int? _userId;
  String? _userType;
  List<AppNotification> _items = [];
  int _unreadCount = 0;
  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _generation = 0;

  int? get userId => _userId;
  String? get userType => _userType;
  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get isBound => _userId != null && _userType != null;

  /// Points the provider at a user/role. A no-op when nothing changed;
  /// passing nulls clears everything (logout).
  void bind({int? userId, String? userType}) {
    if (userId == _userId && userType == _userType) return;
    _generation++;
    _userId = userId;
    _userType = userType;
    _items = [];
    _unreadCount = 0;
    _page = 0;
    _hasMore = true;
    _isLoading = false;
    _isLoadingMore = false;
    _error = null;
    notifyListeners();
    if (isBound) refreshUnread();
  }

  void clear() => bind();

  Future<void> refreshUnread() async {
    if (!isBound) return;
    final gen = _generation;
    try {
      final count = await _repository.fetchUnreadCount(
          userId: _userId!, userType: _userType!);
      if (gen != _generation) return;
      _unreadCount = count;
      notifyListeners();
    } catch (_) {
      // The badge is best-effort; keep the last known value.
    }
  }

  Future<void> loadInbox() async {
    if (!isBound || _isLoading) return;
    final gen = _generation;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repository.fetchInbox(
          userId: _userId!, userType: _userType!, page: 1, pageSize: pageSize);
      if (gen != _generation) return;
      _items = result.items;
      _unreadCount = result.unreadCount;
      _page = 1;
      _hasMore = _items.length < result.totalCount;
    } catch (e) {
      if (gen != _generation) return;
      _error = friendlyErrorMessage(e);
    } finally {
      if (gen == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (!isBound || _isLoading || _isLoadingMore || !_hasMore) return;
    final gen = _generation;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final result = await _repository.fetchInbox(
          userId: _userId!,
          userType: _userType!,
          page: _page + 1,
          pageSize: pageSize);
      if (gen != _generation) return;
      _items = [..._items, ...result.items];
      _page += 1;
      _unreadCount = result.unreadCount;
      _hasMore = result.items.isNotEmpty && _items.length < result.totalCount;
    } catch (e) {
      if (gen != _generation) return;
      _error = friendlyErrorMessage(e);
    } finally {
      if (gen == _generation) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  /// Optimistically marks one notification read, rolling back if the call fails.
  Future<void> markRead(int id) async {
    if (!isBound) return;
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1 || _items[index].isRead) return;
    final original = _items[index];
    _items = [..._items]..[index] = original.copyWith(isRead: true);
    _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
    notifyListeners();

    final gen = _generation;
    try {
      await _repository.markRead(id: id, userId: _userId!);
    } catch (_) {
      if (gen != _generation) return;
      final i = _items.indexWhere((n) => n.id == id);
      if (i != -1) _items = [..._items]..[i] = original;
      _unreadCount += 1;
      notifyListeners();
    }
  }

  Future<bool> markAllRead() async {
    if (!isBound) return false;
    final gen = _generation;
    try {
      await _repository.markAllRead(userId: _userId!, userType: _userType!);
      if (gen != _generation) return false;
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      if (gen != _generation) return false;
      _error = friendlyErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
}
