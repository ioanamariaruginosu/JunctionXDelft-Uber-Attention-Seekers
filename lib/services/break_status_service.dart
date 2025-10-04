import 'package:flutter/material.dart';

class BreakStatusService extends ChangeNotifier {
  bool _needsBreak = false;

  bool get needsBreak => _needsBreak;

  void setNeedsBreak(bool value) {
    if (_needsBreak != value) {
      _needsBreak = value;
      notifyListeners();
    }
  }
}