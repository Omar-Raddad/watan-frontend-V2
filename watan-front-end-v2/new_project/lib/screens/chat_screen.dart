import 'package:flutter/material.dart';
import 'package:new_project/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/message_service.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({Key? key, required this.conversationId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService messageService =
      MessageService(baseUrl: 'http://172.16.0.68:5000');
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> messages = [];
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    _fetchMessages();
  }

  Future<void> _fetchUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId =
          prefs.getString('userId'); // Assumes 'userId' is saved during login
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final data = await messageService.fetchMessages(widget.conversationId);
      setState(() {
        messages = data;
        isLoading = false;
      });
      _scrollToLatestMessage();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      // Get user details from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentUserName =
          prefs.getString('username'); // Fetch current username
      final currentUserId = prefs.getString('userId'); // Fetch current user ID

      if (currentUserName == null || currentUserId == null) {
        throw Exception("User is not logged in.");
      }

      // Send message via the message service
      await messageService.sendMessage(widget.conversationId, content);

      // Send a notification to the recipient
      final recipientId = messages.isNotEmpty
          ? messages.first.senderId == currentUserId
              ? messages.first.senderId
              : messages.first.senderId
          : null;
      print('notifaction ${recipientId}');
      if (recipientId != null) {
        final notificationService = NotificationService();
        await notificationService.sendMessageNotification(
          recipientId,
          currentUserName,
          content,
        );
      }

      // Clear the input field and refresh messages
      _messageController.clear();
      await _fetchMessages();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _scrollToLatestMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/background.jpg'), // Add your background image
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isCurrentUser =
                              message.senderId == currentUserId;
                          return _buildMessageBubble(message, isCurrentUser);
                        },
                      ),
              ),
              _buildMessageInput(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
        padding: const EdgeInsets.all(10.0),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color:
              isCurrentUser ? Colors.green[300] : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isCurrentUser
                ? const Radius.circular(12)
                : const Radius.circular(0),
            bottomRight: isCurrentUser
                ? const Radius.circular(0)
                : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isCurrentUser ? "You" : (message.senderName ?? "Unknown"),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.content,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 124, 60, 60)?.withOpacity(0.9),
        border: Border(
            top: BorderSide(color: const Color.fromARGB(255, 160, 105, 105))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                filled: true,
                fillColor: const Color.fromARGB(255, 22, 22, 22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.green,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
