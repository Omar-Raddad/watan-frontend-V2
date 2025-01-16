import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'RegisterScreen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService apiService = ApiService();

  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  bool _keepMeLoggedIn = false;
  bool _isLoading = false; // <-- To show a loading indicator

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  void _login() async {
    // Validate form fields first
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Retrieve FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print('FCM Token: $fcmToken');

      // Call the API to log in with FCM token
      final result = await apiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
        fcmToken,
      );

      // Check for valid token
      if (result != null && result['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', result['token']);
        await prefs.setBool('isLoggedIn', true);
        print('user ${result['user']}');
        // Store user id and username if available
        if (result['user'] != null) {
          final user = result['user'];
          if (user['id'] != null) {
            await prefs.setString('userId', user['id']);
          }
          if (user['username'] != null) {
            print("${user['username']}");
            await prefs.setString('username', user['username']);
          }
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to MainScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // Credentials are invalid or server didn't return a token
        _showErrorSnackbar('Invalid email or password.');
      }
    } catch (e) {
      // For network errors, server downtime, etc.
      _showErrorSnackbar('Could not log in. Please try again.');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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

          // Dark overlay for contrast
          Container(
            color: Colors.black.withOpacity(0.7),
          ),

          // Main content + form
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
            child: SizedBox(
              height: screenHeight, // So it covers the full screen
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.1),

                    // Logo / Title
                    Icon(
                      Icons.account_circle,
                      size: screenWidth * 0.25,
                      color: Colors.white,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.05),

                    // Email field
                    TextFormField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        // Optional: check email format
                        // final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        // if (!emailRegex.hasMatch(value.trim())) {
                        //   return 'Please enter a valid email address';
                        // }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(Icons.email, color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Password field
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Keep me logged in
                    Row(
                      children: [
                        Checkbox(
                          value: _keepMeLoggedIn,
                          onChanged: (value) {
                            setState(() => _keepMeLoggedIn = value ?? false);
                          },
                          activeColor: Colors.white,
                          checkColor: Colors.black,
                        ),
                        const Text(
                          "Keep me logged in",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // Login button
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.2,
                          vertical: screenHeight * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Text(
                        "Login",
                        style: TextStyle(fontSize: screenWidth * 0.05),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // Register
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Don't have an account? Register Now",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // If loading, show a semi-transparent overlay with a progress indicator
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
