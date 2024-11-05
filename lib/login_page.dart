// lib/login_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv package

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Function to handle login action
  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    final String? apiUrl = dotenv.env['REMOTE_API_URL'];
    final url = Uri.parse('$apiUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        // Parse the JWT from the response
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String token = responseData['token'];

        // Decode the JWT to get the user ID
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          final Map<String, dynamic> decodedPayload = jsonDecode(payload);
          final String userId = decodedPayload['id'];

          // Store the token and userId locally
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setString('user_id', userId);

          // Navigate to the home page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          _showDialog('Error', 'Invalid JWT token.');
        }
      } else {
        // Handle server errors
        _showDialog('Login Failed', jsonDecode(response.body)['message']);
      }
    } catch (e) {
      // Handle network or parsing errors
      _showDialog('Error', 'An error occurred. Please try again.');
      print('Login error: $e');
    }
  }

  // Helper function to display alerts
  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Navigate to the registration page
  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor.IoT'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
          // Email input field
          TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        // Password input field
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        const SizedBox(height: 20),
        // Login button
        ElevatedButton(
          onPressed: _login,
          child: const Text('Login'),
        ),
        const SizedBox(height: 10),
        // Navigate to registration page
        TextButton(
          onPressed: _navigateToRegister,
          child: const Text('Don\'t have an account? Register here'),
          ),
          ],
        ),
      ),
    );
  }
}