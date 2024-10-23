// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';

// void main() => runApp(LocationTrackingApp());

// class LocationTrackingApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: LiveLocationScreen(),
//     );
//   }
// }

// class LiveLocationScreen extends StatefulWidget {
//   @override
//   _LiveLocationScreenState createState() => _LiveLocationScreenState();
// }

// class _LiveLocationScreenState extends State<LiveLocationScreen> {
//   Completer<GoogleMapController> _controller = Completer();
//   LatLng _currentPosition = LatLng(37.7749, -122.4194); // Default position (San Francisco)
//   StreamSubscription<Position>? _positionStream;
//   bool _isTracking = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkPermissionAndStartTracking();
//   }

//   Future<void> _checkPermissionAndStartTracking() async {
//     var status = await Permission.location.request();

//     if (status.isGranted) {
//       _startLocationTracking();
//     } else {
//       print("Location permission denied");
//     }
//   }

// // void _startLocationTracking() async {
// //   LocationSettings locationSettings = LocationSettings(
// //     accuracy: LocationAccuracy.high,
// //     distanceFilter: 4 // Minimum distance in meters to receive updates
// //   );

// //   // Listen to the location updates
// //   _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
// //       .listen((Position newPosition) {
// //     print("Received new position: $newPosition"); // Debug line
// //     if (newPosition != null) {
// //       setState(() {
// //         _currentPosition = LatLng(newPosition.latitude, newPosition.longitude);
// //       });
// //       _updateMapLocation(_currentPosition);
// //     }
// //   }, onError: (error) {
// //     print("Error in location stream: $error"); // Log any errors
// //   });
// // }

// void _startLocationTracking() async {
//   LocationSettings locationSettings = LocationSettings(
//     accuracy: LocationAccuracy.high,
//     distanceFilter: 3,
//   );

//   _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
//       .listen((Position newPosition) {
//     if (newPosition != null) {
//       setState(() {
//         _currentPosition = LatLng(newPosition.latitude, newPosition.longitude);
//         _updateMapLocation(_currentPosition); // Ensure map is updated
//       });
//     }
//   });
// }



// Future<void> _updateMapLocation(LatLng position) async {
//   final GoogleMapController controller = await _controller.future;
//   controller.animateCamera(CameraUpdate.newLatLng(position)); // Animate camera to new position
// }



//   @override
//   void dispose() {
//     _positionStream?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Live Location Tracking'),
//       ),
//       body: GoogleMap(
//         initialCameraPosition: CameraPosition(
//           target: _currentPosition,
//           zoom: 15.0,
//         ),
//         onMapCreated: (GoogleMapController controller) {
//           _controller.complete(controller);
//         },
//         myLocationEnabled: true,
//         myLocationButtonEnabled: true,
//         markers: {
//           Marker(
//             markerId: MarkerId('currentLocation'),
//             position: _currentPosition,
//             infoWindow: InfoWindow(title: 'You are here'),
//           )
//         },
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() => runApp(LocationTrackingApp());

class LocationTrackingApp extends StatelessWidget {
  const LocationTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LiveLocationScreen(),
    );
  }
}

class LiveLocationScreen extends StatefulWidget {
  const LiveLocationScreen({super.key});

  @override
  _LiveLocationScreenState createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng _currentPosition = LatLng(37.7749, -122.4194); // Default position (San Francisco)
  LatLng? _destination;
  final Polyline _polyline = Polyline(polylineId: PolylineId('path'), points: []);
  List<LatLng> _routePoints = [];
  int _routeIndex = 0;
  Timer? _simulationTimer;
  bool _isSimulating = false;
  final _addressController = TextEditingController();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final String _googleApiKey = "AIzaSyD8SKqoDKMzVOfDL2G0AoYW6VDJX0BbBME"; // Replace with your API key

  @override
  void initState() {
    super.initState();
    _checkPermissionAndStartTracking();
    _initializeNotificationPlugin();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  /// Initialize notification plugin
  void _initializeNotificationPlugin() {
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iOS = DarwinInitializationSettings();
    final settings = InitializationSettings(android: android, iOS: iOS);
    _flutterLocalNotificationsPlugin.initialize(settings);
  }

  /// Show notification when arrived at destination
  Future<void> _showArrivalNotification() async {
    const androidDetails = AndroidNotificationDetails('channel_id', 'channel_name', importance: Importance.max);
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _flutterLocalNotificationsPlugin.show(0, 'Arrival', 'You have arrived at your destination', notificationDetails);
  }

  /// Check permissions and start getting current location
  Future<void> _checkPermissionAndStartTracking() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      if (kDebugMode) print("Location permission denied");
    }
  }

  /// Get current location
  Future<void> _getCurrentLocation() async {
   Position position = await Geolocator.getCurrentPosition(
    locationSettings: LocationSettings(
      accuracy: LocationAccuracy.high,
      ),
    );
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    _updateMapLocation(_currentPosition);
  }

  /// Update the map camera to follow the current position
  Future<void> _updateMapLocation(LatLng position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(position));
  }

  /// Get route points from current location to destination
  Future<void> _getRoutePoints(LatLng origin, LatLng destination) async {
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_googleApiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final points = data['routes'][0]['overview_polyline']['points'];
      _routePoints = _decodePolyline(points);
      _startDrivingSimulation(); // Start simulation after fetching route
    } else {
      if (kDebugMode) print("Failed to get directions");
    }
  }

  /// Decode polyline points into LatLng list
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  /// Simulate driving along the route
  void _startDrivingSimulation() {
    _simulationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_routeIndex < _routePoints.length) {
        setState(() {
          _currentPosition = _routePoints[_routeIndex];
          _updateMapLocation(_currentPosition);
          _routeIndex++;
          if (_routeIndex == _routePoints.length) {
            _showArrivalNotification(); // Show arrival notification
            _simulationTimer?.cancel();
            setState(() {
              _isSimulating = false; // End simulation
            });
          }
        });
      }
    });
  }

  /// Search for an address and set it as the destination
  Future<void> _searchAddress(String address) async {
    String url = "https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$_googleApiKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        LatLng destination = LatLng(
          data['results'][0]['geometry']['location']['lat'],
          data['results'][0]['geometry']['location']['lng'],
        );
        setState(() {
          _destination = destination;
        });
        await _getRoutePoints(_currentPosition, _destination!);
        setState(() {
          _isSimulating = true; // Start simulation
        });
      }
    } else {
      if (kDebugMode) print("Failed to search address");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driving Simulation'),
        actions: [
          if (_isSimulating)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () {
                _simulationTimer?.cancel();
                setState(() {
                  _isSimulating = false;
                });
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14.0,
            ),
            myLocationEnabled: true, // Enable user location on the map
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: {
              Marker(
                markerId: const MarkerId('currentLocation'),
                position: _currentPosition,
                infoWindow: const InfoWindow(title: 'You are here'),
              ),
              if (_destination != null)
                Marker(
                  markerId: const MarkerId('destination'),
                  position: _destination!,
                  infoWindow: const InfoWindow(title: 'Destination'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ),
            },
            polylines: {_polyline}, // Show the path
          ),
          Positioned(
            top: 20,
            right: 20,
            left: 20,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: "Enter destination address",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: () {
                    if (_addressController.text.isNotEmpty) {
                      _searchAddress(_addressController.text);
                    }
                  },
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
