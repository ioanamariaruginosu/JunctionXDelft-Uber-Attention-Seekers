import 'dart:math';

class TripModel {
  final String id;
  final String userId;
  final String pickupLocation;
  final String dropoffLocation;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final double distance;
  final double fare;
  final double tip;
  final double surge;
  final Duration estimatedDuration;
  final DateTime requestTime;
  final DateTime? acceptTime;
  final DateTime? startTime;
  final DateTime? completeTime;
  final TripStatus status;
  final double profitabilityScore;
  final String? atlasRecommendation;
  final bool returnTripLikely;

  TripModel({
    required this.id,
    required this.userId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.distance,
    required this.fare,
    this.tip = 0.0,
    this.surge = 1.0,
    required this.estimatedDuration,
    required this.requestTime,
    this.acceptTime,
    this.startTime,
    this.completeTime,
    this.status = TripStatus.pending,
    this.profitabilityScore = 5.0,
    this.atlasRecommendation,
    this.returnTripLikely = false,
  });

  double get totalEarnings => (fare * surge) + tip;

  double get earningsPerMinute => totalEarnings / estimatedDuration.inMinutes;

  TripModel copyWith({
    String? id,
    String? userId,
    String? pickupLocation,
    String? dropoffLocation,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    double? distance,
    double? fare,
    double? tip,
    double? surge,
    Duration? estimatedDuration,
    DateTime? requestTime,
    DateTime? acceptTime,
    DateTime? startTime,
    DateTime? completeTime,
    TripStatus? status,
    double? profitabilityScore,
    String? atlasRecommendation,
    bool? returnTripLikely,
  }) {
    return TripModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      distance: distance ?? this.distance,
      fare: fare ?? this.fare,
      tip: tip ?? this.tip,
      surge: surge ?? this.surge,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      requestTime: requestTime ?? this.requestTime,
      acceptTime: acceptTime ?? this.acceptTime,
      startTime: startTime ?? this.startTime,
      completeTime: completeTime ?? this.completeTime,
      status: status ?? this.status,
      profitabilityScore: profitabilityScore ?? this.profitabilityScore,
      atlasRecommendation: atlasRecommendation ?? this.atlasRecommendation,
      returnTripLikely: returnTripLikely ?? this.returnTripLikely,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'distance': distance,
      'fare': fare,
      'tip': tip,
      'surge': surge,
      'estimatedDuration': estimatedDuration.inSeconds,
      'requestTime': requestTime.toIso8601String(),
      'acceptTime': acceptTime?.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'completeTime': completeTime?.toIso8601String(),
      'status': status.toString().split('.').last,
      'profitabilityScore': profitabilityScore,
      'atlasRecommendation': atlasRecommendation,
      'returnTripLikely': returnTripLikely,
    };
  }

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'],
      userId: json['userId'],
      pickupLocation: json['pickupLocation'],
      dropoffLocation: json['dropoffLocation'],
      pickupLat: json['pickupLat'].toDouble(),
      pickupLng: json['pickupLng'].toDouble(),
      dropoffLat: json['dropoffLat'].toDouble(),
      dropoffLng: json['dropoffLng'].toDouble(),
      distance: json['distance'].toDouble(),
      fare: json['fare'].toDouble(),
      tip: (json['tip'] ?? 0.0).toDouble(),
      surge: (json['surge'] ?? 1.0).toDouble(),
      estimatedDuration: Duration(seconds: json['estimatedDuration']),
      requestTime: DateTime.parse(json['requestTime']),
      acceptTime: json['acceptTime'] != null ? DateTime.parse(json['acceptTime']) : null,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      completeTime: json['completeTime'] != null ? DateTime.parse(json['completeTime']) : null,
      status: TripStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TripStatus.pending,
      ),
      profitabilityScore: (json['profitabilityScore'] ?? 5.0).toDouble(),
      atlasRecommendation: json['atlasRecommendation'],
      returnTripLikely: json['returnTripLikely'] ?? false,
    );
  }

  static TripModel generateMockTrip() {
    final random = Random();
    final locations = [
      'Downtown Financial District',
      'Airport Terminal 2',
      'University Campus',
      'Shopping Mall - West End',
      'Residential Area - Oak Hills',
      'Tech Park - Silicon Valley',
      'Hospital - St. Mary\'s',
      'Train Station - Central',
      'Beach Resort - Sunset Bay',
      'Convention Center',
    ];

    final pickupLocation = locations[random.nextInt(locations.length)];
    String dropoffLocation;
    do {
      dropoffLocation = locations[random.nextInt(locations.length)];
    } while (dropoffLocation == pickupLocation);

    final distance = random.nextDouble() * 15 + 2;
    final baseFare = 3 + (distance * 1.5);
    final surge = random.nextBool() ? 1.0 : (1.0 + random.nextDouble() * 1.5);
    final tip = random.nextBool() ? (random.nextDouble() * 5 + 1) : 0.0;
    final estimatedMinutes = (distance * 3 + 5).round();

    final profitabilityScore =
        (baseFare * surge + tip) / estimatedMinutes * 10;

    return TripModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'user123',
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      pickupLat: 37.7749 + random.nextDouble() * 0.1 - 0.05,
      pickupLng: -122.4194 + random.nextDouble() * 0.1 - 0.05,
      dropoffLat: 37.7749 + random.nextDouble() * 0.1 - 0.05,
      dropoffLng: -122.4194 + random.nextDouble() * 0.1 - 0.05,
      distance: distance,
      fare: baseFare,
      tip: tip,
      surge: surge,
      estimatedDuration: Duration(minutes: estimatedMinutes),
      requestTime: DateTime.now(),
      profitabilityScore: profitabilityScore.clamp(1, 10),
      returnTripLikely: random.nextDouble() > 0.5,
      atlasRecommendation: profitabilityScore > 6
          ? 'Good opportunity! High profitability in current demand zone.'
          : profitabilityScore > 4
              ? 'Average trip. Consider if it leads to a high-demand area.'
              : 'Low profitability. Decline unless positioning strategically.',
    );
  }
}

enum TripStatus {
  pending,
  accepted,
  driverArrived,
  inProgress,
  completed,
  cancelled
}