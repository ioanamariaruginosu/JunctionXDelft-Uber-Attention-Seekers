import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/trip_model.dart';
import '../models/earnings_model.dart';
import '../models/notification_model.dart';
import '../utils/api_client.dart';

class MockDataService extends ChangeNotifier {
  final Random _random = Random();
  final List<TripModel> _tripHistory = [];
  final List<NotificationModel> _notifications = [];

  TripModel? _currentTripRequest;
  TripModel? _activeTrip;
  EarningsModel? _todayEarnings;

  Timer? _tripRequestTimer;
  Timer? _demandUpdateTimer;
  Timer? _earningsUpdateTimer;

  bool _isOnline = false;
  double _currentDemandLevel = 1.0;
  Map<String, double> _demandZones = {};

  Duration _timeOnline = Duration.zero;
  DateTime? _sessionStartTime;

  String? _userId;

  List<TripModel> get tripHistory => _tripHistory;
  List<NotificationModel> get notifications => _notifications;
  TripModel? get currentTripRequest => _currentTripRequest;
  TripModel? get activeTrip => _activeTrip;
  EarningsModel? get todayEarnings => _todayEarnings;
  bool get isOnline => _isOnline;
  double get currentDemandLevel => _currentDemandLevel;
  Map<String, double> get demandZones => _demandZones;
  Duration get timeOnline => _timeOnline;

  MockDataService() {
    _initializeTodayEarnings();
    _initializeDemandZones();
  }

  void setUserId(String userId) {
    _userId = userId;
  }

  void _initializeTodayEarnings() {
    _todayEarnings = EarningsModel(
      id: const Uuid().v4(),
      userId: 'user123',
      date: DateTime.now(),
      totalEarnings: 0.0,
      baseFare: 0.0,
      tips: 0.0,
      bonuses: 0.0,
      surgeEarnings: 0.0,
      tripsCompleted: 0,
      timeOnline: Duration.zero,
      averageRating: 5.0,
      hourlyEarnings: {},
      activeBonuses: _generateActiveBonuses(),
    );
  }

  List<BonusProgress> _generateActiveBonuses() {
    return [
      BonusProgress(
        id: '1',
        title: 'Morning Rush Bonus',
        description: 'Complete 5 trips before 10 AM',
        reward: 15.0,
        targetTrips: 5,
        completedTrips: _random.nextInt(5),
        deadline: DateTime.now().add(const Duration(hours: 4)),
        type: BonusType.peakHour,
      ),
      BonusProgress(
        id: '2',
        title: 'Consecutive Trips',
        description: 'Complete 3 trips without declining',
        reward: 10.0,
        targetTrips: 3,
        completedTrips: _random.nextInt(3),
        deadline: DateTime.now().add(const Duration(hours: 8)),
        type: BonusType.consecutive,
      ),
      BonusProgress(
        id: '3',
        title: 'Weekend Warrior',
        description: 'Complete 20 trips this weekend',
        reward: 50.0,
        targetTrips: 20,
        completedTrips: _random.nextInt(10),
        deadline: DateTime.now().add(const Duration(days: 2)),
        type: BonusType.weekend,
      ),
    ];
  }

  void _initializeDemandZones() {
    _demandZones = {
      'Downtown': 2.5,
      'Airport': 1.8,
      'University': 1.5,
      'Shopping District': 1.3,
      'Residential': 1.0,
      'Tech Park': 1.2,
      'Entertainment District': 2.0,
    };
  }

  void goOnline() {
    _isOnline = true;
    _sessionStartTime = DateTime.now();
    _startMockGenerators();
    notifyListeners();
  }

  void goOffline() {
    _isOnline = false;
    _stopMockGenerators();
    if (_sessionStartTime != null) {
      _timeOnline = _timeOnline + DateTime.now().difference(_sessionStartTime!);
      _sessionStartTime = null;
    }
    notifyListeners();
  }

  void _startMockGenerators() {
    _generateTripRequest();

    _tripRequestTimer = Timer.periodic(
      Duration(seconds: _random.nextInt(60) + 30),
          (_) => _generateTripRequest(),
    );

    _demandUpdateTimer = Timer.periodic(
      const Duration(minutes: 5),
          (_) => _updateDemandZones(),
    );

    _earningsUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => _updateTimeOnline(),
    );
  }

  void _stopMockGenerators() {
    _tripRequestTimer?.cancel();
    _demandUpdateTimer?.cancel();
    _earningsUpdateTimer?.cancel();
  }

  void _generateTripRequest() {
    if (!_isOnline || _activeTrip != null || _currentTripRequest != null) return;

    _currentTripRequest = TripModel.generateMockTrip();

    _addNotification(NotificationModel(
      id: const Uuid().v4(),
      title: 'New Trip Request',
      message: '${_currentTripRequest!.pickupLocation} to ${_currentTripRequest!.dropoffLocation}',
      type: NotificationType.tripRequest,
      priority: NotificationPriority.high,
      data: {'tripId': _currentTripRequest!.id},
      actions: [
        NotificationAction(label: 'Accept', actionId: 'accept'),
        NotificationAction(label: 'Decline', actionId: 'decline'),
      ],
    ));

    notifyListeners();

    Timer(const Duration(seconds: 15), () {
      if (_currentTripRequest != null) {
        _currentTripRequest = null;
        notifyListeners();
      }
    });
  }

  Future<void> acceptTrip() async {
    if (_currentTripRequest == null) return;

    await _startSession();

    _activeTrip = _currentTripRequest!.copyWith(
      status: TripStatus.accepted,
      acceptTime: DateTime.now(),
    );
    _currentTripRequest = null;

    _addNotification(NotificationModel(
      id: const Uuid().v4(),
      title: 'Trip Accepted',
      message: 'Navigate to pickup: ${_activeTrip!.pickupLocation}',
      type: NotificationType.tripRequest,
      priority: NotificationPriority.normal,
    ));

    notifyListeners();

    _simulateTripProgress();
  }

  Future<void> declineTrip() async {
    if (_currentTripRequest == null) return;

    await _stopSession();

    _currentTripRequest = null;
    notifyListeners();
  }

  Future<void> _startSession() async {
    if (_userId == null) {
      debugPrint('Cannot start session: userId is null');
      return;
    }

    try {
      final response = await ApiClient.post(
        '/hours/start/$_userId'
      );

      if (response.success) {
        debugPrint('Session started successfully for user: $_userId');
      } else {
        debugPrint('Failed to start session: ${response.message}');
      }
    } catch (e) {
      debugPrint('Error starting session: $e');
    }
  }

  Future<void> _stopSession() async {
    if (_userId == null) {
      debugPrint('Cannot stop session: userId is null');
      return;
    }

    try {
      final response = await ApiClient.post(
        '/hours/stop/$_userId'
      );

      if (response.success) {
        debugPrint('Session stopped successfully for user: $_userId');
      } else {
        debugPrint('Failed to stop session: ${response.message}');
      }
    } catch (e) {
      debugPrint('Error stopping session: $e');
    }
  }

  void _simulateTripProgress() async {
    if (_activeTrip == null) return;

    await Future.delayed(const Duration(seconds: 3));
    _activeTrip = _activeTrip!.copyWith(
      status: TripStatus.driverArrived,
    );
    _addNotification(NotificationModel(
      id: const Uuid().v4(),
      title: 'Arrived at Pickup',
      message: 'Waiting for passenger',
      type: NotificationType.tripRequest,
    ));
    notifyListeners();

    await Future.delayed(const Duration(seconds: 5));
    _activeTrip = _activeTrip!.copyWith(
      status: TripStatus.inProgress,
      startTime: DateTime.now(),
    );
    _addNotification(NotificationModel(
      id: const Uuid().v4(),
      title: 'Trip Started',
      message: 'En route to ${_activeTrip!.dropoffLocation}',
      type: NotificationType.tripRequest,
    ));
    notifyListeners();

    await Future.delayed(Duration(seconds: _activeTrip!.estimatedDuration.inSeconds ~/ 10));

    final tip = _random.nextBool() ? (_random.nextDouble() * 5 + 1) : 0.0;
    _activeTrip = _activeTrip!.copyWith(
      status: TripStatus.completed,
      completeTime: DateTime.now(),
      tip: tip,
    );

    _updateEarnings(_activeTrip!);
    _tripHistory.insert(0, _activeTrip!);

    _addNotification(NotificationModel(
      id: const Uuid().v4(),
      title: 'Trip Completed',
      message: 'Earned \$${_activeTrip!.totalEarnings.toStringAsFixed(2)}',
      type: NotificationType.earnings,
      priority: NotificationPriority.normal,
    ));

    await _stopSession();

    _activeTrip = null;
    notifyListeners();
  }

  void _updateEarnings(TripModel trip) {
    if (_todayEarnings == null) return;

    final hour = DateTime.now().hour.toString();
    final currentHourEarnings = _todayEarnings!.hourlyEarnings[hour] ?? 0.0;

    _todayEarnings = _todayEarnings!.copyWith(
      totalEarnings: _todayEarnings!.totalEarnings + trip.totalEarnings,
      baseFare: _todayEarnings!.baseFare + trip.fare,
      tips: _todayEarnings!.tips + trip.tip,
      surgeEarnings: _todayEarnings!.surgeEarnings + (trip.fare * (trip.surge - 1)),
      tripsCompleted: _todayEarnings!.tripsCompleted + 1,
      hourlyEarnings: {
        ..._todayEarnings!.hourlyEarnings,
        hour: currentHourEarnings + trip.totalEarnings,
      },
    );

    _updateBonusProgress();
  }

  void _updateBonusProgress() {
    if (_todayEarnings == null) return;

    final updatedBonuses = _todayEarnings!.activeBonuses.map((bonus) {
      if (bonus.isCompleted) return bonus;

      return BonusProgress(
        id: bonus.id,
        title: bonus.title,
        description: bonus.description,
        reward: bonus.reward,
        targetTrips: bonus.targetTrips,
        completedTrips: bonus.completedTrips + 1,
        deadline: bonus.deadline,
        type: bonus.type,
      );
    }).toList();

    for (var bonus in updatedBonuses) {
      if (bonus.isCompleted && !_todayEarnings!.activeBonuses.firstWhere((b) => b.id == bonus.id).isCompleted) {
        _addNotification(NotificationModel(
          id: const Uuid().v4(),
          title: 'Bonus Completed! 🎉',
          message: '${bonus.title}: +\$${bonus.reward.toStringAsFixed(2)}',
          type: NotificationType.bonus,
          priority: NotificationPriority.high,
        ));

        _todayEarnings = _todayEarnings!.copyWith(
          bonuses: _todayEarnings!.bonuses + bonus.reward,
          totalEarnings: _todayEarnings!.totalEarnings + bonus.reward,
        );
      }
    }

    _todayEarnings = _todayEarnings!.copyWith(activeBonuses: updatedBonuses);
  }

  void _updateDemandZones() {
    _demandZones.forEach((zone, level) {
      final change = (_random.nextDouble() - 0.5) * 0.5;
      _demandZones[zone] = (level + change).clamp(0.5, 3.0);
    });

    final highestDemandZone = _demandZones.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
    );

    if (highestDemandZone.value > 2.0) {
      _addNotification(NotificationModel(
        id: const Uuid().v4(),
        title: '🔥 High Demand Alert',
        message: '${highestDemandZone.key}: ${highestDemandZone.value.toStringAsFixed(1)}x surge',
        type: NotificationType.demandAlert,
        priority: NotificationPriority.high,
      ));
    }

    notifyListeners();
  }

  void _updateTimeOnline() {
    if (_isOnline && _sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      _todayEarnings = _todayEarnings?.copyWith(
        timeOnline: _timeOnline + sessionDuration,
      );
      notifyListeners();
    }
  }

  void _addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (_notifications.length > 50) {
      _notifications.removeLast();
    }
  }

  void markNotificationAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopMockGenerators();
    super.dispose();
  }
}