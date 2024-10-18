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
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

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
  LatLng _currentPosition = LatLng(37.7749, -122.4194); // Default position
  LatLng? _destination; // Destination selected by user
  StreamSubscription<Position>? _positionStream;
  final List<LatLng> _pathCoordinates = []; // To store the path points
  Polyline _polyline = Polyline(polylineId: PolylineId('path'), points: []);
  bool _isSimulating = false; // Variable to track simulation mode
  List<LatLng> _routePoints = []; // Route points from Google Directions API
  int _routeIndex = 0; // Index to move along the route
  Timer? _simulationTimer;

  final String _googleApiKey = "AIzaSyD8SKqoDKMzVOfDL2G0AoYW6VDJX0BbBME"; // Add your Google Maps API Key

  @override
  void initState() {
    super.initState();
    _checkPermissionAndStartTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }

  /// Check permissions and start tracking the location
  Future<void> _checkPermissionAndStartTracking() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      _startLocationTracking();
    } else {
      print("Location permission denied");
    }
  }

  /// Start real-time location tracking with high accuracy
  void _startLocationTracking() async {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, // Highest accuracy
      distanceFilter: 0, // No filtering, get every update
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position newPosition) {
      if (!_isSimulating) {
        setState(() {
          _currentPosition = LatLng(newPosition.latitude, newPosition.longitude);
          _pathCoordinates.add(_currentPosition); // Add to the path
          _updateMapLocation(_currentPosition);
          _updatePath();
        });
      }
    });
  }

  /// Get directions from current location to a destination using Google Directions API
  Future<void> _getRoutePoints(LatLng origin, LatLng destination) async {
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_googleApiKey";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final points = data['routes'][0]['overview_polyline']['points'];
      _routePoints = _decodePolyline(points); // Decode polyline to get route points
    } else {
      print("Failed to get directions");
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

  /// Simulate movement along the route
  void _startDrivingSimulation() {
    if (_routePoints.isNotEmpty) {
      _simulationTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
        if (_routeIndex < _routePoints.length) {
          setState(() {
            _currentPosition = _routePoints[_routeIndex];
            _pathCoordinates.add(_currentPosition); // Add to path dynamically
            _updateMapLocation(_currentPosition); // Update map position
            _updatePath(); // Draw the path on the map
          });
          _routeIndex++;
        } else {
          _simulationTimer?.cancel(); // Stop when the route is completed
        }
      });
    } else {
      print("No route points available for simulation");
    }
  }

  /// Update the map camera to follow the current position
  Future<void> _updateMapLocation(LatLng position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(position)); // Move the camera to the new position
  }

  /// Draw the path on the map as a polyline
  void _updatePath() {
    setState(() {
      _polyline = Polyline(
        polylineId: PolylineId('path'),
        points: _pathCoordinates, // Draw the path
        color: Colors.red,
        width: 5,
      );
    });
  }

  /// Toggle between real-time tracking and simulation
  void _toggleSimulation() async {
    if (_isSimulating) {
      _simulationTimer?.cancel(); // Stop simulation
      _isSimulating = false;
      _checkPermissionAndStartTracking(); // Resume real-time tracking
    } else if (_destination != null) {
      _positionStream?.cancel(); // Stop real-time tracking
      _isSimulating = true;

      // Get directions from current position to the selected destination
      await _getRoutePoints(_currentPosition, _destination!); // Get route points from Google Directions API
      _startDrivingSimulation(); // Start simulation after fetching route
    } else {
      print("No destination set");
    }
  }

  /// Handle map tap to set destination
  void _onMapTapped(LatLng tappedPoint) {
    setState(() {
      _destination = tappedPoint; // Set the destination to the tapped point
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSimulating ? 'Simulated Driving' : 'Real-Time Driving'), // Dynamic title
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: {
              Marker(
                markerId: MarkerId('currentLocation'),
                position: _currentPosition,
                infoWindow: InfoWindow(title: _isSimulating ? 'Simulated Position' : 'Real Position'),
              ),
              if (_destination != null) // Display destination marker if set
                Marker(
                  markerId: MarkerId('destination'),
                  position: _destination!,
                  infoWindow: InfoWindow(title: 'Destination'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ),
            },
            polylines: {_polyline}, // Show the path as a polyline
            onTap: _onMapTapped, // Set destination on map tap
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _toggleSimulation, // Toggle simulation on button press
              child: Icon(_isSimulating ? Icons.stop : Icons.play_arrow),
            ),
          ),
        ],
      ),
    );
  }
}
