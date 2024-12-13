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
    return devices.isEmpty
        ? const Center(child: Text('No devices connected.'))
        : GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: devices.length,
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
