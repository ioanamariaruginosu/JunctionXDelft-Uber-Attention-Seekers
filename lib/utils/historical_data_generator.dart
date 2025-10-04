import 'dart:math';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/trip_model.dart';

class HistoricalTripGenerator {
  static HistoricalTripGenerator? _instance;
  static HistoricalTripGenerator get instance {
    _instance ??= HistoricalTripGenerator._();
    return _instance!;
  }

  HistoricalTripGenerator._();

  final Random _random = Random();
  List<HistoricalTrip>? _historicalTrips;
  Map<int, double>? _surgeByHour;
  bool _isLoaded = false;

  Future<void> loadHistoricalData() async {
    if (_isLoaded) return;

    try {
      // Load rides_trips.csv
      final tripsData = await rootBundle.loadString('assets/data/rides_trips.csv');
      final tripsList = const CsvToListConverter().convert(tripsData);

      _historicalTrips = [];
      // Skip header row
      for (int i = 1; i < tripsList.length; i++) {
        try {
          final row = tripsList[i];
          _historicalTrips!.add(HistoricalTrip.fromCsvRow(row));
        } catch (e) {
          // Skip malformed rows
        }
      }

      // Load surge_by_hour.csv
      final surgeData = await rootBundle.loadString('assets/data/surge_by_hour.csv');
      final surgeList = const CsvToListConverter().convert(surgeData);

      _surgeByHour = {};
      for (int i = 1; i < surgeList.length; i++) {
        try {
          final row = surgeList[i];
          final hour = row[1] is int ? row[1] : int.parse(row[1].toString());
          final surge = row[2] is double ? row[2] : double.parse(row[2].toString());

          // Average surge across all cities for this hour
          _surgeByHour![hour] = (_surgeByHour![hour] ?? 0.0) + surge;
        } catch (e) {
          // Skip malformed rows
        }
      }

      // Calculate averages
      final cityCount = (surgeList.length - 1) ~/ 24;
      _surgeByHour!.forEach((hour, total) {
        _surgeByHour![hour] = total / cityCount.clamp(1, 100);
      });

      _isLoaded = true;
      print('Loaded ${_historicalTrips!.length} historical trips');
    } catch (e) {
      print('Failed to load historical data: $e');
      _generateFallbackData();
    }
  }

  TripModel generateRealisticTrip() {
    if (!_isLoaded || _historicalTrips == null || _historicalTrips!.isEmpty) {
      return TripModel.generateMockTrip();
    }

    final template = _historicalTrips![_random.nextInt(_historicalTrips!.length)];

    final currentHour = DateTime.now().hour;
    final baseSurge = _surgeByHour?[currentHour] ?? 1.0;
    final surge = (baseSurge * (0.8 + _random.nextDouble() * 0.4)).clamp(1.0, 3.5);

    final distanceMutation = 0.85 + _random.nextDouble() * 0.3;
    final distance = template.distanceKm * distanceMutation * 0.621371; // km to miles

    final durationMutation = 0.8 + _random.nextDouble() * 0.4;
    final durationMins = (template.durationMins * durationMutation).round();

    final baseFarePerMile = 1.5 + _random.nextDouble() * 1.0;
    final baseFare = distance * baseFarePerMile;
    final timeComponent = durationMins * (0.2 + _random.nextDouble() * 0.2);
    final totalFare = baseFare + timeComponent;

    final earningsPerMinute = (totalFare * surge) / durationMins;
    final profitScore = _calculateProfitScore(
      earningsPerMinute: earningsPerMinute,
      surge: surge,
      distance: distance,
      duration: durationMins,
    );

    // Generate realistic coordinates (San Francisco area)
    final pickupLat = 37.7749 + (_random.nextDouble() * 0.1 - 0.05);
    final pickupLng = -122.4194 + (_random.nextDouble() * 0.1 - 0.05);
    final dropoffLat = 37.7749 + (_random.nextDouble() * 0.1 - 0.05);
    final dropoffLng = -122.4194 + (_random.nextDouble() * 0.1 - 0.05);

    return TripModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'user123',
      pickupLocation: _mutateLocation(template.pickupArea),
      dropoffLocation: _mutateLocation(template.dropoffArea),
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      distance: distance,
      fare: totalFare,
      surge: surge,
      estimatedDuration: Duration(minutes: durationMins),
      requestTime: DateTime.now(),
      profitabilityScore: profitScore,
      returnTripLikely: _random.nextDouble() > 0.5,
    );
  }

  double _calculateProfitScore({
    required double earningsPerMinute,
    required double surge,
    required double distance,
    required int duration,
  }) {
    double score = 0.0;

    // Earnings per minute (0-3.5 points) - made stricter
    if (earningsPerMinute > 2.5) {
      score += 3.5;
    } else if (earningsPerMinute > 1.8) {
      score += 2.5;
    } else if (earningsPerMinute > 1.3) {
      score += 1.8;
    } else if (earningsPerMinute > 0.9) {
      score += 1.2;
    } else if (earningsPerMinute > 0.6) {
      score += 0.6;
    }

    // Surge multiplier (0-2.5 points) - reduced from 3.0
    if (surge >= 2.5) {
      score += 2.5;
    } else if (surge >= 1.8) {
      score += 1.8;
    } else if (surge >= 1.3) {
      score += 1.2;
    } else if (surge > 1.0) {
      score += 0.5;
    }

    // Distance efficiency (0-2.0 points) - stricter thresholds
    final earningsPerMile = (earningsPerMinute * duration) / distance;
    if (earningsPerMile > 3.0) {
      score += 2.0;
    } else if (earningsPerMile > 2.0) {
      score += 1.5;
    } else if (earningsPerMile > 1.3) {
      score += 0.8;
    } else if (earningsPerMile > 0.8) {
      score += 0.3;
    }

    // Time investment (0-1.5 points)
    if (duration <= 12) {
      score += 1.5;
    } else if (duration <= 20) {
      score += 1.0;
    } else if (duration <= 35) {
      score += 0.5;
    } else if (duration > 50) {
      score -= 0.5; // Penalize very long trips
    }

    // Add some randomness for variety (-0.5 to +0.5)
    score += (_random.nextDouble() - 0.5);

    return score.clamp(0.0, 10.0);
  }

  String _mutateLocation(String baseLocation) {
    final prefixes = ['', 'Near ', 'Close to '];
    final suffixes = ['', ' Area', ' District', ' Zone'];

    final prefix = _random.nextBool() ? prefixes[_random.nextInt(prefixes.length)] : '';
    final suffix = _random.nextBool() ? suffixes[_random.nextInt(suffixes.length)] : '';

    return '$prefix$baseLocation$suffix'.trim();
  }

  void _generateFallbackData() {
    _historicalTrips = [];
    final locations = [
      'Downtown', 'Airport', 'University', 'Shopping Mall',
      'Tech Park', 'Residential Area', 'Entertainment District',
      'Business Center', 'Hospital', 'Train Station'
    ];

    for (int i = 0; i < 500; i++) {
      _historicalTrips!.add(HistoricalTrip(
        pickupArea: locations[_random.nextInt(locations.length)],
        dropoffArea: locations[_random.nextInt(locations.length)],
        distanceKm: 2.0 + _random.nextDouble() * 20.0,
        durationMins: 10 + _random.nextInt(50),
        surgeMultiplier: 1.0 + _random.nextDouble() * 2.0,
        netEarnings: 10.0 + _random.nextDouble() * 40.0,
      ));
    }

    _surgeByHour = {};
    for (int hour = 0; hour < 24; hour++) {
      if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)) {
        _surgeByHour![hour] = 1.5 + _random.nextDouble() * 1.0;
      } else {
        _surgeByHour![hour] = 1.0 + _random.nextDouble() * 0.5;
      }
    }

    _isLoaded = true;
    print('Using fallback synthetic data (${_historicalTrips!.length} trips)');
  }
}

class HistoricalTrip {
  final String pickupArea;
  final String dropoffArea;
  final double distanceKm;
  final int durationMins;
  final double surgeMultiplier;
  final double netEarnings;

  HistoricalTrip({
    required this.pickupArea,
    required this.dropoffArea,
    required this.distanceKm,
    required this.durationMins,
    required this.surgeMultiplier,
    required this.netEarnings,
  });

  factory HistoricalTrip.fromCsvRow(List<dynamic> row) {
    return HistoricalTrip(
      pickupArea: _extractAreaFromHexId(row[11].toString()),
      dropoffArea: _extractAreaFromHexId(row[14].toString()),
      distanceKm: _parseDouble(row[15]),
      durationMins: _parseInt(row[16]),
      surgeMultiplier: _parseDouble(row[17]),
      netEarnings: _parseDouble(row[20]),
    );
  }

  static String _extractAreaFromHexId(String hexId) {
    final hash = hexId.hashCode.abs();
    final areas = [
      'Downtown', 'Airport', 'University', 'Shopping District',
      'Tech Park', 'Residential Area', 'Entertainment District',
      'Business Center', 'Medical District', 'Station Area',
      'Historic Center', 'Financial District', 'Waterfront',
      'Industrial Park', 'Suburban Area'
    ];
    return areas[hash % areas.length];
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}