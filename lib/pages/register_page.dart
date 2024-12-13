import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv package

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers for input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Function to handle registration action
  Future<void> _register() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    // Use the API_URL from the .env file
    final String? apiUrl = dotenv.env['REMOTE_API_URL'];
    final url = Uri.parse('$apiUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        // Registration successful
        _showDialog('Registration Successful', 'You can now log in.');
      } else {
        // Handle server errors
        _showDialog('Registration Failed', jsonDecode(response.body)['message']);
      }
    } catch (e) {
      // Handle network or parsing errors
      _showDialog('Error', 'An error occurred. Please try again.');
      print('Registration error: $e');
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
              onPressed: () {
                Navigator.of(context).pop();
                if (title == 'Registration Successful') {
                  Navigator.of(context).pop(); // Go back to login page
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Register - Monitor.IoT'),
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
              // Register button
              ElevatedButton(
                onPressed: _register,
                child: const Text('Register'),
              ),
            ],
          ),
        ));
  }
}
