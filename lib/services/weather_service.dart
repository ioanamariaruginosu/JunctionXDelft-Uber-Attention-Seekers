import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = '5254e3d9df9fac9fa5dc8ecd99359949';

  Future<Map<String, dynamic>?> getCurrentWeather({
    required double lat,
    required double lon,
  }) async {
    final url =
        'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&exclude=minutely,hourly,daily,alerts&units=metric&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];

        if (current == null) return null;

        final weatherDescription =
            current['weather']?[0]?['description'] ?? 'Unknown';
        final windSpeed = current['wind_speed']?.toDouble() ?? 0.0;

        return {
          'weather': weatherDescription,
          'windSpeed': windSpeed,
        };
      } else {
        print('Failed to fetch weather: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }
}
