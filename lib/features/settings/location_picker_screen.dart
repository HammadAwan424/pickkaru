import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:geolocator/geolocator.dart' hide Position, LocationSettings; // Import geolocator
import 'package:geolocator/geolocator.dart' as geo show Position, LocationSettings;

class LocationPickerScreen extends StatefulWidget {

  const LocationPickerScreen({Key? key}) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  PointAnnotation? _currentMarker;
  
  Position? _selectedPosition;
  String _addressText = "Long-press anywhere on the map to pick a location";
  bool _isLoading = false;

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    
    // 1. Initialize the annotation manager for pins
    _annotationManager = await mapboxMap.annotations.createPointAnnotationManager();

    // 2. Register long-press gesture listener using the Interactions API
    mapboxMap.addInteraction(
      LongTapInteraction.onMap((MapContentGestureContext context) {
        _handleMapLongPress(context.point.coordinates);
      })
    );

    // 3. Enable the native blue location puck on the map
    _enableLocationPuck();
  }

  // Enables Mapbox's built-in location indicator layer
  Future<void> _enableLocationPuck() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      // Toggle native Mapbox puck rendering settings
      await _mapboxMap?.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true, // Optional soft pulse effect
        ),
      );
    }
  }

  // Animates the map viewport to the user's active device position
  Future<void> _focusOnUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled. Please enable GPS.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    setState(() => _isLoading = true);

    try {
      // Fetch high-accuracy GPS position
      geo.Position devicePosition = await Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Transition the Mapbox camera viewport smoothly
      await _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(devicePosition.longitude, devicePosition.latitude),
          ),
          zoom: 15.0, // Tight zoom profile for accuracy visibility
        ),
        MapAnimationOptions(duration: 1200), // Smooth 1.2s flight timing
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not retrieve current location layer.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleMapLongPress(Position coordinate) {
    setState(() {
      _selectedPosition = coordinate;
    });

    _updateMarker(coordinate);
    _reverseGeocode(coordinate);
  }

  Future<void> _updateMarker(Position position) async {
    if (_annotationManager == null) return;

    if (_currentMarker != null) {
      await _annotationManager!.delete(_currentMarker!);
    }

    var options = PointAnnotationOptions(
      geometry: Point(coordinates: position),
      iconImage: "marker-15", 
      iconSize: 2.0,
    );

    _currentMarker = await _annotationManager!.create(options);
  }

  Future<void> _reverseGeocode(Position position) async {
    setState(() => _isLoading = true);
    
    // Note: Mapbox API expects longitude first, then latitude
    // in place reading of
    String ACCESS_TOKEN = const String.fromEnvironment("ACCESS_TOKEN");
    final url = 'https://api.mapbox.com/search/geocoding/v6/reverse'
        '?longitude=${position.lng}'
        '&latitude=${position.lat}'
        '&access_token=${ACCESS_TOKEN}'
        '&limit=1';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        if (features.isNotEmpty) {
          setState(() {
            _addressText = features[0]['properties']['full_address'] ?? "Address not found";
          });
        } else {
          setState(() => _addressText = "No address features returned.");
        }
      } else {
        setState(() => _addressText = "Geocoding error: Platform side failure.");
      }
    } catch (e) {
      setState(() => _addressText = "Failed to fetch address profile.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pinpoint Location"),
        actions: [
          if (_selectedPosition != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                Navigator.pop(context, {
                  'latitude': _selectedPosition!.lat,
                  'longitude': _selectedPosition!.lng,
                  'address': _addressText,
                });
              },
            )
        ],
      ),
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            onMapCreated: _onMapCreated,
          ),
          
          // Target / Focus Floating Action Button positioned contextually
          Positioned(
            right: 16,
            bottom: 160, // Kept above the informational context card block
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.blueAccent,
              onPressed: _focusOnUserLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
          
          // Bottom details layout panel
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Selected Location Details", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    const SizedBox(height: 8),
                    _isLoading 
                      ? const Center(child: LinearProgressIndicator()) // Linear keeps space uniform
                      : Text(_addressText, style: const TextStyle(color: Colors.black87)),
                    if (_selectedPosition != null && !_isLoading) ...[
                      const SizedBox(height: 6),
                      Text(
                        "Coords: ${_selectedPosition!.lat.toStringAsFixed(5)}, ${_selectedPosition!.lng.toStringAsFixed(5)}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}