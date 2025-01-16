import 'package:flutter/material.dart';
import 'package:new_project/services/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:new_project/services/post_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  const PostDetailsScreen({Key? key, required this.post}) : super(key: key);

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final Map<String, TextEditingController> _replyControllers = {};
  bool isAddingComment = false;
  String? activeReplyCommentId; // Tracks which comment is being replied to
  final NotificationService _notificationService = NotificationService();

  String _getImageUrl(String imagePath) {
    const String baseUrl = "http://172.16.0.68:5000"; // Your backend URL
    return "$baseUrl$imagePath";
  }

  String _formatTimestamp(DateTime timestamp) {
    return timeago.format(timestamp);
  }

  void _addComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    setState(() {
      isAddingComment = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return;

      // Add comment to the post
      await PostService().addComment(widget.post.id, commentText, token);
      final username =
          prefs.getString('username'); // Assuming username is stored

      // Notify the post owner
      await _notificationService.sendPostInteractionNotification(
        widget.post.userId, // Post owner's ID
        username!, // Post owner's username
        "comment", // Interaction type
      );

      // Fetch updated post
      final updatedPost =
          await PostService().fetchPostById(widget.post.id, token);

      setState(() {
        widget.post.comments.clear();
        widget.post.comments.addAll(updatedPost.comments);
        _commentController.clear();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment: $error')),
      );
    } finally {
      setState(() {
        isAddingComment = false;
      });
    }
  }

  void _addReply(String commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username'); // Assuming username is stored

    final replyText = _replyControllers[commentId]?.text.trim();
    if (replyText == null || replyText.isEmpty) return;

    setState(() {
      activeReplyCommentId = commentId;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return;

      // Find the owner of the comment
      final commentOwner = widget.post.comments
          .firstWhere((comment) => comment.id == commentId)
          .userId;

      // Add reply to the comment
      await PostService().addReply(widget.post.id, commentId, replyText, token);

      // Notify the comment owner
      await _notificationService.sendPostInteractionNotification(
        commentOwner, // Post owner's ID
        username!, "reply", // Interaction type
      );

      // Fetch updated post
      final updatedPost =
          await PostService().fetchPostById(widget.post.id, token);

      setState(() {
        widget.post.comments.clear();
        widget.post.comments.addAll(updatedPost.comments);
        _replyControllers[commentId]?.clear();
        activeReplyCommentId = null;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add reply: $error')),
      );
    } finally {
      setState(() {
        activeReplyCommentId = null;
      });
    }
  }

  void _openGallery(BuildContext context, List<String> images, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: index),
                itemCount: images.length,
                itemBuilder: (context, pageIndex) {
                  return InteractiveViewer(
                    child: Image.network(
                      _getImageUrl(images[pageIndex]),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(
        title: Text('${post.username}\'s Post'),
        backgroundColor: Colors.green,
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text(post.username[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.username,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          _formatTimestamp(post.createdAt),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Post content
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                // Post images
                // Post images
                if (post.images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: post.images.length == 1
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.network(
                              _getImageUrl(post.images.first),
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // Two images per row
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                            ),
                            itemCount: post.images.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () =>
                                    _openGallery(context, post.images, index),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: Image.network(
                                    _getImageUrl(post.images[index]),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: Colors.grey,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.white,
                                          size: 50,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                const SizedBox(height: 20),
                // Comments Section Header
                const Text(
                  'Comments',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black),
                ),
                const Divider(thickness: 1.0, color: Colors.grey),
                const SizedBox(height: 10),
                // Comments Section
                if (post.comments.isEmpty)
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'No comments yet. Be the first to comment!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                if (post.comments.isNotEmpty)
                  ...post.comments.map((comment) => _buildCommentCard(comment)),
                const SizedBox(height: 20),
                // Add Comment Section
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: isAddingComment ? null : _addComment,
                      icon: Icon(
                        Icons.send,
                        color: isAddingComment ? Colors.grey : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCard(Comment comment) {
    // Initialize reply controller for each comment
    if (!_replyControllers.containsKey(comment.id)) {
      _replyControllers[comment.id] = TextEditingController();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(comment.username[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Text(
                  comment.username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(comment.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Comment content
            Text(
              comment.text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            // Replies Section
            if (comment.replies.isNotEmpty)
              ...comment.replies
                  .map((reply) => _buildReplyCard(reply, comment.id)),
            // Add Reply Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    activeReplyCommentId =
                        activeReplyCommentId == comment.id ? null : comment.id;
                  });
                },
                child: Text(
                  activeReplyCommentId == comment.id ? 'Cancel' : 'Reply',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ),
            // Reply Input Field (if active)
            if (activeReplyCommentId == comment.id)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyControllers[comment.id],
                      decoration: InputDecoration(
                        hintText: 'Write a reply...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _addReply(comment.id),
                    icon: const Icon(
                      Icons.send,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyCard(Reply reply, String commentId) {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0, top: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade400,
            radius: 16,
            child: Text(reply.username[0].toUpperCase(),
                style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reply.username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  reply.text,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatTimestamp(reply.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
