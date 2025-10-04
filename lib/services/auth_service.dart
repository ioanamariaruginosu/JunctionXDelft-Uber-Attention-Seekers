import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    await Future.delayed(const Duration(seconds: 2));

    if (email.isNotEmpty && password.isNotEmpty) {
      _currentUser = UserModel(
        id: const Uuid().v4(),
        fullName: 'Demo User',
        email: email,
        phoneNumber: '+1234567890',
        vehicleType: VehicleType.car,
        licenseNumber: 'DL123456',
        rating: 4.9,
        totalTrips: 342,
        totalEarnings: 8456.50,
        joinedDate: DateTime.now().subtract(const Duration(days: 180)),
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _error = 'Invalid email or password';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required VehicleType vehicleType,
    required String licenseNumber,
  }) async {
    _setLoading(true);
    _error = null;

    await Future.delayed(const Duration(seconds: 2));

    _currentUser = UserModel(
      id: const Uuid().v4(),
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      vehicleType: vehicleType,
      licenseNumber: licenseNumber,
      rating: 5.0,
      totalTrips: 0,
      totalEarnings: 0.0,
      joinedDate: DateTime.now(),
    );

    _setLoading(false);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _setLoading(true);
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _error = null;
    _setLoading(false);
    notifyListeners();
  }

  void updateOnlineStatus(bool isOnline) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(isOnline: isOnline);
      notifyListeners();
    }
  }

  void updateUserPreferences(Map<String, dynamic> preferences) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(preferences: preferences);
      notifyListeners();
    }
  }

  void updateEarnings(double amount) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        totalEarnings: _currentUser!.totalEarnings + amount,
        totalTrips: _currentUser!.totalTrips + 1,
      );
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}