import 'message_model.dart';

class Conversation {
  final String id;
  final List<Participant> participants;
  final Message? lastMessage; // <-- Now a Message object

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'],
      participants: (json['participants'] as List)
          .map((item) => Participant.fromJson(item))
          .toList(),
      lastMessage: json['lastMessage'] == null
          ? null
          : Message.fromJson(json['lastMessage']), // Parse as Message
    );
  }
}

class Participant {
  final String id;
  final String username;
  final String? avatarUrl;

  Participant({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['_id'],
      username: json['username'],
      avatarUrl: json['avatarUrl'],
    );
  }
}
