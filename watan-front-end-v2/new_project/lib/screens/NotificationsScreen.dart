import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService notificationService = NotificationService();
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        throw Exception('User ID not found in SharedPreferences');
      }

      notifications = await notificationService.fetchNotifications(userId);
    } catch (error) {
      setState(() {
        hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load notifications: $error')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _clearNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      await notificationService.clearNotifications(userId!);
      setState(() {
        notifications.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications cleared')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing notifications: $error')),
      );
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await notificationService.markNotificationAsRead(notificationId);
      setState(() {
        notifications.removeWhere((notif) => notif['_id'] == notificationId);
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notification as read: $error')),
      );
    }
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final String type = notification['type'] ?? 'default';
    final IconData icon;
    final Color color;

    // Determine icon and color based on notification type
    switch (type) {
      case 'purchase':
        icon = Icons.shopping_cart;
        color = Colors.blue;
        break;
      case 'message':
        icon = Icons.message;
        color = Colors.green;
        break;
      case 'post_interaction':
        icon = Icons.thumb_up;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3.0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          notification['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          notification['body'],
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () => _markAsRead(notification['_id']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(
                  child: Text(
                    'Failed to load notifications',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              : notifications.isEmpty
                  ? const Center(
                      child: Text(
                        'No notifications available',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
    );
  }
}
