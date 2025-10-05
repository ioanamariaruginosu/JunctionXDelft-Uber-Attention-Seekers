// lib/services/rest_timer_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'notification_service.dart';

class RestTimerService extends ChangeNotifier {
  int continuousMinutes = 0;
  int todayMinutes = 0;
  bool activeSession = false;

  // thresholds (minutes)
  static const int restSoonThreshold = 105; // 1h45m
  static const int takeBreakThreshold = 120; // 2h

  // demo/testing
  final bool demoMode;
  final int demoSecondsPerMinute;

  final String userId;
  final Uri baseUrl;
  final NotificationService? notificationService;

  Timer? _tickTimer;
  Timer? _pollTimer;
  bool _alert105Fired = false;
  bool _alert120Fired = false;

  RestTimerService({
    required this.baseUrl,
    required this.userId,
    this.notificationService,
    this.demoMode = false,
    this.demoSecondsPerMinute = 1,
  }) {
    // bootstrap
    syncWithServer();
  }

  Duration get _tickDuration =>
      demoMode ? Duration(seconds: demoSecondsPerMinute) : const Duration(minutes: 1);

  Uri _statusUri() => baseUrl.replace(path: '${baseUrl.path}/hours/status', queryParameters: {'userId': userId});
  Uri _startUri() => baseUrl.replace(path: '${baseUrl.path}/hours/start', queryParameters: {'userId': userId});
  Uri _stopUri() => baseUrl.replace(path: '${baseUrl.path}/hours/stop', queryParameters: {'userId': userId});

  void startLocalTimer() {
    stopLocalTimer();
    _tickTimer = Timer.periodic(_tickDuration, (_) {
      continuousMinutes++;
      todayMinutes++;
      _checkThresholdsAndAlert();
      notifyListeners();
    });
  }

  void stopLocalTimer() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  Future<void> syncWithServer() async {
    try {
      final res = await http.get(_statusUri()).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(res.body) as Map<String, dynamic>;

        // map backend keys:
        continuousMinutes = (body['continuous'] ?? 0) as int;
        todayMinutes = (body['totalContinuousToday'] ?? 0) as int; // choose the best match for 'today'
        // if you prefer driving minutes, pick 'driving' or 'totalDrivingToday'

        // define active if continuous > 0 (or modify if backend provides explicit active flag)
        activeSession = continuousMinutes > 0;

        // immediate threshold evaluation (e.g., app opened after threshold passed)
        _checkThresholdsAndAlert(forceNotify: true);

        if (activeSession) startLocalTimer();
        else {
          stopLocalTimer();
          // reset fired-alerts when session stops (optional)
          _alert105Fired = false;
          _alert120Fired = false;
        }

        // poll to stay synced: faster in demo
        _pollTimer?.cancel();
        _pollTimer = Timer.periodic(demoMode ? const Duration(seconds: 5) : const Duration(minutes: 1), (_) {
          syncWithServer();
        });

        notifyListeners();
      } else {
        // server returned non-200 — ignore and keep local state
      }
    } catch (e) {
      // network error — keep local timers running if any
    }
  }

  Future<void> startSession() async {
    try {
      await http.post(_startUri()).timeout(const Duration(seconds: 5));
      await syncWithServer();
    } catch (_) {
      activeSession = true;
      startLocalTimer();
      notifyListeners();
    }
  }

  Future<void> stopSession() async {
    try {
      await http.post(_stopUri()).timeout(const Duration(seconds: 5));
      await syncWithServer();
    } catch (_) {
      activeSession = false;
      stopLocalTimer();
      continuousMinutes = 0;
      _alert105Fired = false;
      _alert120Fired = false;
      notifyListeners();
    }
  }

  void _checkThresholdsAndAlert({bool forceNotify = false}) {
    if (!_alert105Fired && continuousMinutes >= restSoonThreshold) {
      _alert105Fired = true;
      notificationService?.showWellnessReminder('Rest soon — you have been driving for $continuousMinutes minutes.');
      if (forceNotify) notifyListeners();
    }
    if (!_alert120Fired && continuousMinutes >= takeBreakThreshold) {
      _alert120Fired = true;
      notificationService?.showWellnessReminder('Take a break — you have been driving for $continuousMinutes minutes.');
      if (forceNotify) notifyListeners();
    }
  }

  @override
  void dispose() {
    stopLocalTimer();
    _pollTimer?.cancel();
    super.dispose();
  }
}