import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService apiService = ApiService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  String gender = 'Male'; // Default gender selection
  void _register() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Passwords do not match!'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      // Retrieve FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print('FCM Token: $fcmToken');

      // Call the API to register with the FCM token
      final result = await apiService.register(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
        cityController.text.trim(),
        locationController.text.trim(),
        gender,
        fcmToken,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Registration successful: ${result['message']}'),
        backgroundColor: Colors.green,
      ));

      // Navigate back to LoginScreen
      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Registration failed: $error'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
          // Transparent overlay for contrast
          Container(
            color: Colors.black.withOpacity(0.7),
          ),
          // Main content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.1),
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Name Field
                  _buildTextField(nameController, "Name", Icons.person),
                  SizedBox(height: screenHeight * 0.02),
                  // Email Field
                  _buildTextField(emailController, "Email", Icons.email),
                  SizedBox(height: screenHeight * 0.02),
                  // Password Field
                  _buildTextField(passwordController, "Password", Icons.lock,
                      isPassword: true),
                  SizedBox(height: screenHeight * 0.02),
                  // Confirm Password Field
                  _buildTextField(
                      confirmPasswordController, "Confirm Password", Icons.lock,
                      isPassword: true),
                  SizedBox(height: screenHeight * 0.02),
                  // City Field
                  _buildTextField(cityController, "City", Icons.location_city),
                  SizedBox(height: screenHeight * 0.02),
                  // Location Field
                  _buildTextField(locationController, "Location", Icons.map),
                  SizedBox(height: screenHeight * 0.02),
                  // Gender Dropdown
                  DropdownButton<String>(
                    value: gender,
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (String? value) {
                      setState(() {
                        gender = value!;
                      });
                    },
                    items: <String>['Male', 'Female', 'Other']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  // Register Button
                  ElevatedButton(
                    onPressed: _register,
                    child: const Text("Register"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        prefixIcon: Icon(icon, color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
