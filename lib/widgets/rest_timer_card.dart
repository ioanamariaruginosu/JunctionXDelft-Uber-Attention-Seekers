import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/rest_timer_service.dart';

class RestTimerCard extends StatelessWidget {
  const RestTimerCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RestTimerService>();
    final continuous = service.continuousMinutes;
    final today = service.todayMinutes;

    String? message;
    Color? messageColor;
    if (continuous >= RestTimerService.takeBreakThreshold) {
      message = 'Take a break';
      messageColor = Colors.redAccent;
    } else if (continuous >= RestTimerService.restSoonThreshold) {
      message = 'Rest soon';
      messageColor = Colors.orangeAccent;
    }

    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Continuous: $continuous min', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text('Today: $today min', style: Theme.of(context).textTheme.bodyMedium),
            ]),
            if (message != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: messageColor?.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(message, style: TextStyle(color: messageColor, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}