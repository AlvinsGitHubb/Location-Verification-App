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
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(LocationTrackingApp());

class LocationTrackingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LiveLocationScreen(),
    );
  }
}

class LiveLocationScreen extends StatefulWidget {
  @override
  _LiveLocationScreenState createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  Completer<GoogleMapController> _controller = Completer();
  LatLng _currentPosition = LatLng(37.7749, -122.4194); // Default position
  StreamSubscription<Position>? _positionStream;
  List<LatLng> _pathCoordinates = []; // To store the path points
  Polyline _polyline = Polyline(polylineId: PolylineId('path'), points: []);

  @override
  void initState() {
    super.initState();
    _checkPermissionAndStartTracking();
  }

  Future<void> _checkPermissionAndStartTracking() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      _startLocationTracking();
    } else {
      print("Location permission denied");
    }
  }

void _startLocationTracking() async {
  LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation, // Highest accuracy for real-time tracking
    distanceFilter: 0, // Update as often as possible (with no movement threshold)
  );

  _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
      .listen((Position newPosition) {
    if (newPosition != null) {
      setState(() {
        _currentPosition = LatLng(newPosition.latitude, newPosition.longitude);
        _pathCoordinates.add(_currentPosition); // Add to path
        _updateMapLocation(_currentPosition);
        _updatePath();
      });
    }
  }, onError: (error) {
    print("Error in location stream: $error");
  });
}


  Future<void> _updateMapLocation(LatLng position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(position)); // Move the camera to new position
  }

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

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Location Tracking with Path'),
      ),
      body: GoogleMap(
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
            infoWindow: InfoWindow(title: 'You are here'),
          ),
        },
        polylines: {_polyline}, // Show the path as a polyline
      ),
    );
  }
}
