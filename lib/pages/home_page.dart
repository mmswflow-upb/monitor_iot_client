import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'login_page.dart';
import '../home widgets/device_grid.dart';
import '../home widgets/device_popup_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late IOWebSocketChannel channel;
  List<Map<String, dynamic>> devices = [];
  Color _currentColor = Colors.white; // Default color for the RGB lamp

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  // Connect to WebSocket
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

      String clientType = "user"; // Set client type as user

      final uri = Uri.parse('$apiUrl/?token=$token&userId=$userId&type=$clientType');

      channel = IOWebSocketChannel.connect(uri);

      channel.stream.listen((message) {
        setState(() {
          try {
            final decoded = jsonDecode(message);
            if (decoded['messageType'] == 'updateDevicesList') {
              devices = List<Map<String, dynamic>>.from(decoded['devices']);
            } else if (decoded['messageType'] == 'ping') {
              final pongResponse = jsonEncode({'messageType': 'pong', 'message': 'pong'});
              try {
                channel.sink.add(pongResponse);
              } catch (pongErr) {
                removeToken();
                _showDialog("Connection Ended", "Connection was closed from the remote server.");
                _navigateToLogin();
              }
            }
          } catch (e) {
          }
        });
      }, onError: (error) {
        removeToken();
        _showDialog("Error", "Automatic login failed. You need to log in manually.");
      }, onDone: () {
        removeToken();
        _showDialog("Connection Ended", "Connection was closed from the remote server.");
        _navigateToLogin();  // Navigate back to login page when connection closes
      });
    } else {
      _navigateToLogin();  // Navigate to login if no token or user ID is found
    }
  }

  Future<void> removeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

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

  // Called by the device card tap callback
  void _showDevicePopup(Map<String, dynamic> device) {
    if (device['data'] == null || device['data'].isEmpty) {
      _showDialog("Error", "Device data is not available.");
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DevicePopupDialog(
          device: device,
          currentColor: _currentColor,
          onColorChanged: (color) {
            setState(() {
              _currentColor = color;
            });
          },
          onSetColorPressed: () {
            _updateDeviceState(device);
            Navigator.of(context).pop();
          },
          onActiveChanged: (bool active) {
            // Update the device object locally
            device["data"]["active"] = active;

            // If you have a dedicated function to update the device on the server:
            // _updateDevice(device);

            // If the camera device doesn't need RGB updates, you could write a separate
            // function similar to _setRGBColor for updating camera states, for example:
            _updateDeviceState(device);
          },
        );
      },
    );
  }

  void _updateDeviceState(Map<String, dynamic> device) {
    try {
      // Convert the device object to a JSON string
      final message = jsonEncode({
        "deviceId": device["deviceId"],
        "deviceName": device["deviceName"],
        "deviceType": device["deviceType"],
        "data": device["data"], // Contains "active" or other data
      });

      // Send the JSON message via WebSocket
      channel.sink.add(message);

      print("Updated device state sent: $message");
    } catch (e) {
      print("Error sending updated device state: $e");
      _showDialog("Error", "Failed to update the device state.");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home - Monitor.IoT'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              channel.sink.close();
              removeToken();
              _navigateToLogin();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DeviceGrid(
          devices: devices,
          onDeviceTap: _showDevicePopup,
        ),
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }
}
