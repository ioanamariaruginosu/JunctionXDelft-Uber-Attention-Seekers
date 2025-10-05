import 'package:flutter/material.dart';

class SlideToGoOnline extends StatefulWidget {
  final bool isOnline;
  final Function(bool) onChanged;

  const SlideToGoOnline({
    Key? key,
    required this.isOnline,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<SlideToGoOnline> createState() => _SlideToGoOnlineState();
}

class _SlideToGoOnlineState extends State<SlideToGoOnline> with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  bool _isDragging = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: widget.isOnline ? 80 : 140,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: widget.isOnline
            ? _buildOnlineStatus(theme)
            : _buildSlider(size, theme),
      ),
    );
  }

  Widget _buildOnlineStatus(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'You\'re Online',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ready to accept trips',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: () => widget.onChanged(false),
            child: const Text('Go Offline'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(Size size, ThemeData theme) {
    const sliderHeight = 60.0; // Reduced from 70
    const thumbSize = 50.0; // Reduced from 60
    final maxDrag = size.width - 48 - thumbSize;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), // Reduced vertical padding
      child: Stack(
        children: [
          // Background track
          Container(
            height: sliderHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade300,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isDragging ? 1.0 : _pulseAnimation.value,
                    child: Text(
                      'Slide to go online',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Animated fill
          AnimatedContainer(
            duration: _isDragging
                ? Duration.zero
                : const Duration(milliseconds: 300),
            height: sliderHeight,
            width: _dragPosition + thumbSize,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4CAF50),
                  Color(0xFF66BB6A),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
          ),

          // Draggable thumb
          AnimatedPositioned(
            duration: _isDragging
                ? Duration.zero
                : const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: _dragPosition,
            top: (sliderHeight - thumbSize) / 2,
            child: GestureDetector(
              onHorizontalDragStart: (_) {
                setState(() => _isDragging = true);
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _dragPosition = (_dragPosition + details.delta.dx)
                      .clamp(0.0, maxDrag);
                });
              },
              onHorizontalDragEnd: (_) {
                if (_dragPosition > maxDrag * 0.8) {
                  widget.onChanged(true);
                  setState(() {
                    _dragPosition = 0;
                    _isDragging = false;
                  });
                } else {
                  setState(() {
                    _dragPosition = 0;
                    _isDragging = false;
                  });
                }
              },
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: _dragPosition > maxDrag * 0.5
                      ? Colors.green
                      : Colors.grey.shade600,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}