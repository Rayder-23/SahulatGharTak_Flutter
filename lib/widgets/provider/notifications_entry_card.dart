import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';

/// Small tappable banner on the Home tab that opens the notifications page.
class NotificationsEntryCard extends StatelessWidget {
  final VoidCallback onTap;

  const NotificationsEntryCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.deepPurple.withValues(alpha: 0.1), width: 1),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF0A4FA8).withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6))
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.deepPurple, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Notifications',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1A2233))),
              ),
              Builder(builder: (context) {
                final unread = context
                    .select<NotificationProvider, int>((n) => n.unreadCount);
                if (unread == 0) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700)),
                );
              }),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
