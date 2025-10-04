import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class DemandZone {
  final LatLng center;
  final double radius; // in meters
  final double multiplier;
  final Color color;

  DemandZone({
    required this.center,
    required this.radius,
    required this.multiplier,
    required this.color,
  });
}

class RealMapWidget extends StatefulWidget {
  const RealMapWidget({super.key});

  @override
  State<RealMapWidget> createState() => _RealMapWidgetState();
}

class _RealMapWidgetState extends State<RealMapWidget> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = LatLng(51.5074, -0.1278); // Default: London
  bool _isLoadingLocation = true;
  bool _isDark = false;
  List<DemandZone> _demandZones = [];
  Timer? _zoneTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startRandomZoneGeneration();
  }

  @override
  void dispose() {
    _zoneTimer?.cancel();
    super.dispose();
  }

  void _startRandomZoneGeneration() {
    _generateDemandZones();

    // Then generate new zones at random intervals (between 10-30 seconds)
    void scheduleNext() {
      final random = math.Random();
      final seconds = 10 + random.nextInt(21); // 10 to 30 seconds

      _zoneTimer = Timer(Duration(seconds: seconds), () {
        _generateDemandZones();
        scheduleNext(); // Schedule the next generation
      });
    }

    scheduleNext();
  }

  void _generateDemandZones() {
    final random = math.Random();
    _demandZones.clear();

    // Generate 5-8 random demand zones around current location
    final numZones = 5 + random.nextInt(4);

    for (int i = 0; i < numZones; i++) {
      // Random offset from current location (roughly within 5km)
      final latOffset = (random.nextDouble() - 0.5) * 0.05;
      final lngOffset = (random.nextDouble() - 0.5) * 0.05;

      final center = LatLng(
        _currentLocation.latitude + latOffset,
        _currentLocation.longitude + lngOffset,
      );

      // Random multiplier between 1.2x and 3.0x
      final multiplier = 1.2 + random.nextDouble() * 1.8;

      // Color based on multiplier
      Color color;
      if (multiplier >= 2.5) {
        color = Colors.red.withOpacity(0.3);
      } else if (multiplier >= 2.0) {
        color = Colors.orange.withOpacity(0.3);
      } else if (multiplier >= 1.5) {
        color = Colors.yellow.withOpacity(0.3);
      } else {
        color = Colors.green.withOpacity(0.3);
      }

      // Random radius between 300-800 meters
      final radius = 300.0 + random.nextDouble() * 500;

      _demandZones.add(DemandZone(
        center: center,
        radius: radius,
        multiplier: multiplier,
        color: color,
      ));
    }

    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        _generateDemandZones();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          _generateDemandZones();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        _generateDemandZones();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _mapController.move(_currentLocation, 13.0);
      _generateDemandZones();
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoadingLocation = false);
      _generateDemandZones();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13.0,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _isDark
                    ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hackathon.uberCopilot',
                maxZoom: 19,
                additionalOptions: const {
                  'User-Agent': 'Uber Copilot/1.0 (stefmatei22@gmail.com)',
                },
                tileProvider: NetworkTileProvider(),
              ),

              // Demand zones as circles
              CircleLayer(
                circles: _demandZones.map((zone) {
                  return CircleMarker(
                    point: zone.center,
                    radius: zone.radius / 2, // Adjust visual size
                    color: zone.color,
                    borderColor: zone.color.withOpacity(0.8),
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                  );
                }).toList(),
              ),

              // Markers showing multipliers
              MarkerLayer(
                markers: _demandZones.map((zone) {
                  return Marker(
                    point: zone.center,
                    width: 80,
                    height: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: zone.color.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: zone.color.withOpacity(1.0),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${zone.multiplier.toStringAsFixed(1)}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Current location marker
              if (!_isLoadingLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (_isLoadingLocation)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Getting your location...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Controls
          Positioned(
            top: 50,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'theme',
                  onPressed: () {
                    setState(() => _isDark = !_isDark);
                  },
                  child: Icon(_isDark ? Icons.light_mode : Icons.dark_mode),
                ),
                const SizedBox(height: 8),

                FloatingActionButton(
                  mini: true,
                  heroTag: 'location',
                  onPressed: () {
                    _mapController.move(_currentLocation, 13.0);
                  },
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),

                const SizedBox(height: 8),

                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_in',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),

                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_out',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}