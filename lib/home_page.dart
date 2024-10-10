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

    if (token != null) {
      // Replace with your server address and include the token as a query parameter
      // Use the API_URL from the .env file
      final String? apiUrl = dotenv.env['LOCAL_API_SOCKET_URL'];
      final uri = Uri.parse('$apiUrl/?token=$token');

      channel = IOWebSocketChannel.connect(uri);

      channel.stream.listen((message) {
        final data = jsonDecode(message);
        setState(() {
          _number = data['number'].toString();
        });
      }, onError: (error) {
        print('WebSocket error: $error');
        removeToken();
        _showDialog(error, "Automatic login failed, so you need to login manually");
      }, onDone: () {
        print('WebSocket connection closed');
        removeToken();
        _showDialog("Connection Ended","Connection was closed from remote server");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
    } else {
      print('No JWT token found');
      // Navigate to the home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }


  Future<void> removeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('jwt_token');  // Replace 'jwt_token' with the key you want to remove
    print('JWT token removed');
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
      ),
      body: Center(
        child: Text(
          'Random Number: $_number',
          style: const TextStyle(fontSize: 24),
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
