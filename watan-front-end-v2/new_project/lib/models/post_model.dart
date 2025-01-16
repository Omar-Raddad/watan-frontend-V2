class Post {
  final String id;
  final String content;
  final List<String> images;
  final String username;
  final String userId;
  final DateTime createdAt;
  final List<Reaction> reactions;
  final List<Comment> comments;

  Post({
    required this.id,
    required this.content,
    required this.images,
    required this.username,
    required this.userId,
    required this.createdAt,
    required this.reactions,
    required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] ?? '',
      content: json['content'] ?? '',
      images: (json['images'] != null && json['images'] is List)
          ? List<String>.from(json['images'])
          : [],
      username: json['user'] != null && json['user']['username'] != null
          ? json['user']['username']
          : 'Unknown User',
      userId: json['user'] != null && json['user']['_id'] != null
          ? json['user']['_id']
          : '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      reactions: (json['reactions'] != null && json['reactions'] is List)
          ? (json['reactions'] as List)
              .map((reaction) => Reaction.fromJson(reaction))
              .toList()
          : [],
      comments: (json['comments'] != null && json['comments'] is List)
          ? (json['comments'] as List)
              .map((comment) => Comment.fromJson(comment))
              .toList()
          : [],
    );
  }
}

class Reaction {
  final String type; // like, love, angry, happy
  final String userId;
  final String username; // Added username for better display

  Reaction({
    required this.type,
    required this.userId,
    required this.username,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      type: json['type'],
      userId: json['user']['_id'],
      username: json['user']['username'],
    );
  }
}

class Comment {
  final String id;
  final String text;
  final String username;
  final String userId;
  final DateTime createdAt;
  final List<Reaction> reactions;
  final List<Reply> replies;

  Comment({
    required this.id,
    required this.text,
    required this.username,
    required this.userId,
    required this.createdAt,
    required this.reactions,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['_id'],
      text: json['text'],
      username: json['user']['username'],
      userId: json['user']['_id'],
      createdAt: DateTime.parse(json['createdAt']),
      reactions: json['reactions'] != null
          ? (json['reactions'] as List)
              .map((reaction) => Reaction.fromJson(reaction))
              .toList()
          : [],
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((reply) => Reply.fromJson(reply))
              .toList()
          : [],
    );
  }
}

class Reply {
  final String id;
  final String text;
  final String username;
  final String userId;
  final DateTime createdAt;
  final List<Reaction> reactions;

  Reply({
    required this.id,
    required this.text,
    required this.username,
    required this.userId,
    required this.createdAt,
    required this.reactions,
  });

  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      id: json['_id'],
      text: json['text'],
      username: json['user']['username'],
      userId: json['user']['_id'],
      createdAt: DateTime.parse(json['createdAt']),
      reactions: json['reactions'] != null
          ? (json['reactions'] as List)
              .map((reaction) => Reaction.fromJson(reaction))
              .toList()
          : [],
    );
  }
}
