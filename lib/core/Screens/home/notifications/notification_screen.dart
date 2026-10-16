import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:foam_mobile/core/hive/hive.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:http/http.dart' as http;

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Notification',
      body: json['body'] ?? '',
      type: json['type'] ?? 'SYSTEM',
      referenceId: json['referenceId']?.toString(),
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      type: type,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(createdAt);
    }
  }

  IconData get icon {
    switch (type) {
      case 'ORDER_UPDATE':
        return Icons.local_shipping_outlined;
      case 'PAYMENT':
        return Icons.account_balance_wallet_outlined;
      case 'WALLET':
        return Icons.savings_outlined;
      case 'PROMOTION':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'ORDER_UPDATE':
        return const Color(0xFF0098A6);
      case 'PAYMENT':
        return const Color(0xFF10B981);
      case 'WALLET':
        return const Color(0xFFF59E0B);
      case 'PROMOTION':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF0098A6);
    }
  }
}

class NotificationScreen extends StatefulWidget {
  static const String id = '/notification_page';

  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final GlobalKey<ScaffoldMessengerState> scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isLoading = true;
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  String _selectedFilter = 'All'; // 'All' or 'Unread'

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Map<String, String> get _headers => {
        "Authorization": "Bearer ${HiveClass.getToken()}",
        "Accept": "application/json",
        "Content-Type": "application/json",
      };

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse("${Constants.url}/api/notifications"),
        headers: _headers,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['notifications'] as List? ?? [])
            .map((item) => NotificationItem.fromJson(item))
            .toList();

        setState(() {
          _notifications = list;
          _unreadCount = data['unreadCount'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(NotificationItem item, int index) async {
    if (item.isRead) return;

    setState(() {
      _notifications[index] = item.copyWith(isRead: true);
      if (_unreadCount > 0) _unreadCount--;
    });

    try {
      await http.patch(
        Uri.parse("${Constants.url}/api/notifications/${item.id}/read"),
        headers: _headers,
      );
    } catch (e) {
      debugPrint("Error marking notification read: $e");
    }
  }

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) return;

    setState(() {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      await http.patch(
        Uri.parse("${Constants.url}/api/notifications/read-all"),
        headers: _headers,
      );
    } catch (e) {
      debugPrint("Error marking all read: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _selectedFilter == 'Unread'
        ? _notifications.where((n) => !n.isRead).toList()
        : _notifications;

    return ScaffoldMessenger(
      key: scaffoldKey,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppColors.blackAccentColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Notifications',
            style: Constants.headingStyle.copyWith(fontSize: 18),
          ),
          actions: [
            if (_unreadCount > 0)
              TextButton(
                onPressed: _markAllAsRead,
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: AppColors.primaryAccentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('All', _notifications.length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unread', _unreadCount),
                ],
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchNotifications,
          color: AppColors.primaryAccentColor,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      itemCount: filteredNotifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filteredNotifications[index];
                        return _buildNotificationCard(item, index);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryAccentColor.withValues(alpha: 0.12)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryAccentColor
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryAccentColor
                    : const Color(0xFF4B5563),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryAccentColor
                      : const Color(0xFF9CA3AF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item, int index) {
    return InkWell(
      onTap: () => _markAsRead(item, index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : const Color(0xFFF0FDF4).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? const Color(0xFFE5E7EB)
                : AppColors.primaryAccentColor.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxExtentShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color: item.iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: const Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        item.timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: item.isRead
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
            if (!item.isRead) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryAccentColor,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryAccentColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_outlined,
                size: 56,
                color: AppColors.primaryAccentColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedFilter == 'Unread'
                  ? 'No unread notifications'
                  : 'No notifications yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'Unread'
                  ? 'You have read all your notifications.'
                  : 'We will keep you informed about order updates, payments, and special laundry offers.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoxExtentShadow extends BoxShadow {
  const BoxExtentShadow({
    super.color,
    super.offset,
    super.blurRadius,
    super.spreadRadius,
  });
}
