import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/maskot_ai_service.dart';
import '../services/notification_service.dart';
import '../services/mock_data_service.dart';
import '../services/demand_service.dart';
import '../models/notification_model.dart';
import 'popup_system.dart';

class MascotWidget extends StatefulWidget {
  const MascotWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget> with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _glowController;
  late AnimationController _rotationController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;

  String _currentTip = '';
  String _currentImage = 'assets/images/Mascot_normal.png'; // default image (fallback for tips)
  bool _showTip = false;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _floatingAnimation = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    // Start showing random tips
    _startTipCycle();
  }

  // Keep tip-informed fallback image, but overall image will be chosen based on NotificationService
  void _updateMascotImage(String tip) {
    if (tip.contains('surge')) {
      _currentImage = 'assets/images/Mascot_angry.png';
    } else if (tip.contains('Break') || tip.contains('wellness')) {
      _currentImage = 'assets/images/Mascot_tired.png';
    } else if (tip.contains('bonus')) {
      _currentImage = 'assets/images/Mascot_angry.png';
    } else {
      _currentImage = 'assets/images/Mascot_normal.png';
    }
  }

  // Decide mascot image based on notification and session state. Higher priority rules first.
  String _chooseMascotImage(NotificationService notif) {
    // 1) If there is a safety alert active while the driver is online, show angry
    final hasSafety = notif.activePopups.any((p) => p.type == NotificationType.safety);
    final hasWeather = notif.activePopups.any((p) => p.title.toLowerCase().contains('weather') || p.message.toLowerCase().contains('weather') || p.message.toLowerCase().contains('rain') || p.message.toLowerCase().contains('storm'));
    if (notif.activeSession && (hasSafety || hasWeather)) {
      return 'assets/images/Mascot_angry.png';
    }

    // 2) If the rest timer indicates take-break threshold, show tired
    if (notif.continuousMinutes >= NotificationService.takeBreakThreshold) {
      return 'assets/images/Mascot_tired.png';
    }

    // 3) If a wellness popup is active, also show tired
    final hasWellness = notif.activePopups.any((p) => p.type == NotificationType.wellness);
    if (hasWellness) return 'assets/images/Mascot_tired.png';

    // 4) If there are urgent demand alerts (surge), show angry
    final hasDemand = notif.activePopups.any((p) => p.type == NotificationType.demandAlert);
    if (hasDemand) return 'assets/images/Mascot_angry.png';

    // 5) Default: use tip-derived image (fallback)
    return _currentImage;
  }


  @override
  void dispose() {
    _floatingController.dispose();
    _glowController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _startTipCycle() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _showNextTip();
        _startTipCycle();
      }
    });
  }

  // HERE ARE THE TIPS
  void _showNextTip() {
    // Prefer real contextual data when available
    final maskotService = context.read<MaskotAIService>();
    final mockData = context.read<MockDataService>();
    final notif = context.read<NotificationService>();
    final demand = context.read<DemandService>();

    String tip = '';

    // 1) If there's an active urgent popup, show it
    if (notif.activePopups.isNotEmpty) {
      final p = notif.activePopups.first;
      tip = '${p.title}: ${p.message}';
    }

    // 2) If there's an incoming trip request, show a concise summary
    else if (mockData.currentTripRequest != null) {
      final t = mockData.currentTripRequest!;
      tip = 'New request: ${t.pickupLocation} → ${t.dropoffLocation} • \$${t.totalEarnings.toStringAsFixed(2)} • ${t.estimatedDuration.inMinutes}m';
    }

    // 3) If on an active trip, give supportive message
    else if (mockData.activeTrip != null) {
      final t = mockData.activeTrip!;
      tip = 'On trip to ${t.dropoffLocation}. Stay safe — you\'re doing great!';
    }

    // 4) High demand zones
    else if (mockData.demandZones.isNotEmpty) {
      final highest = mockData.demandZones.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (highest.value >= 1.8) {
        tip = 'High demand at ${highest.key}: ${highest.value.toStringAsFixed(1)}x — good time to accept rides.';
      }
    }

    // 5) Earnings nudges
    else if (mockData.todayEarnings != null && mockData.todayEarnings!.totalEarnings >= 50 && math.Random().nextBool()) {
      tip = 'Great progress — you\'ve earned \$${mockData.todayEarnings!.totalEarnings.toStringAsFixed(0)} today!';
    }

    // 6) DemandService hints
    else if (demand.currentZoneDemand != null) {
      final z = demand.currentZoneDemand!;
      if (z.level != null) {
        tip = 'Current demand: ${z.level} — ${z.action}';
      }
    }

    // 7) Fallback to maskot service suggestion if present
    if (tip.isEmpty) {
      // If demo mode is enabled, prefer recent scripted messages from the service
      if (maskotService.messages.isNotEmpty) {
        tip = maskotService.messages.first.text;
      } else if (maskotService.currentSuggestion != null) {
        tip = maskotService.currentSuggestion!;
      }
    }

    // 8) Final fallback: random helpful tips
    if (tip.isEmpty) {
      final tips = [
        '💡 Pro tip: Position yourself near hotels in the morning for airport runs!',
        '☕ Safety first: Take breaks every 3 hours to maintain focus',
        '🔥 Focus on surge zones during peak hours',
        '⭐ Check your bonus progress to unlock rewards',
        '⚡ Quick trips nearby can boost earnings per hour',
      ];
      tip = tips[math.Random().nextInt(tips.length)];
    }

    setState(() {
      _currentTip = tip;
      _showTip = true;
      _updateMascotImage(tip);
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showTip = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double mascotSize = MediaQuery.of(context).size.width * 0.15;
    double mascotBottom = 80 + _floatingAnimation.value; // current mascot bottom

  final maskotService = context.watch<MaskotAIService>();
  final notif = context.watch<NotificationService>();
    if (!maskotService.isEnabled) return const SizedBox.shrink();

    return Stack(
      children: [
        // Popup above mascot
        PopupSystem(
          mascotSize: mascotSize,
          mascotBottom: mascotBottom,
        ),

        // Mascot itself
        Positioned(
          bottom: mascotBottom,
          right: 20,
          child: GestureDetector(
            onTap: _showNextTip,
            child: Container(
              width: mascotSize,
              height: mascotSize,
                child: ClipOval(
                child: Image.asset(_chooseMascotImage(notif), fit: BoxFit.contain),
              ),
            ),
          ),
        ),

        // Tip bubble (optional)
        if (_showTip)
          Positioned(
            bottom: mascotBottom + mascotSize + 10,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                _currentTip,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }


}

class HappyFacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Eyes
    final eyePaint = Paint()
      ..color = Colors.white
      //..color = Color.blue
      ..style = PaintingStyle.fill;

    // Left eye
    canvas.drawCircle(
      Offset(center.dx - 12, center.dy - 8),
      5,
      eyePaint,
    );

    // Right eye
    canvas.drawCircle(
      Offset(center.dx + 12, center.dy - 8),
      5,
      eyePaint,
    );

    // Smile
    final smilePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final smilePath = Path();
    smilePath.moveTo(center.dx - 15, center.dy + 5);
    smilePath.quadraticBezierTo(
      center.dx,
      center.dy + 18,
      center.dx + 15,
      center.dy + 5,
    );

    canvas.drawPath(smilePath, smilePaint);
  }

  @override
  bool shouldRepaint(HappyFacePainter oldDelegate) => false;
}