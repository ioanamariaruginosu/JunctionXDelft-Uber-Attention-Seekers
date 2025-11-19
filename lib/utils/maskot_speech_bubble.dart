import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/maskot_ai_service.dart';

class MaskotSpeechBubble extends StatefulWidget {
  final TripModel trip;
  final MaskotAIService maskotService;

  const MaskotSpeechBubble({
    Key? key,
    required this.trip,
    required this.maskotService,
  }) : super(key: key);

  @override
  State<MaskotSpeechBubble> createState() => _MaskotSpeechBubbleState();
}

class _MaskotSpeechBubbleState extends State<MaskotSpeechBubble>
    with SingleTickerProviderStateMixin {
  late final Future<String> _analysisFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _analysisFuture = widget.maskotService.analyzeTripRequest(widget.trip);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<String>(
      future: _analysisFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingBubble(theme);
        }

        if (snapshot.hasError) {
          return _buildErrorBubble(theme);
        }

        if (snapshot.hasData && snapshot.data != null) {
          return _buildSpeechBubble(theme, snapshot.data!);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingBubble(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF9C27B0).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9C27B0), width: 2),
      ),
      child: Row(
        children: [
          _buildMaskotAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maskot',
                  style: TextStyle(
                    color: const Color(0xFF9C27B0),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF9C27B0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Let me analyze this trip for you...',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBubble(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Row(
        children: [
          _buildMaskotAvatar(isError: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Maskot',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sorry, I couldn\'t analyze this trip. Network issue detected.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechBubble(ThemeData theme, String recommendation) {
    final lines = recommendation.split('\n');

    Color bubbleColor;
    Color borderColor;

    if (lines.isNotEmpty) {
      final mainRec = lines[0];
      if (mainRec.contains('ACCEPT NOW') || mainRec.contains('Exceptional')) {
        bubbleColor = Colors.green.withOpacity(0.15);
        borderColor = Colors.green;
      } else if (mainRec.contains('ACCEPT') && mainRec.contains('Strong')) {
        bubbleColor = Colors.blue.withOpacity(0.15);
        borderColor = Colors.blue;
      } else if (mainRec.contains('CONSIDER')) {
        bubbleColor = Colors.orange.withOpacity(0.15);
        borderColor = Colors.orange;
      } else if (mainRec.contains('MARGINAL') || mainRec.contains('SKIP')) {
        bubbleColor = Colors.red.withOpacity(0.15);
        borderColor = Colors.red;
      } else {
        bubbleColor = const Color(0xFF9C27B0).withOpacity(0.1);
        borderColor = const Color(0xFF9C27B0);
      }
    } else {
      bubbleColor = const Color(0xFF9C27B0).withOpacity(0.1);
      borderColor = const Color(0xFF9C27B0);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: borderColor.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildMaskotAvatar(borderColor: borderColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Maskot',
                              style: TextStyle(
                                color: borderColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: borderColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Your Co-Pilot',
                                style: TextStyle(
                                  color: borderColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                _formatAsMaskotSpeech(recommendation),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaskotAvatar({bool isError = false, Color? borderColor}) {
    String mascotImage;
    if (isError) {
      mascotImage = 'assets/images/Mascot_tired.png';
    } else if (borderColor == Colors.green) {
      mascotImage = 'assets/images/Mascot_normal.png';
    } else if (borderColor == Colors.red) {
      mascotImage = 'assets/images/Mascot_angry.png';
    } else {
      mascotImage = 'assets/images/Mascot_normal.png';
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? const Color(0xFF9C27B0)).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          mascotImage,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _formatAsMaskotSpeech(String recommendation) {
    String formatted = recommendation;

    if (formatted.contains('ACCEPT NOW')) {
      formatted = formatted.replaceFirst(
          RegExp(r'[🔥✅⚠️❌🤔]*\s*ACCEPT NOW - '),
          'Hey! This is an excellent opportunity. '
      );
    } else if (formatted.contains('ACCEPT - Strong')) {
      formatted = formatted.replaceFirst(
          RegExp(r'[🔥✅⚠️❌🤔]*\s*ACCEPT - '),
          'I recommend taking this trip. '
      );
    } else if (formatted.contains('CONSIDER')) {
      formatted = formatted.replaceFirst(
          RegExp(r'[🔥✅⚠️❌🤔]*\s*CONSIDER - '),
          'This one is okay, but not amazing. '
      );
    } else if (formatted.contains('MARGINAL')) {
      formatted = formatted.replaceFirst(
          RegExp(r'[🔥✅⚠️❌🤔]*\s*MARGINAL - '),
          'I\'d only take this if you really need it. '
      );
    } else if (formatted.contains('SKIP')) {
      formatted = formatted.replaceFirst(
          RegExp(r'[🔥✅⚠️❌🤔]*\s*SKIP - '),
          'I suggest skipping this one. '
      );
    }

    formatted = formatted
        .replaceAll('Earnings:', 'You\'ll earn:')
        .replaceAll('Time:', 'It\'ll take:')
        .replaceAll('Distance:', 'Distance:')
        .replaceAll('Score:', 'My score for this:')
        .replaceAll('Wait advice:', '\n\nTiming wise:')
        .replaceAll('Top 25% of drivers', 'Just so you know, top drivers');

    return formatted.trim();
  }
}
