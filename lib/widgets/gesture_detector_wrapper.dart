import 'package:flutter/material.dart';
import '../services/gesture_service.dart';
import '../themes/terminal_theme.dart';

class GestureDetectorWrapper extends StatefulWidget {
  final Widget child;
  final GestureService gestureService;

  const GestureDetectorWrapper({
    super.key,
    required this.child,
    required this.gestureService,
  });

  @override
  State<GestureDetectorWrapper> createState() => _GestureDetectorWrapperState();
}

class _GestureDetectorWrapperState extends State<GestureDetectorWrapper>
    with SingleTickerProviderStateMixin {
  Offset? _swipeStart;
  bool _showGestureHint = false;
  String _gestureHintText = '';
  late AnimationController _hintController;
  late Animation<double> _hintAnimation;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _hintAnimation = CurvedAnimation(
      parent: _hintController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  void _showHint(String text) {
    setState(() {
      _gestureHintText = text;
      _showGestureHint = true;
    });
    _hintController.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _hintController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showGestureHint = false;
            });
          }
        });
      }
    });
  }

  void _handleSwipe(DragEndDetails details) {
    if (_swipeStart == null) return;

    final velocity = details.velocity.pixelsPerSecond;
    final dx = velocity.dx;
    final dy = velocity.dy;

    if (dx.abs() > dy.abs()) {
      // Horizontal swipe
      if (dx > 500) {
        // Swipe right
        widget.gestureService.handleSwipe(SwipeDirection.right);
        _showHint('Swipe Right: Next Theme');
      } else if (dx < -500) {
        // Swipe left
        widget.gestureService.handleSwipe(SwipeDirection.left);
        _showHint('Swipe Left: Previous Theme');
      }
    } else {
      // Vertical swipe
      if (dy > 500) {
        // Swipe down
        widget.gestureService.handleSwipe(SwipeDirection.down);
        _showHint('Swipe Down: Show Apps');
      } else if (dy < -500) {
        // Swipe up
        widget.gestureService.handleSwipe(SwipeDirection.up);
        _showHint('Swipe Up: Toggle Widgets');
      }
    }

    _swipeStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        _swipeStart = details.globalPosition;
      },
      onPanEnd: _handleSwipe,
      onDoubleTap: () {
        widget.gestureService.handleDoubleTap();
        _showHint('Double Tap: Clear Terminal');
      },
      onLongPress: () {
        widget.gestureService.handleLongPress();
        _showHint('Long Press: Settings');
      },
      child: Stack(
        children: [
          widget.child,
          if (_showGestureHint)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _hintAnimation,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: TerminalTheme.black.withOpacity(0.9),
                      border: Border.all(
                        color: TerminalTheme.cyberCyan,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: TerminalTheme.cyberCyan.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      _gestureHintText,
                      style: TerminalTheme.promptText.copyWith(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}