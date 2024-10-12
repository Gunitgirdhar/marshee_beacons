import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BeaconScannerPage(),
    );
  }
}

class BeaconScannerPage extends StatefulWidget {
  @override
  _BeaconScannerPageState createState() => _BeaconScannerPageState();
}

class _BeaconScannerPageState extends State<BeaconScannerPage> {
  StreamSubscription<RangingResult>? _beaconSubscription;
  final List<Beacon> _beacons = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _initializeBeaconScanner();
  }

  Future<void> _initializeBeaconScanner() async {
    // Request Bluetooth and Location permissions.
    final locationStatus = await Permission.locationWhenInUse.request();
    final bluetoothStatus = await Permission.bluetooth.request();

    if (locationStatus.isGranted && bluetoothStatus.isGranted) {
      try {
        // Initialize Flutter Beacon.
        await flutterBeacon.initializeScanning;

        // Define the region to scan.
        final region = Region(identifier: 'com.example.region');

        // Start the beacon scan if not already running.
        if (!_scanning) {
          _beaconSubscription = flutterBeacon.ranging([region]).listen(
                (RangingResult result) {
              setState(() {
                _beacons.clear();
                _beacons.addAll(result.beacons);
              });
            },
            onError: (e) {
              print('Error during beacon scanning: $e');
              _showSnackBar('Error during scanning.');
            },
          );
          setState(() {
            _scanning = true;
          });
        }
      } catch (e) {
        print('Initialization error: $e');
        _showSnackBar('Failed to initialize beacon scanner.');
      }
    } else {
      _showSnackBar('Permissions are required!');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    // Cancel beacon scanning when the widget is disposed.
    _beaconSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beacon Scanner'),
      ),
      body: _beacons.isEmpty
          ? const Center(child: Text('No beacons found.'))
          : ListView.builder(
        itemCount: _beacons.length,
        itemBuilder: (context, index) {
          final beacon = _beacons[index];
          return ListTile(
            title: Text('UUID: ${beacon.proximityUUID}'),
            subtitle: Text(
                'Major: ${beacon.major}, Minor: ${beacon.minor}, RSSI: ${beacon.rssi}'),
          );
        },
      ),
    );
  }
}
