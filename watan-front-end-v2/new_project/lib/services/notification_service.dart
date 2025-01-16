import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final String baseUrl =
      "http://172.16.0.68:5000/api/notifications"; // Replace with your API URL

  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null || token.isEmpty) {
        throw Exception('User is not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to fetch notifications: ${response.body}');
      }
    } catch (error) {
      throw Exception('Error fetching notifications: $error');
    }
  }

  // Mark a specific notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception("User is not authenticated");
      }

      final response = await http.put(
        Uri.parse('$baseUrl/read/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to mark notification as read");
      }
    } catch (error) {
      throw Exception("Error marking notification as read: $error");
    }
  }

  // Clear all notifications for a user
  Future<void> clearNotifications(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception("User is not authenticated");
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/clear/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to clear notifications");
      }
    } catch (error) {
      throw Exception("Error clearing notifications: $error");
    }
  }

  // Send a notification for a new message
  Future<void> sendMessageNotification(
      String receiverId, String senderName, String messageText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception("User is not authenticated");
      }

      final response = await http.post(
        Uri.parse('$baseUrl/message'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'receiverId': receiverId,
          'senderName': senderName,
          'messageText': messageText,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to send message notification");
      }
    } catch (error) {
      throw Exception("Error sending message notification: $error");
    }
  }

  // Send a notification for a post interaction (like or comment)
  Future<void> sendPostInteractionNotification(
      String receiverId, String postOwner, String interactionType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception("User is not authenticated");
      }

      final response = await http.post(
        Uri.parse('$baseUrl/post-interaction'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'receiverId': receiverId,
          'postOwner': postOwner,
          'interactionType': interactionType,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to send post interaction notification");
      }
    } catch (error) {
      throw Exception("Error sending post interaction notification: $error");
    }
  }

  // Send a notification for a product purchase
  Future<void> sendPurchaseNotification(
      String receiverId, String buyerName, String productName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        throw Exception("User is not authenticated");
      }

      final response = await http.post(
        Uri.parse('$baseUrl/purchase'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'receiverId': receiverId,
          'buyerName': buyerName,
          'productName': productName,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to send purchase notification");
      }
    } catch (error) {
      throw Exception("Error sending purchase notification: $error");
    }
  }
}
