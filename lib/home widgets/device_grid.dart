import 'package:flutter/material.dart';
import 'device_card.dart';

class DeviceGrid extends StatelessWidget {
  final List<Map<String, dynamic>> devices;
  final Function(Map<String, dynamic>) onDeviceTap;

  const DeviceGrid({
    Key? key,
    required this.devices,
    required this.onDeviceTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // A simple grid layout: 2 columns, can be adjusted as needed
    return GridView.builder(
      itemCount: devices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final device = devices[index];
        return DeviceCard(
          device: device,
          onTap: () => onDeviceTap(device),
        );
      },
    );
  }
}
