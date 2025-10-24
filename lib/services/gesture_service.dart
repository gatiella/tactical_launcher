import 'package:flutter/material.dart';

enum SwipeDirection { up, down, left, right }

class GestureService extends ChangeNotifier {
  Function()? onSwipeUp;
  Function()? onSwipeDown;
  Function()? onSwipeLeft;
  Function()? onSwipeRight;
  Function()? onDoubleTap;
  Function()? onLongPress;

  void handleSwipe(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.up:
        onSwipeUp?.call();
        break;
      case SwipeDirection.down:
        onSwipeDown?.call();
        break;
      case SwipeDirection.left:
        onSwipeLeft?.call();
        break;
      case SwipeDirection.right:
        onSwipeRight?.call();
        break;
    }
    notifyListeners();
  }

  void handleDoubleTap() {
    onDoubleTap?.call();
    notifyListeners();
  }

  void handleLongPress() {
    onLongPress?.call();
    notifyListeners();
  }
}