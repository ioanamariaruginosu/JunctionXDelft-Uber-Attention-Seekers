import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:uuid/uuid.dart';

import '../models/notification_model.dart';
import '../models/trip_model.dart';
import '../utils/api_client.dart';

class NotificationService extends ChangeNotifier {
  // ========= Popup/notification state =========
  final List<NotificationModel> _activePopups = [];
  final Random _random = Random();
  Timer? _autoNotificationTimer;

  List<NotificationModel> get activePopups => _activePopups;

  void showPopup(NotificationModel notification) {
    _activePopups.add(notification);
    _notifySafely();

    if (notification.priority != NotificationPriority.urgent) {
      Timer(const Duration(seconds: 10), () {
        dismissPopup(notification.id);
      });
    }
  }

  void dismissPopup(String notificationId) {
    _activePopups.removeWhere((n) => n.id == notificationId);
    _notifySafely();
  }

  void clearAllPopups() {
    _activePopups.clear();
    _notifySafely();
  }

  void showTripRequestPopup(TripModel trip) {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: 'New Trip Request',
      message: '${trip.pickupLocation} → ${trip.dropoffLocation}\n'
          '💰 \$${trip.totalEarnings.toStringAsFixed(2)} | '
          '📍 ${trip.distance.toStringAsFixed(1)} mi | '
          '⏱️ ${trip.estimatedDuration.inMinutes} min',
      type: NotificationType.tripRequest,
      priority: NotificationPriority.urgent,
      data: {'trip': trip.toJson()},
      actions: [
        NotificationAction(label: 'Accept', actionId: 'accept_trip', color: Colors.green),
        NotificationAction(label: 'Decline', actionId: 'decline_trip', color: Colors.red),
      ],
    );
    showPopup(notification);
  }

  void showDemandAlert(String location, double surge) {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: '🔥 High Demand Alert',
      message: '$location is surging at ${surge}x!\nExpected wait: 2-3 minutes',
      type: NotificationType.demandAlert,
      priority: NotificationPriority.high,
      actions: [
        NotificationAction(label: 'Navigate', actionId: 'navigate_to_zone', color: Colors.blue),
        NotificationAction(label: 'Dismiss', actionId: 'dismiss'),
      ],
    );
    showPopup(notification);
  }

  void showBonusProgress(String bonusTitle, int current, int target, double reward) {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: '💰 Bonus Progress',
      message: '$bonusTitle: $current/$target trips\nComplete for +\$${reward}!',
      type: NotificationType.bonus,
      priority: NotificationPriority.normal,
    );
    showPopup(notification);
  }

  // ======== REST-PIN VISIBILITY CONTROL ========
  bool showRestPins = false;

  void _setShowRestPins(bool v) {
    if (showRestPins != v) {
      showRestPins = v;
      _notifySafely();
    }
  }

  void showRestPinsNow() => _setShowRestPins(true);

  void hideRestPinsAndReset() {
    _setShowRestPins(false);
    // allow future wellness alerts to trigger again
    _restAlert95Fired = false;
    _restAlert120Fired = false;
  }
  // =============================================

  void showWellnessReminder(String message) {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: '☕ Wellness Check',
      message: message,
      type: NotificationType.wellness,
      priority: NotificationPriority.normal,
      actions: [
        NotificationAction(label: 'Take Break', actionId: 'take_break', color: Colors.green),
        NotificationAction(label: 'Snooze 30 min', actionId: 'snooze'),
      ],
    );

    // Pins visible as soon as the assistant suggests resting
    showRestPinsNow();

    showPopup(notification);
  }

  void showSafetyAlert(String message) {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: '⚠️ Safety Alert',
      message: message,
      type: NotificationType.safety,
      priority: NotificationPriority.high,
      actions: [
        NotificationAction(label: 'Got it', actionId: 'acknowledge', color: Colors.orange),
      ],
    );
    showPopup(notification);
  }

  void showAchievement(String title, String description) {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: '🏆 Achievement Unlocked!',
      message: '$title\n$description',
      type: NotificationType.achievement,
      priority: NotificationPriority.normal,
    );
    showPopup(notification);
  }

  void showEarningsUpdate(double amount, String period) {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: '💵 Earnings Update',
      message: 'You\'ve earned \$${amount.toStringAsFixed(2)} $period',
      type: NotificationType.earnings,
      priority: NotificationPriority.low,
    );
    showPopup(notification);
  }

  void showAtlasInsight(String insight) {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: '🤖 Atlas Insight',
      message: insight,
      type: NotificationType.atlas,
      priority: NotificationPriority.normal,
      actions: [
        NotificationAction(label: 'Learn More', actionId: 'open_chat', color: Colors.purple),
      ],
    );
    showPopup(notification);
  }

  void startAutoNotifications() {
    _autoNotificationTimer?.cancel();
    _autoNotificationTimer = Timer.periodic(
      Duration(minutes: 3 + _random.nextInt(5)),
          (_) => _showRandomNotification(),
    );
  }

  void stopAutoNotifications() {
    _autoNotificationTimer?.cancel();
    _autoNotificationTimer = null;
  }

  void _showRandomNotification() {
    final notifications = [
          () => showDemandAlert('Downtown', 1.5 + _random.nextDouble()),
          () => showBonusProgress('Morning Rush', _random.nextInt(3) + 1, 5, 15.0),
          () => showWellnessReminder('You\'ve been driving for 2 hours. Time for a stretch?'),
          () => showAtlasInsight('Traffic is lighter on parallel routes. Consider alternate paths.'),
          () => showEarningsUpdate(25.50 + _random.nextDouble() * 20, 'in the last hour'),
    ];
    notifications[_random.nextInt(notifications.length)]();
  }

  void handleAction(String notificationId, String actionId) {
    switch (actionId) {
      case 'snooze':
      // Snoozing hides pins and resets thresholds
        hideRestPinsAndReset();
        break;
      case 'take_break':
      // Keep pins visible so they can pick a rest spot
        showRestPinsNow();
        break;
      case 'accept_trip':
      case 'decline_trip':
      case 'navigate_to_zone':
      case 'take_break_confirmed':
      case 'open_chat':
      case 'acknowledge':
      case 'dismiss':
      default:
        break;
    }
    dismissPopup(notificationId);
  }

  // ========= Rest timer (backend source of truth) =========

  int continuousMinutes = 0;
  int todayMinutes = 0;
  bool activeSession = false;
  DateTime? startedAt;

  static const int restSoonThreshold = 3;
  static const int takeBreakThreshold = 3;

  bool _restDemoMode = false;
  int _restDemoSecondsPerMinute = 1;

  String? _restUserId;
  Timer? _restPollTimer;

  bool _restAlert95Fired = false;
  bool _restAlert120Fired = false;

  Duration get _pollInterval =>
      _restDemoMode ? const Duration(seconds: 5) : const Duration(minutes: 1);

  void initRestTimer({
    required String userId,
    bool demoMode = false,
    int demoSecondsPerMinute = 1,
  }) {
    _restUserId = userId;
    _restDemoMode = demoMode;
    _restDemoSecondsPerMinute = demoSecondsPerMinute;

    _stopPolling();

    print('initRestTimer demo=$_restDemoMode user=$_restUserId');

    _syncRestWithServer(forceNotifyOnce: true);
    _startPolling();
  }

  Future<void> startRestSession() async {
    if (_restUserId != null) {
      try {
        await ApiClient.post(
          '/hours/start',
          queryParams: {'userId': _restUserId!},
        );
      } catch (e) {
        print('startRestSession error: $e');
      }
    }
    print('startRestSession called');
    await _syncRestWithServer(forceNotifyOnce: true);
  }

  Future<void> stopRestSession() async {
    if (_restUserId != null) {
      try {
        await ApiClient.post(
          '/hours/stop',
          queryParams: {'userId': _restUserId!},
        );
      } catch (e) {
        print('stopRestSession error: $e');
      }
    }
    await _syncRestWithServer(forceNotifyOnce: true);
  }

  void _startPolling() {
    _restPollTimer?.cancel();
    _restPollTimer = Timer.periodic(_pollInterval, (_) => _syncRestWithServer());
  }

  void _stopPolling() {
    _restPollTimer?.cancel();
    _restPollTimer = null;
  }

  Future<void> _syncRestWithServer({bool forceNotifyOnce = false}) async {
    if (_restUserId == null) return;

    try {
      final response = await ApiClient.get(
        '/hours/status',
        queryParams: {'userId': _restUserId!},
      );

      if (!response.success || response.dataAsMap == null) {
        print('_syncRestWithServer failed: ${response.message}');
        return;
      }

      final body = response.dataAsMap!;

      final serverContinuous = (body['continuous'] ?? 0) as int? ?? 0;
      final serverTotalToday = (body['totalContinuousToday'] ?? 0) as int? ?? 0;
      final serverActive = _parseBool(body['active']) ?? (serverContinuous > 0);

      DateTime? serverStartedAt;
      final rawStartedAt = body['startedAt'];
      if (rawStartedAt != null) {
        serverStartedAt = DateTime.tryParse(rawStartedAt.toString());
      }

      activeSession = serverActive;
      continuousMinutes = serverContinuous;
      todayMinutes = serverTotalToday;
      startedAt = serverStartedAt;

      print('_syncRestWithServer -> continuous=$continuousMinutes today=$todayMinutes active=$activeSession');

      _checkRestThresholdsAndAlert(forceNotify: forceNotifyOnce);
      _notifySafely();
    } catch (e) {
      print('_syncRestWithServer failed: $e');
    }
  }

  void _checkRestThresholdsAndAlert({bool forceNotify = false}) {
    if (!_restAlert95Fired && continuousMinutes >= restSoonThreshold) {
      _restAlert95Fired = true;
      showWellnessReminder('Rest soon — you have been driving for $continuousMinutes minutes.');
      if (forceNotify) _notifySafely();
    }
    if (!_restAlert120Fired && continuousMinutes >= takeBreakThreshold) {
      _restAlert120Fired = true;
      showWellnessReminder('Take a break — you have been driving for $continuousMinutes minutes.');
      if (forceNotify) _notifySafely();
    }

    // When going inactive, clear thresholds and hide pins
    if (!activeSession) {
      _restAlert95Fired = false;
      _restAlert120Fired = false;
      _setShowRestPins(false);
    }
  }

  @override
  void dispose() {
    stopAutoNotifications();
    _stopPolling();
    super.dispose();
  }

  bool? _parseBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return null;
  }

  void _notifySafely() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle || phase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }
}
