import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv for configuration
import 'login_page.dart';

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

      // Establish WebSocket connection
      channel = IOWebSocketChannel.connect(uri);

      channel.stream.listen((message) {
        setState(() {
          try {
            final decoded = jsonDecode(message);
            print('Decoded Object: ' + decoded.toString());
            if (decoded['devices'] != null) {
              // Handle devices array from the server
              devices = List<Map<String, dynamic>>.from(decoded['devices']);
            } else if (decoded['type'] == 'ping') {
              final pongResponse = jsonEncode({'type': 'pong', 'message': 'pong'});
              try {
                channel.sink.add(pongResponse);
              } catch (pongErr) {
                removeToken();
                _showDialog("Connection Ended", "Connection was closed from the remote server.");
                print("Error when sending pong");
                _navigateToLogin();
              }
            }
          } catch (e) {
            print("Error parsing message: $e");
          }
        });
      }, onError: (error) {
        print('WebSocket error: $error');
        removeToken();
        _showDialog("Error", "Automatic login failed. You need to log in manually.");
      }, onDone: () {
        print('WebSocket connection closed');
        removeToken();
        _showDialog("Connection Ended", "Connection was closed from the remote server.");
        _navigateToLogin();  // Navigate back to login page when connection closes
      });
    } else {
      print('No JWT token or user ID found');
      _navigateToLogin();  // Navigate to login if no token or user ID is found
    }
  }

  // Logout function and remove JWT token
  Future<void> removeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
    print('JWT token and user ID removed');
  }

  // Function to navigate to the login page
  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Function to show the device control dialog (color picker for RGB lamp)
  void _showDevicePopup(Map<String, dynamic> device) {
    if (device['data'] == null || device['data'].isEmpty) {
      // Do not open the popup if data is null or empty
      _showDialog("Error", "Device data is not available.");
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Control ${device['deviceName']}'),
          content: device['deviceType'] == 'RGB-Lamp'
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose a color for ${device['deviceName']}'),
              ColorPicker(
                pickerColor: _currentColor,
                onColorChanged: (Color color) {
                  setState(() {
                    _currentColor = color;
                  });
                },
                pickerAreaHeightPercent: 0.8,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _setRGBColor(device);
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Set Color'),
              ),
            ],
          )
              : Text('No controls available for this device.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Function to send the selected color to the server in JSON format
  void _setRGBColor(Map<String, dynamic> device) {
    final rgb = {
      "r": _currentColor.red,
      "g": _currentColor.green,
      "b": _currentColor.blue,
    };

    // Construct the updated device object
    final updatedDevice = {
      "userId": device['userId'],
      "deviceId": device['deviceId'],
      "deviceName": device['deviceName'],
      "deviceType": device['deviceType'],
      "data": rgb, // Include updated data
    };

    final message = jsonEncode(updatedDevice);

    try {
      channel.sink.add(message); // Send the updated device state via WebSocket
      print("Updated device state sent: $message");
    } catch (e) {
      print("Error sending updated device state: $e");
      _showDialog("Error", "Failed to update the device state.");
    }
  }

  // Function to show a simple dialog for error/success messages
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

  // Build method for UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home - Monitor.IoT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              channel.sink.close(); // Close the WebSocket connection
              removeToken(); // Remove token
              _navigateToLogin(); // Navigate back to login page on logout
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: devices.isEmpty
                  ? Center(child: Text('No devices connected.'))
                  : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,  // 2 or 3 columns depending on screen width
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded corners for a modern look
                    ),
                    child: GestureDetector(
                      onTap: () => _showDevicePopup(device),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0), // Add padding inside the card
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center, // Center items inside the card
                          children: [
                            // Image based on device type
                            device['deviceType'] == 'RGB-Lamp'
                                ? Image.asset(
                              'assets/icon/RGB_Lamp.png',
                              width: 40,  // Smaller image size
                              height: 40,
                            )
                                : device['deviceType'] == 'Camera'
                                ? Icon(Icons.camera_alt, size: 40)
                                : Image.asset(
                              'assets/icon/Camera.png',
                              width: 40,
                              height: 40,
                            ),
                            SizedBox(height: 8),  // Reduce space between image and text
                            Text(
                              device['deviceName'] ?? 'Unknown Device',
                              style: TextStyle(
                                fontSize: 14,  // Smaller font size
                                fontWeight: FontWeight.w500,  // Medium weight font for better readability
                              ),
                              textAlign: TextAlign.center,  // Center text alignment
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Dispose method to clean up resources
  @override
  void dispose() {
    channel.sink.close(); // Close WebSocket connection when the widget is disposed
    super.dispose();
  }
}
