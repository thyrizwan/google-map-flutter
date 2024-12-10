import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final List<LatLng> _polylineCoordinates = [];
  LatLng? _currentLocation;
  Marker? _currentMarker;
  Polyline? _currentPolyline;
  bool _isMapInitialized = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _startLocationUpdates();
  }

  Future<void> _fetchLocation() async {
    final hasPermission = await _handlePermission();
    if (!hasPermission) return;

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _polylineCoordinates.add(_currentLocation!);
      _addMarker(_currentLocation!);
    });

    if (_isMapInitialized) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_currentLocation!),
      );
    }
  }

  Future<bool> _handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = newLocation;
        _polylineCoordinates.add(newLocation);
        _updateMarkerAndPolyline(newLocation);
      });
    });
  }

  // Add or update the marker at the given position
  void _addMarker(LatLng position) {
    _currentMarker = Marker(
      markerId: const MarkerId("current_location"),
      position: position,
      draggable: true,
      infoWindow: InfoWindow(
        title: "My current location",
        snippet: "Lat: ${position.latitude}, Lng: ${position.longitude}",
      ),
      onTap: () {
        setState(() {});
      },
    );
  }

  // Update marker position and polyline
  void _updateMarkerAndPolyline(LatLng position) {
    _addMarker(position);

    _currentPolyline = Polyline(
      polylineId: const PolylineId("tracking_polyline"),
      points: _polylineCoordinates,
      color: Colors.blue,
      width: 4,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Google Maps & Geolocator"),
      ),
      body: _currentLocation == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation!,
                zoom: 16,
              ),
              markers: _currentMarker != null ? {_currentMarker!} : {},
              polylines: _currentPolyline != null ? {_currentPolyline!} : {},
              onMapCreated: (controller) {
                _mapController = controller;
                _isMapInitialized = true;
                if (_currentLocation != null) {
                  _mapController.animateCamera(
                    CameraUpdate.newLatLng(_currentLocation!),
                  );
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: (LatLng? latLng) {
                print(latLng);
              },
            ),
    );
  }
}
