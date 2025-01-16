import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CheckpointService {
  final String baseUrl;

  CheckpointService({required this.baseUrl});

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs
        .getString('authToken'); // Assumes the token is stored as 'authToken'
  }

  Future<List<dynamic>> getCheckpoints() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/checkpoints/nearby?lng=35.2137&lat=31.7683&distance=4000'),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['checkpoints'];
      } else {
        throw Exception('Failed to load checkpoints: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching checkpoints: $e');
    }
  }

  Future<Map<String, dynamic>> getCheckpointDetails(String checkpointId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/checkpoints/$checkpointId'),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['checkpoint'];
      } else {
        throw Exception('Failed to load checkpoint details: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching checkpoint details: $e');
    }
  }

  Future<void> addReview(
      String checkpointId, Map<String, dynamic> reviewData) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/checkpoints/$checkpointId/reviews'),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode(reviewData),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add review: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding review: $e');
    }
  }
}
