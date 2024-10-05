import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(LocationApp());

class LocationApp extends StatefulWidget {
  @override
  _LocationAppState createState() => _LocationAppState();
}

class _LocationAppState extends State<LocationApp> {
  Position? _currentPosition;
  String _locationMessage = 'Getting location...';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Method to get the current location
  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = "Location services are disabled.";
      });
      return;
    }

    // Check and request location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = "Location permissions are denied.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage = "Location permissions are permanently denied.";
      });
      return;
    }

    // Get current position
    Geolocator.getPositionStream().listen(
      (Position position) {
        setState(() {
          _currentPosition = position;
          _locationMessage =
              'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
        });
      },
      onError: (e) {
        setState(() {
          _locationMessage = 'Error: ${e.toString()}';
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Location Tracker'),
        ),
        body: Center(
          child: _currentPosition == null
              ? Text(_locationMessage) // Show message if location is not available
              : Text(_locationMessage), // Show updated location data
        ),
      ),
    );
  }
}
