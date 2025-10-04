import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({Key? key}) : super(key: key);

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final WeatherService _weatherService = WeatherService();
  String weather = 'Fetching weather...';
  double windSpeed = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeatherWithLocation();
  }

  Future<void> _fetchWeatherWithLocation() async {
    try {
      // ✅ Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          weather = 'Location services disabled';
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            weather = 'Permission denied';
            _loading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          weather = 'Permission permanently denied';
          _loading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final result = await _weatherService.getCurrentWeather(
        lat: position.latitude,
        lon: position.longitude,
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          weather = result['weather'];
          windSpeed = result['windSpeed'];
          _loading = false;
        });

        final String lowerWeather = weather.toLowerCase();
        final double windKmH = windSpeed * 3.6;

        // Build alerts
        String? alertMessage;
        if (windKmH > 25) {
          alertMessage = '💨 Be careful: strong winds coming!';
        } else if (lowerWeather.contains('rain')) {
          alertMessage = '🌧️ Rain expected — drive carefully!';
        } else if (lowerWeather.contains('snow')) {
          alertMessage = '❄️ Snowfall detected — roads may be slippery!';
        }

        // Show snackbar alert if any
        if (alertMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(alertMessage!),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 5),
              ),
            );
          });
        }
      } else {
        setState(() {
          weather = 'Weather unavailable';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        weather = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _loading
          ? const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Fetching weather...'),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wb_sunny, color: Colors.orange),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Wind: ${windSpeed.toStringAsFixed(1)} m/s',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
