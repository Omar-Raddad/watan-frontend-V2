class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'],
      conversationId: json['conversation'],
      senderId: json['sender']['_id'], // Ensure correct mapping
      senderName: json['sender']['username'], // Ensure correct mapping
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
