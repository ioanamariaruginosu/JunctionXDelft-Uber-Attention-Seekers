import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/trip_model.dart';

class NotificationService extends ChangeNotifier {
  final List<NotificationModel> _activePopups = [];
  final Random _random = Random();
  Timer? _autoNotificationTimer;

  List<NotificationModel> get activePopups => _activePopups;

  void showPopup(NotificationModel notification) {
    _activePopups.add(notification);
    notifyListeners();

    if (notification.priority != NotificationPriority.urgent) {
      Timer(const Duration(seconds: 10), () {
        dismissPopup(notification.id);
      });
    }
  }

  void dismissPopup(String notificationId) {
    _activePopups.removeWhere((n) => n.id == notificationId);
    notifyListeners();
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
        NotificationAction(
          label: 'Accept',
          actionId: 'accept_trip',
          color: Colors.green,
        ),
        NotificationAction(
          label: 'Decline',
          actionId: 'decline_trip',
          color: Colors.red,
        ),
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
        NotificationAction(
          label: 'Navigate',
          actionId: 'navigate_to_zone',
          color: Colors.blue,
        ),
        NotificationAction(
          label: 'Dismiss',
          actionId: 'dismiss',
        ),
      ],
    );
    showPopup(notification);
  }

  void showBonusProgress(String bonusTitle, int current, int target, double reward) {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: '💰 Bonus Progress',
      message: '$bonusTitle: $current/$target trips\nComplete for +\\\$$reward!',
      type: NotificationType.bonus,
      priority: NotificationPriority.normal,
    );
    showPopup(notification);
  }

  void showWellnessReminder(String message) {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: '☕ Wellness Check',
      message: message,
      type: NotificationType.wellness,
      priority: NotificationPriority.normal,
      actions: [
        NotificationAction(
          label: 'Take Break',
          actionId: 'take_break',
          color: Colors.green,
        ),
        NotificationAction(
          label: 'Snooze 30 min',
          actionId: 'snooze',
        ),
      ],
    );
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
        NotificationAction(
          label: 'Got it',
          actionId: 'acknowledge',
          color: Colors.orange,
        ),
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
        NotificationAction(
          label: 'Learn More',
          actionId: 'open_chat',
          color: Colors.purple,
        ),
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
      case 'accept_trip':
        dismissPopup(notificationId);
        break;
      case 'decline_trip':
        dismissPopup(notificationId);
        break;
      case 'navigate_to_zone':
        dismissPopup(notificationId);
        break;
      case 'take_break':
        dismissPopup(notificationId);
        break;
      case 'snooze':
        dismissPopup(notificationId);
        break;
      case 'open_chat':
        dismissPopup(notificationId);
        break;
      default:
        dismissPopup(notificationId);
    }
  }

  void clearAllPopups() {
    _activePopups.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoNotifications();
    super.dispose();
  }
}