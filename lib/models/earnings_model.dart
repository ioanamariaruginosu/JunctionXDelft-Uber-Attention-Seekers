class EarningsModel {
  final String id;
  final String userId;
  final DateTime date;
  final double totalEarnings;
  final double baseFare;
  final double tips;
  final double bonuses;
  final double surgeEarnings;
  final int tripsCompleted;
  final Duration timeOnline;
  final double averageRating;
  final Map<String, double> hourlyEarnings;
  final List<BonusProgress> activeBonuses;

  EarningsModel({
    required this.id,
    required this.userId,
    required this.date,
    this.totalEarnings = 0.0,
    this.baseFare = 0.0,
    this.tips = 0.0,
    this.bonuses = 0.0,
    this.surgeEarnings = 0.0,
    this.tripsCompleted = 0,
    Duration? timeOnline,
    this.averageRating = 5.0,
    Map<String, double>? hourlyEarnings,
    List<BonusProgress>? activeBonuses,
  })  : timeOnline = timeOnline ?? Duration.zero,
        hourlyEarnings = hourlyEarnings ?? {},
        activeBonuses = activeBonuses ?? [];

  double get earningsPerHour {
    if (timeOnline.inMinutes == 0) return 0;
    return totalEarnings / (timeOnline.inMinutes / 60);
  }

  double get earningsPerTrip {
    if (tripsCompleted == 0) return 0;
    return totalEarnings / tripsCompleted;
  }

  EarningsModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? totalEarnings,
    double? baseFare,
    double? tips,
    double? bonuses,
    double? surgeEarnings,
    int? tripsCompleted,
    Duration? timeOnline,
    double? averageRating,
    Map<String, double>? hourlyEarnings,
    List<BonusProgress>? activeBonuses,
  }) {
    return EarningsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      baseFare: baseFare ?? this.baseFare,
      tips: tips ?? this.tips,
      bonuses: bonuses ?? this.bonuses,
      surgeEarnings: surgeEarnings ?? this.surgeEarnings,
      tripsCompleted: tripsCompleted ?? this.tripsCompleted,
      timeOnline: timeOnline ?? this.timeOnline,
      averageRating: averageRating ?? this.averageRating,
      hourlyEarnings: hourlyEarnings ?? this.hourlyEarnings,
      activeBonuses: activeBonuses ?? this.activeBonuses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'totalEarnings': totalEarnings,
      'baseFare': baseFare,
      'tips': tips,
      'bonuses': bonuses,
      'surgeEarnings': surgeEarnings,
      'tripsCompleted': tripsCompleted,
      'timeOnline': timeOnline.inSeconds,
      'averageRating': averageRating,
      'hourlyEarnings': hourlyEarnings,
      'activeBonuses': activeBonuses.map((b) => b.toJson()).toList(),
    };
  }

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      id: json['id'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      baseFare: (json['baseFare'] ?? 0.0).toDouble(),
      tips: (json['tips'] ?? 0.0).toDouble(),
      bonuses: (json['bonuses'] ?? 0.0).toDouble(),
      surgeEarnings: (json['surgeEarnings'] ?? 0.0).toDouble(),
      tripsCompleted: json['tripsCompleted'] ?? 0,
      timeOnline: Duration(seconds: json['timeOnline'] ?? 0),
      averageRating: (json['averageRating'] ?? 5.0).toDouble(),
      hourlyEarnings: Map<String, double>.from(json['hourlyEarnings'] ?? {}),
      activeBonuses: (json['activeBonuses'] as List?)
              ?.map((b) => BonusProgress.fromJson(b))
              .toList() ??
          [],
    );
  }
}

class BonusProgress {
  final String id;
  final String title;
  final String description;
  final double reward;
  final int targetTrips;
  final int completedTrips;
  final DateTime deadline;
  final BonusType type;

  BonusProgress({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.targetTrips,
    this.completedTrips = 0,
    required this.deadline,
    required this.type,
  });

  double get progressPercentage => (completedTrips / targetTrips) * 100;

  bool get isCompleted => completedTrips >= targetTrips;

  Duration get timeRemaining => deadline.difference(DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reward': reward,
      'targetTrips': targetTrips,
      'completedTrips': completedTrips,
      'deadline': deadline.toIso8601String(),
      'type': type.toString().split('.').last,
    };
  }

  factory BonusProgress.fromJson(Map<String, dynamic> json) {
    return BonusProgress(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      reward: json['reward'].toDouble(),
      targetTrips: json['targetTrips'],
      completedTrips: json['completedTrips'] ?? 0,
      deadline: DateTime.parse(json['deadline']),
      type: BonusType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => BonusType.consecutive,
      ),
    );
  }
}

enum BonusType { consecutive, quest, surge, weekend, peakHour }