import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../utils/api_client.dart';
import '../utils/constants.dart';

class MaskotAIService extends ChangeNotifier {
  final Random _random = Random();
  final List<ChatMessage> _messages = [];

  MaskotState _currentState = MaskotState.idle;
  String? _currentSuggestion;
  bool _isTyping = false;
  bool _isEnabled = true;

  List<ChatMessage> get messages => _messages;
  MaskotState get currentState => _currentState;
  String? get currentSuggestion => _currentSuggestion;
  bool get isTyping => _isTyping;
  bool get isEnabled => _isEnabled;

  MaskotAIService() {
    _initializeMaskot();
  }

  void _initializeMaskot() {
    final greeting = Constants.maskotGreetings[_random.nextInt(Constants.maskotGreetings.length)];
    _addMessage(ChatMessage(
      text: greeting,
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void setState(MaskotState state) {
    _currentState = state;
    notifyListeners();
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    _addMessage(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _isTyping = true;
    notifyListeners();

    await Future.delayed(Duration(seconds: 1 + _random.nextInt(2)));

    final response = _generateResponse(text);
    _addMessage(ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
    ));

    _isTyping = false;
    notifyListeners();
  }

  String _generateResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('best area') || lowerMessage.contains('hotspot') || lowerMessage.contains('where')) {
      return _getHotspotResponse();
    } else if (lowerMessage.contains('break') || lowerMessage.contains('tired') || lowerMessage.contains('rest')) {
      return _getBreakResponse();
    } else if (lowerMessage.contains('how am i doing') || lowerMessage.contains('stats') || lowerMessage.contains('performance')) {
      return _getPerformanceResponse();
    } else if (lowerMessage.contains('bonus') || lowerMessage.contains('quest') || lowerMessage.contains('challenge')) {
      return _getBonusResponse();
    } else if (lowerMessage.contains('tip') || lowerMessage.contains('advice') || lowerMessage.contains('help')) {
      return _getTipResponse();
    } else {
      return _getGenericResponse();
    }
  }

  String _getHotspotResponse() {
    final zones = ['Downtown', 'Airport', 'University District'];
    final zone = zones[_random.nextInt(zones.length)];
    final surge = (1.5 + _random.nextDouble() * 1.5).toStringAsFixed(1);
    return '🔥 Top hotspots right now:\n\n1. $zone - ${surge}x surge\n2. Tech Park - High demand\n3. Entertainment District - Bar rush starting\n\nI recommend heading to $zone for the best earnings!';
  }

  String _getBreakResponse() {
    final minutes = 15 + _random.nextInt(30);
    return 'You\'ve been driving for a while. I suggest taking a $minutes-minute break. There\'s a rest area 0.5 miles away with good facilities. Demand will pick up again around ${_getTimeString(minutes)}. Stay hydrated! 💧';
  }

  String _getPerformanceResponse() {
    final earnings = 50 + _random.nextInt(100);
    final trips = 5 + _random.nextInt(10);
    final rating = (4.5 + _random.nextDouble() * 0.5).toStringAsFixed(1);
    return '📊 Your performance today:\n\n💰 Earnings: \\\$$earnings\n🚗 Trips: $trips\n⭐ Rating: $rating\n⏱️ Avg trip time: 12 mins\n\nYou\'re doing great! You\'re on track to exceed your daily goal!';
  }

  String _getBonusResponse() {
    return '🎯 Active bonuses:\n\n1. Complete 2 more trips for +\\\$15\n2. Morning rush bonus: 3/5 trips done\n3. Weekend warrior: \\\$50 for 20 trips\n\nFocus on quick trips to maximize bonus completion!';
  }

  String _getTipResponse() {
    final tips = [
      '💡 Pro tip: Position yourself near hotels in the morning for airport runs!',
      '💡 Smart move: Avoid downtown during construction hours (2-4 PM)',
      '💡 Earning hack: Chain rides in the same area to minimize dead miles',
      '💡 Safety first: Take breaks every 3 hours to maintain your rating',
      '💡 Money maker: Focus on surge zones during peak hours',
    ];
    return tips[_random.nextInt(tips.length)];
  }

  String _getGenericResponse() {
    final responses = [
      'I\'m here to help! What would you like to know?',
      'Great question! Let me analyze the data for you...',
      Constants.maskotEncouragements[_random.nextInt(Constants.maskotEncouragements.length)],
      'Based on current patterns, you\'re making smart choices!',
    ];
    return responses[_random.nextInt(responses.length)];
  }

  String _getTimeString(int minutesFromNow) {
    final future = DateTime.now().add(Duration(minutes: minutesFromNow));
    final hour = future.hour > 12 ? future.hour - 12 : future.hour;
    final period = future.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${future.minute.toString().padLeft(2, '0')} $period';
  }

  Future<String> analyzeTripRequest(TripModel trip) async {
    setState(MaskotState.analyzing);

    try {
      // Send trip data to backend using ApiClient
      final response = await ApiClient.post(
        '/analyze-trip',
        body: {
          'profitabilityScore': trip.profitabilityScore,
          'totalEarnings': trip.totalEarnings,
          'estimatedDuration': trip.estimatedDuration.inMinutes,
          'distance': trip.distance,
          'surgeMultiplier': trip.surgeMultiplier,
          'pickupLocation': trip.pickupLocation,
          'dropoffLocation': trip.dropoffLocation,
        },
      );

      if (response.success && response.dataAsMap != null) {
        _currentSuggestion = response.dataAsMap!['suggestion'];
      } else {
        _currentSuggestion = '❌ Error: ${response.message ?? "Failed to analyze trip"}';
      }
    } catch (e) {
      print('Error calling backend: $e');
      _currentSuggestion = '❌ Network error. Using offline analysis.';

      // Fallback to local logic
      _currentSuggestion = _getLocalSuggestion(trip);
    }

    Timer(const Duration(seconds: 2), () {
      setState(MaskotState.idle);
    });

    return _currentSuggestion!;
  }

// Fallback local analysis
  String _getLocalSuggestion(TripModel trip) {
    final profitScore = trip.profitabilityScore;
    String recommendation;
    String reason;

    if (profitScore >= 7) {
      recommendation = '✅ ACCEPT - Excellent opportunity!';
      reason = 'High profitability, good surge, likely return trip';
    } else if (profitScore >= 5) {
      recommendation = '⚠️ ACCEPT - Decent trip';
      reason = 'Average profitability, consider if positioning helps';
    } else {
      recommendation = '❌ SKIP - Low value';
      reason = 'Low earnings per minute, no surge active';
    }

    return '$recommendation\n$reason\n\n💰 Earnings: \$${trip.totalEarnings.toStringAsFixed(2)}\n⏱️ Time: ${trip.estimatedDuration.inMinutes} mins\n📍 Distance: ${trip.distance.toStringAsFixed(1)} miles';
  }

  void provideWellnessReminder() {
    _currentSuggestion = '☕ Wellness Check: You\'ve been driving for 3 hours. Time for a 15-minute break? Your reaction time may be slower when tired.';
    setState(MaskotState.suggesting);
    notifyListeners();

    Timer(const Duration(seconds: 10), () {
      setState(MaskotState.idle);
    });
  }

  void provideDemandPrediction() {
    final location = Constants.locations[_random.nextInt(Constants.locations.length)];
    final surge = (1.5 + _random.nextDouble() * 1.5).toStringAsFixed(1);

    _currentSuggestion = '🔥 High demand detected!\n📍 $location\n💰 ${surge}x surge active\n⏱️ 3-5 min wait time';
    setState(MaskotState.alerting);
    notifyListeners();

    Timer(const Duration(seconds: 10), () {
      setState(MaskotState.idle);
    });
  }

  void celebrateAchievement(String achievement) {
    setState(MaskotState.celebrating);
    _currentSuggestion = '🎉 Achievement Unlocked: $achievement!';
    notifyListeners();

    Timer(const Duration(seconds: 5), () {
      setState(MaskotState.idle);
    });
  }

  void _addMessage(ChatMessage message) {
    _messages.insert(0, message);
    if (_messages.length > 100) {
      _messages.removeLast();
    }
  }

  void clearMessages() {
    _messages.clear();
    _initializeMaskot();
    notifyListeners();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

enum MaskotState {
  idle,
  speaking,
  thinking,
  analyzing,
  alerting,
  suggesting,
  celebrating,
}