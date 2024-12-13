import 'package:flutter/material.dart';
import 'package:monitor_iot_client/pages/home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv package

void main() async {
  await dotenv.load(fileName: ".env"); // Load environment variables
  runApp(const MonitorIoTApp());
}

class MonitorIoTApp extends StatelessWidget {
  const MonitorIoTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Monitor.IoT',
      home: HomePage(),
    );
  }
}
