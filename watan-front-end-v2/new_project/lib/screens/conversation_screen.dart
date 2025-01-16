import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation_model.dart';
import '../services/message_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final MessageService messageService =
      MessageService(baseUrl: 'http://172.16.0.68:5000');
  List<Conversation> conversations = [];
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeUserIdAndFetchConversations();
  }

  Future<void> _initializeUserIdAndFetchConversations() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('userId');

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get current user ID')),
      );
      return;
    }

    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    try {
      final fetchedConversations = await messageService.fetchConversations();

      setState(() {
        conversations = fetchedConversations;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load conversations: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];

                    // Safely identify the other participant
                    final otherParticipant =
                        conversation.participants.firstWhere(
                      (participant) => participant.id != currentUserId,
                      orElse: () => Participant(
                        id: '',
                        username: 'Unknown User',
                        avatarUrl: null,
                      ),
                    );

                    // Wrap each ListTile in a Container with decoration for a “card-like” effect
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 112, 45, 43)
                            .withOpacity(0.75),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundImage: otherParticipant.avatarUrl != null
                              ? NetworkImage(otherParticipant.avatarUrl!)
                              : const AssetImage('assets/user.png')
                                  as ImageProvider,
                          backgroundColor:
                              const Color.fromARGB(255, 126, 70, 70),
                          radius: 24,
                        ),
                        title: Text(
                          otherParticipant.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          // Safely access the last message content
                          conversation.lastMessage?.content ??
                              'No messages yet',
                          style: const TextStyle(color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                conversationId: conversation.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
