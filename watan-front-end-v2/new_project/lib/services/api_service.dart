import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "http://172.16.0.68:5000";

  Future<dynamic> login(String email, String password, String? fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "fcmToken": fcmToken, // Include FCM token in the request
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error logging in: $e');
    }
  }

  Future<dynamic> register(String username, String email, String password,
      String city, String location, String gender, String? fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
          "city": city,
          "location": location,
          "gender": gender,
          "fcmToken": fcmToken, // Include FCM token in the request
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body); // Handle success
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error registering user: $e');
    }
  }

  Future<dynamic> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.put(
        Uri.parse('$baseUrl/api/auth/profile'),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<dynamic> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) throw Exception('No token found.');

    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch profile: ${response.body}');
    }
  }
}
