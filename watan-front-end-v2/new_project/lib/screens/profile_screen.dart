import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        throw Exception("No auth token found.");
      }

      final response = await apiService.getUserProfile();
      if (response != null) {
        setState(() {
          usernameController.text = response['username'] ?? 'Username';
          emailController.text = response['email'] ?? 'Email';
          cityController.text = response['city'] ?? 'City';
          locationController.text = response['location'] ?? 'Location';
          _isLoading = false;
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $error')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _saveProfileChanges() async {
    try {
      final response = await apiService.updateUserProfile({
        "username": usernameController.text,
        "email": emailController.text,
        "city": cityController.text,
        "location": locationController.text,
      });
      if (response != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        setState(() {
          _isEditing = false;
        });
        // Save updated data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', usernameController.text);
        await prefs.setString('email', emailController.text);
        await prefs.setString('city', cityController.text);
        await prefs.setString('location', locationController.text);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.green],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // User Information
                      _buildEditableField(
                        "Username",
                        usernameController,
                        _isEditing,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        "Email",
                        emailController,
                        _isEditing,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        "City",
                        cityController,
                        _isEditing,
                      ),
                      const SizedBox(height: 16),
                      _buildEditableField(
                        "Location",
                        locationController,
                        _isEditing,
                      ),
                      const SizedBox(height: 24),
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _isEditing ? _saveProfileChanges : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Save Changes"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = !_isEditing;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(_isEditing ? "Cancel" : "Edit Profile"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
      String label, TextEditingController controller, bool isEditing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isEditing)
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: !isEditing,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
          ),
        ),
      ],
    );
  }
}
