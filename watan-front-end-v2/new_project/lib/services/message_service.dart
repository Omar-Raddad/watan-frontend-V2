import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

class MessageService {
  final String baseUrl;

  MessageService({required this.baseUrl});

  // Get the auth token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('authToken'); // Assumes token is stored as 'authToken'
  }

  // Fetch all conversations
  Future<List<Conversation>> fetchConversations() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/messaging/conversation'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Conversation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch conversations: ${response.body}');
    }
  }

  // Fetch messages for a specific conversation
  Future<List<Message>> fetchMessages(String conversationId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/messaging/conversation/$conversationId/messages'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data
          .map((json) => Message.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to fetch messages: ${response.body}');
    }
  }

  // Send a message in a conversation
  Future<void> sendMessage(String conversationId, String content) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/messaging/message'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'conversationId': conversationId,
        'content': content,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  // Start a new conversation
  Future<void> startConversation(String receiverId, String content) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/messaging/conversation'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode({'receiverId': receiverId, 'content': content}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start conversation: ${response.body}');
    }
  }
}
