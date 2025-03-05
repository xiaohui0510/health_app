import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class BleSmartWatchScreen extends StatefulWidget {
  const BleSmartWatchScreen({super.key});

  @override
  State<BleSmartWatchScreen> createState() => _BleSmartWatchScreenState();
}

class _BleSmartWatchScreenState extends State<BleSmartWatchScreen> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  DiscoveredDevice? _device;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  bool _isConnected = false;
  String _connectionStatus = "Disconnected";

  // Variables to hold raw data from the watch.
  String _heartRateData = "No HR data";
  String _batteryData = "No battery data";
  String _allServiceData = "No service data";

  @override
  void initState() {
    super.initState();
    _initPermissionsAndScan();
  }

  Future<void> _initPermissionsAndScan() async {
    // Request required permissions.
    final locationStatus = await Permission.location.request();
    final bluetoothScanStatus = await Permission.bluetoothScan.request();
    final bluetoothConnectStatus = await Permission.bluetoothConnect.request();

    if (locationStatus.isGranted &&
        bluetoothScanStatus.isGranted &&
        bluetoothConnectStatus.isGranted) {
      _startScan();
    } else {
      setState(() {
        _connectionStatus = "Required permissions not granted.";
      });
    }
  }

  // Scan for all BLE devices.
  void _startScan() {
    _scanSubscription = _ble.scanForDevices(
      withServices: [], // scan for all services
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      debugPrint("Found device: ${device.name} (id: ${device.id})");
      // Filter for devices whose name contains "Watch"
      if (device.name.isNotEmpty && device.name.contains("Watch")) {
        setState(() {
          _device = device;
        });
        _scanSubscription?.cancel();
        _connectToDevice();
      }
    }, onError: (error) {
      debugPrint("Scan error: $error");
      setState(() {
        _connectionStatus = "Scan error: $error";
      });
    });
  }

  // Connect to the discovered device.
  void _connectToDevice() {
    if (_device == null) return;
    _connectionSubscription = _ble.connectToDevice(
      id: _device!.id,
      connectionTimeout: const Duration(seconds: 10),
    ).listen((connectionUpdate) async {
      debugPrint("Connection update: ${connectionUpdate.connectionState}");
      if (connectionUpdate.connectionState == DeviceConnectionState.connected) {
        setState(() {
          _isConnected = true;
          _connectionStatus = "Connected to ${_device!.name}";
        });
        await _discoverAndProcessServices();
      } else if (connectionUpdate.connectionState ==
          DeviceConnectionState.disconnected) {
        setState(() {
          _isConnected = false;
          _connectionStatus = "Disconnected";
        });
      }
    }, onError: (error) {
      debugPrint("Connection error: $error");
      setState(() {
        _connectionStatus = "Connection error: $error";
      });
    });
  }

  // Discover services using the new API and process them.
  Future<void> _discoverAndProcessServices() async {
    try {
      // Trigger service discovery.
      await _ble.discoverAllServices(_device!.id);
      // Get the discovered services.
      final services = await _ble.getDiscoveredServices(_device!.id);
      debugPrint("Discovered ${services.length} services.");
      
      // Clear previous service data.
      _allServiceData = "";
      
      // Iterate over discovered services.
      for (int i = 0; i < services.length; i++) {
        final service = services[i];
        _allServiceData += "Service ${i + 1}: ${service.id}\n";
        for (int j = 0; j < service.characteristics.length; j++) {
          final characteristic = service.characteristics[j];
          _allServiceData += "  Characteristic ${j + 1}: ${characteristic.id} "
              "readable: ${characteristic.isReadable}, "
              "writableWithResponse: ${characteristic.isWritableWithResponse}, "
              "writableWithoutResponse: ${characteristic.isWritableWithoutResponse}, "
              "notifiable: ${characteristic.isNotifiable}, "
              "indicatable: ${characteristic.isIndicatable}\n";
          // If the characteristic is readable, try to read its value.
          if (characteristic.isReadable) {
            final qualifiedCharacteristic = QualifiedCharacteristic(
              deviceId: _device!.id,
              serviceId: service.id,
              characteristicId: characteristic.id,
            );
            try {
              final value = await _ble.readCharacteristic(qualifiedCharacteristic);
              _allServiceData += "    Value: ${value.toString()}\n";
            } catch (e) {
              _allServiceData += "    Error reading value: $e\n";
            }
          } else {
            _allServiceData += "    Not readable\n";
          }
          // Additionally, subscribe to Heart Rate characteristic if applicable.
          if (service.id.toString().toLowerCase().contains("180d") &&
              characteristic.id.toString().toLowerCase().contains("2a37")) {
            final qualifiedCharacteristic = QualifiedCharacteristic(
              deviceId: _device!.id,
              serviceId: service.id,
              characteristicId: characteristic.id,
            );
            _dataSubscription = _ble
                .subscribeToCharacteristic(qualifiedCharacteristic)
                .listen((data) {
              setState(() {
                _heartRateData = "HR Data: ${data.toString()}";
              });
            }, onError: (error) {
              debugPrint("HR subscription error: $error");
            });
          }
          // Additionally, if the service is Battery Service (180f) and characteristic is Battery Level (2a19)
          if (service.id.toString().toLowerCase().contains("180f") &&
              characteristic.id.toString().toLowerCase().contains("2a19")) {
            final qualifiedCharacteristic = QualifiedCharacteristic(
              deviceId: _device!.id,
              serviceId: service.id,
              characteristicId: characteristic.id,
            );
            try {
              final value = await _ble.readCharacteristic(qualifiedCharacteristic);
              debugPrint("Battery raw data: $value");
              setState(() {
                _batteryData = "Battery: ${value.isNotEmpty ? value[0].toString() : "N/A"}%";
              });
            } catch (e) {
              debugPrint("Error reading battery level: $e");
            }
          }
        }
      }
      debugPrint("All discovered service data:\n$_allServiceData");
      setState(() {}); // update UI
    } catch (e) {
      debugPrint("Error discovering services: $e");
    }
  }

  // Disconnect from the device.
  void _disconnectDevice() {
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    setState(() {
      _isConnected = false;
      _connectionStatus = "Disconnected";
      _heartRateData = "No HR data";
      _batteryData = "No battery data";
      _allServiceData = "No service data";
      _device = null;
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLE Smart Watch"),
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: _disconnectDevice,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_connectionStatus, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              if (_device != null) ...[
                Text("Device Name: ${_device!.name}"),
                Text("Device ID: ${_device!.id}"),
              ] else ...[
                const Text("Scanning for devices..."),
              ],
              const SizedBox(height: 20),
              Text(_heartRateData, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Text(_batteryData, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              const Text("All Service Data:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_allServiceData, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _disconnectDevice();
                  _initPermissionsAndScan();
                },
                child: const Text("Restart Scan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
