import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/break_status_service.dart';

class DemandZone {
  final LatLng center;
  final double radius;
  final double multiplier;
  final Color color;

  DemandZone({
    required this.center,
    required this.radius,
    required this.multiplier,
    required this.color,
  });
}

class RestLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? amenity;

  RestLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.amenity,
  });

  factory RestLocation.fromJson(Map<String, dynamic> json) {
    try {
      return RestLocation(
        id: json['id'] as String? ?? 'unknown',
        name: json['name'] as String? ?? 'Parking Location',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        amenity: json['amenity'] as String?,
      );
    } catch (e) {
      print('⚠️ Error parsing location: $e');
      print('JSON: $json');
      rethrow;
    }
  }
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
  List<RestLocation> _restLocations = [];
  Timer? _zoneTimer;

  static const String baseUrl = 'http://localhost:8080';

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

  Future<void> _fetchRestLocations() async {
    try {
      final url = Uri.parse(
          '$baseUrl/api/locations/nearby/${_currentLocation.latitude}/${_currentLocation.longitude}/10');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        List<dynamic> features;
        if (jsonData is Map && jsonData.containsKey('features')) {
          features = jsonData['features'] as List<dynamic>;
        } else if (jsonData is List) {
          features = jsonData;
        } else {
          return;
        }

        setState(() {
          _restLocations = features
              .map((json) {
            try {
              return RestLocation.fromJson(json);
            } catch (e) {
              return null;
            }
          })
              .whereType<RestLocation>()
              .toList();
        });
      }
    } catch (e, stackTrace) {
      print('💥 Error fetching rest locations: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _startRandomZoneGeneration() {
    _generateDemandZones();

    void scheduleNext() {
      final random = math.Random();
      final seconds = 10 + random.nextInt(21);

      _zoneTimer = Timer(Duration(seconds: seconds), () {
        _generateDemandZones();
        scheduleNext();
      });
    }

    scheduleNext();
  }

  void _generateDemandZones() {
    final random = math.Random();
    _demandZones.clear();

    final numZones = 5 + random.nextInt(4);

    for (int i = 0; i < numZones; i++) {
      final latOffset = (random.nextDouble() - 0.5) * 0.05;
      final lngOffset = (random.nextDouble() - 0.5) * 0.05;

      final center = LatLng(
        _currentLocation.latitude + latOffset,
        _currentLocation.longitude + lngOffset,
      );

      final multiplier = 1.2 + random.nextDouble() * 1.8;

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
        _fetchRestLocations();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          _generateDemandZones();
          _fetchRestLocations();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        _generateDemandZones();
        _fetchRestLocations();
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
      _fetchRestLocations();
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoadingLocation = false);
      _generateDemandZones();
      _fetchRestLocations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final breakStatusService = context.watch<BreakStatusService>();
    final shouldShowRestLocations = breakStatusService.needsBreak;

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

              CircleLayer(
                circles: _demandZones.map((zone) {
                  return CircleMarker(
                    point: zone.center,
                    radius: zone.radius / 2,
                    color: zone.color,
                    borderColor: zone.color.withOpacity(0.8),
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                  );
                }).toList(),
              ),

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

              if (shouldShowRestLocations)
                MarkerLayer(
                  markers: _restLocations.map((location) {
                    print('Creating rest marker at: ${location.latitude}, ${location.longitude} - ${location.name}');
                    return Marker(
                      point: LatLng(location.latitude, location.longitude),
                      width: 80,
                      height: 80,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () {
                          print('Tapped rest location: ${location.name}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Rest Stop: ${location.name}'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.deepPurple,
                            ),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Zzz',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            CustomPaint(
                              size: const Size(16, 8),
                              painter: TrianglePainter(Colors.deepPurple),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

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

                FloatingActionButton(
                  mini: true,
                  heroTag: 'refresh',
                  onPressed: _fetchRestLocations,
                  child: const Icon(Icons.refresh),
                ),
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
          if (shouldShowRestLocations)
            Positioned(
              bottom: 120,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hotel, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Rest stops shown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}