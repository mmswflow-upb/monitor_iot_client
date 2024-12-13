import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class DevicePopupDialog extends StatefulWidget {
  final Map<String, dynamic> device;
  final Color currentColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onSetColorPressed;
  final ValueChanged<bool> onActiveChanged; // Callback when active state changes for camera

  const DevicePopupDialog({
    Key? key,
    required this.device,
    required this.currentColor,
    required this.onColorChanged,
    required this.onSetColorPressed,
    required this.onActiveChanged,
  }) : super(key: key);

  @override
  State<DevicePopupDialog> createState() => _DevicePopupDialogState();
}

class _DevicePopupDialogState extends State<DevicePopupDialog> {
  bool isActive = false;

  @override
  void initState() {
    super.initState();
    // Initialize isActive if device data is present and is a camera
    if (widget.device['deviceType'] == 'Camera' || widget.device['deviceType'] == 'Camera-Streamer') {
      isActive = widget.device['data']?['active'] ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (widget.device['deviceType'] == 'RGB-Lamp') {
      // RGB Lamp controls
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Choose a color for ${widget.device['deviceName']}'),
          ColorPicker(
            pickerColor: widget.currentColor,
            onColorChanged: widget.onColorChanged,
            pickerAreaHeightPercent: 0.8,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: widget.onSetColorPressed,
            child: const Text('Set Color'),
          ),
        ],
      );
    } else if (widget.device['deviceType'] == 'Camera' || widget.device['deviceType'] == 'Camera-Streamer') {
      // Camera controls
      final imageData = widget.device['data']?['imageBinaryData'];
      Uint8List? imageBytes;
      if (isActive && imageData != null) {
        imageBytes = base64Decode(imageData);
      }

      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Active Stream'),
              Switch(
                value: isActive,
                onChanged: (val) {
                  setState(() {
                    isActive = val;
                  });
                  // Notify parent about the active state change
                  widget.onActiveChanged(val);

                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isActive && imageBytes != null)
            Image.memory(
              imageBytes,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            )
          else if (isActive)
            const Text('Waiting for image...'),
          if (!isActive)
            const Text('Turn on the stream to view the image feed.'),
        ],
      );
    } else {
      // No controls available for other device types
      content = const Text('No controls available for this device.');
    }

    return AlertDialog(
      title: Text('Control ${widget.device['deviceName']}'),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
