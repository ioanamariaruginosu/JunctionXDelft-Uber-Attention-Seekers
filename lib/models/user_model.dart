class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final VehicleType vehicleType;
  final String licenseNumber;
  final double rating;
  final int totalTrips;
  final double totalEarnings;
  final DateTime joinedDate;
  final bool isOnline;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.vehicleType,
    required this.licenseNumber,
    this.rating = 5.0,
    this.totalTrips = 0,
    this.totalEarnings = 0.0,
    DateTime? joinedDate,
    this.isOnline = false,
    Map<String, dynamic>? preferences,
  })  : joinedDate = joinedDate ?? DateTime.now(),
        preferences = preferences ?? {};

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    VehicleType? vehicleType,
    String? licenseNumber,
    double? rating,
    int? totalTrips,
    double? totalEarnings,
    DateTime? joinedDate,
    bool? isOnline,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      joinedDate: joinedDate ?? this.joinedDate,
      isOnline: isOnline ?? this.isOnline,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'vehicleType': vehicleType.toString().split('.').last,
      'licenseNumber': licenseNumber,
      'rating': rating,
      'totalTrips': totalTrips,
      'totalEarnings': totalEarnings,
      'joinedDate': joinedDate.toIso8601String(),
      'isOnline': isOnline,
      'preferences': preferences,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.toString().split('.').last == json['vehicleType'],
        orElse: () => VehicleType.car,
      ),
      licenseNumber: json['licenseNumber'],
      rating: (json['rating'] ?? 5.0).toDouble(),
      totalTrips: json['totalTrips'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      joinedDate: DateTime.parse(json['joinedDate']),
      isOnline: json['isOnline'] ?? false,
      preferences: json['preferences'] ?? {},
    );
  }
}

enum VehicleType { car, motorcycle, bicycle, scooter, suv, bike }