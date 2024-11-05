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
  String _number = '';
  late IOWebSocketChannel channel;

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
      final String? apiUrl = dotenv.env['REMOTE_API_SOCKET_URL'];

      if (apiUrl == null) {
        _showDialog("Error", "WebSocket URL is not set. Please check the configuration.");
        return;
      }

      String clientType = "user"; // Set the client type accordingly

      final uri = Uri.parse('$apiUrl/?token=$token&userId=$userId&type=$clientType');

      channel = IOWebSocketChannel.connect(uri);

      channel.stream.listen((message) {
        final data = jsonDecode(message);
        setState(() {
          _number = data['number'].toString();
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

  void _logout() async {
    await removeToken();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Random Number: $_number',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _logout,
              child: const Text('Log Out'),
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
