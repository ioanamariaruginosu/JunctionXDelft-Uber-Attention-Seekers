import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/atlas_ai_service.dart';
import '../services/break_status_service.dart';
import '../utils/api_client.dart';

class MascotWidget extends StatefulWidget {
  final String userId;

  const MascotWidget({
    Key? key,
    required this.userId,
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
  bool _hasShownRestNotification = false;
  bool _needsBreak = false;
  DateTime? _breakStartTime;
  int _totalDrivingMinutesToday = 0;
  int _continuousDrivingMinutes = 0;

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

    _startDrivingTimeCheck();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _glowController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _startDrivingTimeCheck() {
    _checkDrivingTime();
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _startDrivingTimeCheck();
      }
    });
  }

  Future<void> _checkDrivingTime() async {
    try {
      debugPrint('🔍 Checking driving time for user: ${widget.userId}');
      final response = await ApiClient.get(
          '/hours/status/${widget.userId}'
      );

      debugPrint('📡 API Response - Status: ${response.statusCode}, Success: ${response.success}');
      debugPrint('📦 Response data: ${response.dataAsMap}');

      if (response.success && response.dataAsMap != null) {
        final data = response.dataAsMap!;
        final totalContinuousToday = data['totalContinuousToday'] as int? ?? 0;
        final continuousDriving = data['continuous'] as int? ?? 0;

        setState(() {
          _totalDrivingMinutesToday = totalContinuousToday;
          _continuousDrivingMinutes = continuousDriving;
        });

        debugPrint('📊 Total today: $_totalDrivingMinutesToday mins, Continuous: $_continuousDrivingMinutes mins');
        debugPrint('🚦 Current state - needsBreak: $_needsBreak, hasShownNotification: $_hasShownRestNotification');

        // Check if user needs a break (driving >= 1 minute for testing, 600 for production)
        if (totalContinuousToday >= 1) {
          debugPrint('✅ Total driving exceeds threshold (1 min)');

          // Check if user is on a break (continuous driving is 0 or low)
          if (continuousDriving == 0 && _needsBreak) {
            debugPrint('⏸️ User is on break (continuous = 0)');
            // User might be on break
            if (_breakStartTime == null) {
              _breakStartTime = DateTime.now();
              debugPrint('🕐 Break timer started');
            } else {
              // Check if break has been 30 minutes
              final breakDuration = DateTime.now().difference(_breakStartTime!);
              debugPrint('⏱️ Break duration: ${breakDuration.inMinutes} minutes');
              if (breakDuration.inMinutes >= 1) {
                // Break completed, reset flags
                setState(() {
                  _needsBreak = false;
                  _hasShownRestNotification = false;
                  _breakStartTime = null;
                });
                // Update break status service
                context.read<BreakStatusService>().setNeedsBreak(false);
                debugPrint('✅ Break completed (30 mins), all flags reset');
              }
            }
          } else if (continuousDriving > 0) {
            debugPrint('🚗 User is currently driving (continuous: $continuousDriving)');
            // User is driving again, reset break timer but keep needsBreak flag
            _breakStartTime = null;

            if (!_needsBreak) {
              debugPrint('⚠️ Setting needsBreak to TRUE');
              setState(() {
                _needsBreak = true;
              });
              // Update break status service
              context.read<BreakStatusService>().setNeedsBreak(true);
            }

            // Show notification if not shown yet
            if (!_hasShownRestNotification) {
              debugPrint('🔔 SHOWING REST NOTIFICATION');
              _showRestNotification();
              _hasShownRestNotification = true;

              // Schedule recurring notification every 2 minutes
              _scheduleRecurringNotification();
            } else {
              debugPrint('ℹ️ Notification already shown, waiting for recurring schedule');
            }
          } else {
            debugPrint('⏹️ Continuous driving is 0 but needsBreak is false - waiting state');
          }
        } else {
          debugPrint('❌ Total driving time ($_totalDrivingMinutesToday) below threshold (1 min)');
        }
      } else {
        debugPrint('❌ API call failed - Status: ${response.statusCode}, Message: ${response.message}');
      }
    } catch (e, stackTrace) {
      debugPrint('💥 Error fetching driving time: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _scheduleRecurringNotification() {
    Future.delayed(const Duration(minutes: 2), () {
      if (mounted && _needsBreak && _continuousDrivingMinutes > 0) {
        _showRestNotification();
        // Recursively schedule next notification
        _scheduleRecurringNotification();
      }
    });
  }

  void _showRestNotification() {
    setState(() {
      _currentTip = '☕ You\'ve been driving for ${(_totalDrivingMinutesToday / 60).toStringAsFixed(1)} hours. Please take a 30-minute break!';
      _showTip = true;
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _showTip = false);
      }
    });
  }

  void _startTipCycle() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        if (!_needsBreak) {
          _showNextTip();
        }
        _startTipCycle();
      }
    });
  }

  void _showNextTip() {
    final tips = [
      '💰 Downtown surge active! +2.5x earnings',
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
    final breakStatusService = context.watch<BreakStatusService>();

    if (!atlasService.isEnabled) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
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
                color: _needsBreak ? Colors.orange.shade100 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: _needsBreak ? Border.all(color: Colors.orange, width: 2) : null,
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
                style: TextStyle(
                  color: _needsBreak ? Colors.orange.shade900 : Colors.black87,
                  fontSize: 14,
                  fontWeight: _needsBreak ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
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
                  onLongPress: () {
                    debugPrint('🧪 Manual test: Triggering rest notification');
                    setState(() {
                      _needsBreak = true;
                      _totalDrivingMinutesToday = 120;
                    });
                    context.read<BreakStatusService>().setNeedsBreak(true);
                    _showRestNotification();
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _needsBreak
                            ? [Colors.orange, Colors.deepOrange]
                            : [const Color(0xFF2196F3), const Color(0xFF1976D2)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_needsBreak ? Colors.orange : Colors.amber)
                              .withOpacity(0.5 * _glowAnimation.value),
                          blurRadius: 20 * _glowAnimation.value,
                          spreadRadius: 5 * _glowAnimation.value,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: HappyFacePainter(needsBreak: _needsBreak),
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
  final bool needsBreak;

  HappyFacePainter({this.needsBreak = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    if (needsBreak) {
      final rect1 = Rect.fromCircle(center: Offset(center.dx - 12, center.dy - 8), radius: 5);
      canvas.drawArc(rect1, 0, math.pi, false, eyePaint);

      final rect2 = Rect.fromCircle(center: Offset(center.dx + 12, center.dy - 8), radius: 5);
      canvas.drawArc(rect2, 0, math.pi, false, eyePaint);
    } else {
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
    }
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();

    if (needsBreak) {
      mouthPath.moveTo(center.dx - 15, center.dy + 10);
      mouthPath.lineTo(center.dx + 15, center.dy + 10);
    } else {
      mouthPath.moveTo(center.dx - 15, center.dy + 5);
      mouthPath.quadraticBezierTo(
        center.dx,
        center.dy + 18,
        center.dx + 15,
        center.dy + 5,
      );
    }

    canvas.drawPath(mouthPath, mouthPaint);
  }

  @override
  bool shouldRepaint(HappyFacePainter oldDelegate) => oldDelegate.needsBreak != needsBreak;
}