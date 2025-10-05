import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/maskot_ai_service.dart';
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
  String _currentImage = 'assets/images/Mascot_normal.png'; 
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

    _startTipCycle();
  }

  void _updateMascotImage(String tip) {
  if (tip.contains('surge')) {
    _currentImage = 'assets/images/Mascot_angry.png';
  } else if (tip.contains('Break') || tip.contains('wellness')) {
    _currentImage = 'assets/images/Mascot_tired.png';
  } else if (tip.contains('bonus')) {
    _currentImage = 'assets/images/Mascot_angry.png';
  } else if (tip.contains('weather') || tip.contains('🌤')) {
    _currentImage = 'assets/images/Mascot_normal.png';
  } else {
    _currentImage = 'assets/images/Mascot_normal.png';
  }
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

  void _showNextTip() {
    final tips = [
      '💰 Downtown surge active! +2.5x earnings',
      '☕ You\'ve been driving for 2 hours. Break time?',
      '🎯 Complete 2 more trips for \$15 bonus!',
      '📈 Your earnings are up 20% today!',
      '🚗 Airport runs are busy right now',
      '⭐ Great job! Your rating is 4.9',
      '🔥 Tech Park has high demand!',
      '💵 You\'re on track to hit your daily goal',
      '🌟 5 rides until weekend bonus!',
      '⚡ Quick trips near you - maximize earnings',
      '🌤 Current weather: Light Rain',
    ];

    final tip = tips[math.Random().nextInt(tips.length)];

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
    double mascotBottom = 80 + _floatingAnimation.value; 

    final maskotService = context.watch<MaskotAIService>();
    if (!maskotService.isEnabled) return const SizedBox.shrink();

    return Stack(
      children: [
        PopupSystem(
          mascotSize: mascotSize,
          mascotBottom: mascotBottom,
        ),

        Positioned(
          bottom: mascotBottom,
          right: 20,
          child: GestureDetector(
            onTap: _showNextTip,
            child: Container(
              width: mascotSize,
              height: mascotSize,
              child: ClipOval(
                child: Image.asset(_currentImage, fit: BoxFit.contain),
              ),
            ),
          ),
        ),

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

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(center.dx - 12, center.dy - 8),
      5,
      eyePaint,
    );

    canvas.drawCircle(
      Offset(center.dx + 12, center.dy - 8),
      5,
      eyePaint,
    );

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
