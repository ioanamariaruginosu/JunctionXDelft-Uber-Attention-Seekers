import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'mock_data_service.dart';

class DemandZoneSnapshot {
  final double score;
  final String level;
  final String action;

  DemandZoneSnapshot({required this.score, required this.level, required this.action});
}

class DemandResponse {
  final DateTime generatedAt;
  DemandResponse(this.generatedAt);
}

class DemandService extends ChangeNotifier {
  final MockDataService _mock;

  DemandService(this._mock) {
    // auto-refresh when mock data updates
    _mock.addListener(() => refresh());
    refresh();
  }

  bool isLoading = false;
  String? error;
  DemandResponse? current;

  DemandZoneSnapshot? currentZoneDemand;
  DemandZoneSnapshot? nextZoneDemand;

  String zone = 'A';

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // build 3 simple zones (A,B,C) from mock demand zones
      final entries = _mock.demandZones.entries.toList();
      entries.sort((a, b) => b.value.compareTo(a.value));

      double aScore = entries.isNotEmpty ? entries[0].value : 1.0;
      double bScore = entries.length > 1 ? entries[1].value : aScore * 0.8;
      double cScore = entries.length > 2 ? entries[2].value : aScore * 0.6;

      currentZoneDemand = DemandZoneSnapshot(score: aScore, level: _toLevel(aScore), action: _recommend(aScore));
      nextZoneDemand = DemandZoneSnapshot(score: aScore * 0.95, level: _toLevel(aScore * 0.95), action: _recommend(aScore * 0.95));

      current = DemandResponse(DateTime.now());
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  String _toLevel(double score) {
    if (score >= 2.0) return 'high';
    if (score >= 1.5) return 'med';
    return 'low';
  }

  String _recommend(double score) {
    if (score >= 2.0) return 'Go now';
    if (score >= 1.5) return 'Stay ready';
    return 'Rest';
  }
}
