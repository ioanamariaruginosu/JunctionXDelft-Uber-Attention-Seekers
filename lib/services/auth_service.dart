import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/api_client.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

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

    final response = await ApiClient.post(
      '/auth/register',
      body: {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'vehicleType': vehicleType.toString().split('.').last,
        'licenseNumber': licenseNumber,
      },
    );

    if (response.success) {
      final data = response.dataAsMap!;
      _currentUser = UserModel(
        id: data['id'],
        fullName: data['fullName'],
        email: data['email'],
        phoneNumber: data['phoneNumber'],
        vehicleType: _parseVehicleType(data['vehicleType']),
        licenseNumber: data['licenseNumber'],
        rating: data['rating'].toDouble(),
        totalTrips: data['totalTrips'],
        totalEarnings: data['totalEarnings'].toDouble(),
        joinedDate: DateTime.parse(data['joinedDate']),
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _error = response.message ?? 'Registration failed';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    final response = await ApiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.success) {
      final data = response.dataAsMap!;
      _currentUser = UserModel(
        id: data['id'],
        fullName: data['fullName'],
        email: data['email'],
        phoneNumber: data['phoneNumber'],
        vehicleType: _parseVehicleType(data['vehicleType']),
        licenseNumber: data['licenseNumber'],
        rating: data['rating'].toDouble(),
        totalTrips: data['totalTrips'],
        totalEarnings: data['totalEarnings'].toDouble(),
        joinedDate: DateTime.parse(data['joinedDate']),
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } else {
      _error = response.message ?? 'Login failed';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  VehicleType _parseVehicleType(String type) {
    switch (type.toLowerCase()) {
      case 'car':
        return VehicleType.car;
      case 'suv':
        return VehicleType.suv;
      case 'bike':
        return VehicleType.bike;
      default:
        return VehicleType.car;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
}