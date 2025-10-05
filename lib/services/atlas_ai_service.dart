import 'package:flutter/material.dart';

/// Minimal stub for AtlasAIService used by the UI.
/// The real implementation can provide suggestions/insights; this stub keeps
/// the app compiling and provides a couple of no-op methods used in widgets.
class AtlasAIService extends ChangeNotifier {
  bool get isReady => true;

  String summarizeTrip(String tripId) {
    return 'Quick summary for trip $tripId';
  }

  // Example: return a short hint for a trip request
  String hintForRequest() => 'This area usually has short trips.';
}
