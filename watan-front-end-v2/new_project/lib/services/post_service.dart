import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class PostService {
  final String baseUrl = "http://172.16.0.68:5000";
  Future<void> createPost(
      String content, List<File> images, String token) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/api/posts'));

    // Add headers and fields
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['content'] = content;

    // Add all selected image files
    for (File image in images) {
      try {
        final imageFile =
            await http.MultipartFile.fromPath('images', image.path);
        request.files.add(imageFile);
      } catch (e) {
        print('Error adding image file: $e');
        throw Exception('Failed to attach one or more image files.');
      }
    }

    // Send the request and debug the response
    final response = await request.send();

    // Read the full response
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode != 201) {
      throw Exception('Failed to create post: $responseBody');
    }
  }

  Future<List<Post>> fetchPosts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/posts'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      // Log the raw API response

      return (jsonData as List)
          .map((post) => Post.fromJson(post as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to fetch posts: ${response.body}');
    }
  }

  // Fetch Single Post by ID
  Future<Post> fetchPostById(String postId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/posts/$postId'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return Post.fromJson(jsonData as Map<String, dynamic>);
    } else {
      throw Exception('Failed to fetch post: ${response.body}');
    }
  }

  // React to Post
  Future<void> reactToPost(
      String postId, String token, String reactionType) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/posts/$postId/react'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"type": reactionType}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to react to post: ${response.body}');
    }
  }

  // Add Comment
  Future<void> addComment(String postId, String text, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/posts/$postId/comment'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add comment: ${response.body}');
    }
  }

  // React to Comment

  // Add Reply to Comment
  Future<void> addReply(
      String postId, String commentId, String text, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/posts/$postId/comment/$commentId/reply'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add reply: ${response.body}');
    }
  }

  // React to Comment
  Future<void> reactToComment(String postId, String commentId, String token,
      String reactionType) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/posts/$postId/comment/$commentId/reaction'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"type": reactionType}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to react to comment: ${response.body}');
    }
  }

// React to Reply
  Future<void> reactToReply(String postId, String commentId, String replyId,
      String token, String reactionType) async {
    final response = await http.put(
      Uri.parse(
          '$baseUrl/api/posts/$postId/comment/$commentId/reply/$replyId/reaction'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"type": reactionType}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to react to reply: ${response.body}');
    }
  }
}
