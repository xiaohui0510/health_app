import 'package:flutter/material.dart';
import 'package:flutter_smart_watch/flutter_smart_watch.dart';

class WearableSupportScreen extends StatefulWidget {
  const WearableSupportScreen({super.key});

  @override
  State<WearableSupportScreen> createState() => _WearableSupportScreenState();
}

class _WearableSupportScreenState extends State<WearableSupportScreen> {
  bool isWearOSSupported = false;
  bool isWatchOSSupported = false;

  final FlutterWatchOsConnectivity _flutterWatchOsConnectivity =
      FlutterSmartWatch().watchOS;
  final FlutterWearOsConnectivity _flutterWearOsConnectivity =
      FlutterSmartWatch().wearOS;

  @override
  void initState() {
    super.initState();
    _checkWearableSupport();
  }

  Future<void> _checkWearableSupport() async {
    bool wearOS = await _flutterWearOsConnectivity.isSupported();
    bool watchOS = await _flutterWatchOsConnectivity.isSupported();

    setState(() {
      isWearOSSupported = wearOS;
      isWatchOSSupported = watchOS;
    });

    print("WearOS Supported: $isWearOSSupported");
    print("WatchOS Supported: $isWatchOSSupported");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wearable Support")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isWearOSSupported || isWatchOSSupported
                  ? Icons.check_circle
                  : Icons.cancel,
              color: isWearOSSupported || isWatchOSSupported
                  ? Colors.green
                  : Colors.red,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              "WearOS Supported: $isWearOSSupported",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "WatchOS Supported: $isWatchOSSupported",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Back"),
            ),
          ],
        ),
      ),
    );
  }
}
