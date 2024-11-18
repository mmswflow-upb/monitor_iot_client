// lib/home_page.dart
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv package

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _inputText = ''; // To hold the TextField input
  late IOWebSocketChannel channel;
  List<String> _messages = []; // To store received messages

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');
    String? userId = prefs.getString('user_id');

    if (token != null && userId != null) {
      final String? apiUrl = dotenv.env['LOCAL_API_SOCKET_URL'];

      if (apiUrl == null) {
        _showDialog("Error", "WebSocket URL is not set. Please check the configuration.");
        return;
      }

      String clientType = "user"; // Set the client type accordingly

      final uri = Uri.parse('$apiUrl/?token=$token&userId=$userId&type=$clientType');

      channel = IOWebSocketChannel.connect(uri);

      channel.stream.listen((message) {
        setState(() {
          // Handle all types of data (JSON, String, or Number)
          try {
            final decoded = jsonDecode(message); // Try parsing as JSON
            _messages.add('Received JSON: $decoded');
          } catch (e) {
            _messages.add('Received: $message'); // Fallback for non-JSON
          }
        });
      }, onError: (error) {
        print('WebSocket error: $error');
        removeToken();
        _showDialog("Error", "Automatic login failed, so you need to login manually");
      }, onDone: () {
        print('WebSocket connection closed');
        removeToken();
        _showDialog("Connection Ended", "Connection was closed from remote server");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
    } else {
      print('No JWT token or user ID found');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<void> removeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    print('JWT token and user ID removed');
  }

  @override
  void dispose() {
    if (channel != null) {
      channel.sink.close();
      print("WebSocket connection closed.");
    }
    super.dispose();
  }

  void _logout() async {
    if (channel != null) {
      channel.sink.close();
      print("WebSocket connection closed during logout.");
    }
    await removeToken();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _sendMessage() {
    if (_inputText.isNotEmpty) {
      try {
        channel.sink.add(_inputText); // Send the text to the WebSocket server
        print("Message sent: $_inputText");
        setState(() {
          _messages.add('Sent: $_inputText'); // Add sent message to log
          _inputText = ''; // Clear the input field after sending
        });
      } catch (e) {
        print("Error sending message: $e");
        _showDialog("Error", "Failed to send message to the server.");
      }
    } else {
      _showDialog("Error", "Input field is empty.");
    }
  }



  // Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home - Monitor.IoT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Enter a message',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _inputText = value;
                });
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text('Send Message'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_messages[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
}
