import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../utils/theme.dart';

class PopupSystem extends StatelessWidget {
  const PopupSystem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationService = context.watch<NotificationService>();
    final activePopups = notificationService.activePopups;

    return Stack(
      children: activePopups.map((notification) {
        final index = activePopups.indexOf(notification);
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          top: MediaQuery.of(context).padding.top + 60 + (index * 120.0),
          left: 16,
          right: 16,
          child: NotificationPopup(
            notification: notification,
            onDismiss: () => notificationService.dismissPopup(notification.id),
            onAction: (actionId) => notificationService.handleAction(notification.id, actionId),
          ),
        );
      }).toList(),
    );
  }
}

class NotificationPopup extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final Function(String) onAction;

  const NotificationPopup({
    Key? key,
    required this.notification,
    required this.onDismiss,
    required this.onAction,
  }) : super(key: key);

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notification = widget.notification;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  side: BorderSide(
                    color: notification.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.surface,
                        theme.colorScheme.surface.withOpacity(0.95),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: notification.color.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppConstants.cardRadius),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: notification.color.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                notification.icon,
                                color: notification.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                notification.title,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: widget.onDismiss,
                              iconSize: 20,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.message,
                              style: AppTextStyles.bodyMedium,
                            ),
                            if (notification.actions.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: notification.actions.map((action) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: TextButton(
                                      onPressed: () => widget.onAction(action.actionId),
                                      style: TextButton.styleFrom(
                                        backgroundColor: action.color?.withOpacity(0.2),
                                        foregroundColor: action.color ?? theme.colorScheme.primary,
                                      ),
                                      child: Text(action.label),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}