import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/atlas_ai_service.dart';

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
    ];

    setState(() {
      _currentTip = tips[math.Random().nextInt(tips.length)];
      _showTip = true;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showTip = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final atlasService = context.watch<AtlasAIService>();

    if (!atlasService.isEnabled) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Tip bubble
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          bottom: _showTip ? 100 : 80,
          right: 20,
          child: AnimatedOpacity(
            opacity: _showTip ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: const BoxConstraints(maxWidth: 250),
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
        ),
        // Happy face
        Positioned(
          bottom: 20,
          right: 20,
          child: AnimatedBuilder(
            animation: Listenable.merge([_floatingAnimation, _glowAnimation]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value),
                child: GestureDetector(
                  onTap: _showNextTip,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        //colors: [Color(0xFFFFC107), Color(0xFFFFB300)],
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5 * _glowAnimation.value),
                          blurRadius: 20 * _glowAnimation.value,
                          spreadRadius: 5 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: HappyFacePainter(),
                    ),
                  ),
                ),
              );
            },
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