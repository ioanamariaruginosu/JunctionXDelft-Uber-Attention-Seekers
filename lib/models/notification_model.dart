import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final List<NotificationAction> actions;
  final bool isRead;
  final IconData icon;
  final Color color;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    DateTime? timestamp,
    this.data,
    List<NotificationAction>? actions,
    this.isRead = false,
    IconData? icon,
    Color? color,
  })  : timestamp = timestamp ?? DateTime.now(),
        actions = actions ?? [],
        icon = icon ?? _getDefaultIcon(type),
        color = color ?? _getDefaultColor(type);

  static IconData _getDefaultIcon(NotificationType type) {
    switch (type) {
      case NotificationType.demandAlert:
        return Icons.trending_up;
      case NotificationType.tripRequest:
        return Icons.directions_car;
      case NotificationType.bonus:
        return Icons.card_giftcard;
      case NotificationType.wellness:
        return Icons.health_and_safety;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.safety:
        return Icons.security;
      case NotificationType.earnings:
        return Icons.attach_money;
      case NotificationType.atlas:
        return Icons.assistant;
      default:
        return Icons.notifications;
    }
  }

  static Color _getDefaultColor(NotificationType type) {
    switch (type) {
      case NotificationType.demandAlert:
        return const Color(0xFFF59E0B);
      case NotificationType.tripRequest:
        return const Color(0xFF3B82F6);
      case NotificationType.bonus:
        return const Color(0xFF10B981);
      case NotificationType.wellness:
        return const Color(0xFF8B5CF6);
      case NotificationType.achievement:
        return const Color(0xFFFBBF24);
      case NotificationType.safety:
        return const Color(0xFFEF4444);
      case NotificationType.earnings:
        return const Color(0xFF10B981);
      case NotificationType.atlas:
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF6B7280);
    }
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    List<NotificationAction>? actions,
    bool? isRead,
    IconData? icon,
    Color? color,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      actions: actions ?? this.actions,
      isRead: isRead ?? this.isRead,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'actions': actions.map((a) => a.toJson()).toList(),
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      data: json['data'],
      actions: (json['actions'] as List?)
              ?.map((a) => NotificationAction.fromJson(a))
              .toList() ??
          [],
      isRead: json['isRead'] ?? false,
    );
  }
}

class NotificationAction {
  final String label;
  final String actionId;
  final Color? color;

  NotificationAction({
    required this.label,
    required this.actionId,
    this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'actionId': actionId,
    };
  }

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      label: json['label'],
      actionId: json['actionId'],
    );
  }
}

enum NotificationType {
  general,
  demandAlert,
  tripRequest,
  bonus,
  wellness,
  achievement,
  safety,
  earnings,
  atlas,
}

enum NotificationPriority { low, normal, high, urgent }