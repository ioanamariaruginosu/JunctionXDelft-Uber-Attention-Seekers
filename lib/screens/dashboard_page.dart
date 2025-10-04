import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../services/mock_data_service.dart';
import '../services/atlas_ai_service.dart';
import '../services/notification_service.dart';
import '../models/trip_model.dart';
import '../widgets/atlas_widget.dart';
import '../widgets/popup_system.dart';
import '../utils/theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _pulseController;
  late AnimationController _counterController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _counterAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _counterController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _counterAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().startAutoNotifications();
      _counterController.forward();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _counterController.dispose();
    context.read<NotificationService>().stopAutoNotifications();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final mockData = context.watch<MockDataService>();
    final atlasService = context.watch<AtlasAIService>();
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, authService),
      body: Stack(
        children: [
          _buildMapInterface(context, size, mockData),
          _buildTopBar(context, authService, mockData),
          if (mockData.currentTripRequest != null) _buildTripRequestCard(context, mockData, atlasService),
          if (mockData.activeTrip != null) _buildActiveTripCard(context, mockData),
          const AtlasWidget(),
          const PopupSystem(),
        ],
      ),
    );
  }

  Widget _buildMapInterface(BuildContext context, Size size, MockDataService mockData) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Google Maps style background
        CustomPaint(
          size: size,
          painter: GoogleMapsPainter(isDark: isDark),
        ),
        ..._buildDemandZones(size, mockData),
        _buildCurrentLocationMarker(size),
      ],
    );
  }

  List<Widget> _buildDemandZones(Size size, MockDataService mockData) {
    final random = math.Random(42);
    return mockData.demandZones.entries.map((entry) {
      final left = random.nextDouble() * (size.width - 100);
      final top = 100 + random.nextDouble() * (size.height - 300);
      final radius = 40.0 + entry.value * 20;

      Color color;
      if (entry.value > 2.0) {
        color = AppColors.demandHigh;
      } else if (entry.value > 1.5) {
        color = AppColors.demandMedium;
      } else {
        color = AppColors.demandLow;
      }

      return Positioned(
        left: left,
        top: top,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.2),
                  border: Border.all(
                    color: color.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  Widget _buildCurrentLocationMarker(Size size) {
    return Positioned(
      left: size.width / 2 - 15,
      top: size.height / 2 - 15,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 10 * _pulseAnimation.value,
                  spreadRadius: 5 * _pulseAnimation.value,
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation,
              color: Colors.white,
              size: 20,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AuthService authService, MockDataService mockData) {
    final theme = Theme.of(context);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.background.withOpacity(0.9),
              theme.colorScheme.background.withOpacity(0),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            AnimatedBuilder(
              animation: _counterAnimation,
              builder: (context, child) {
                final earnings = mockData.todayEarnings?.totalEarnings ?? 0;
                final displayEarnings = earnings * _counterAnimation.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money, color: AppColors.success),
                      Text(
                        displayEarnings.toStringAsFixed(2),
                        style: AppTextStyles.headline4.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Switch.adaptive(
              value: mockData.isOnline,
              onChanged: (value) {
                if (value) {
                  mockData.goOnline();
                } else {
                  mockData.goOffline();
                }
              },
              activeColor: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTripRequestCard(BuildContext context, MockDataService mockData, AtlasAIService atlasService) {
    final trip = mockData.currentTripRequest!;
    final theme = Theme.of(context);

    atlasService.analyzeTripRequest(trip);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 100,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'New Trip Request',
                    style: AppTextStyles.headline4,
                  ),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 15, end: 0),
                    duration: const Duration(seconds: 15),
                    builder: (context, value, child) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: value <= 5 ? AppColors.error : AppColors.warning,
                        ),
                        child: Text(
                          '$value',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.trip_origin, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.pickupLocation,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.dropoffLocation,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTripDetail(Icons.attach_money, '\\\$${trip.totalEarnings.toStringAsFixed(2)}'),
                  _buildTripDetail(Icons.straighten, '${trip.distance.toStringAsFixed(1)} mi'),
                  _buildTripDetail(Icons.schedule, '${trip.estimatedDuration.inMinutes} min'),
                  if (trip.surge > 1.0) _buildTripDetail(Icons.bolt, '${trip.surge.toStringAsFixed(1)}x'),
                ],
              ),
              if (atlasService.currentSuggestion != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.atlasGlow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.atlasGlow),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assistant, color: AppColors.atlasGlow),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          atlasService.currentSuggestion!.split('\n').first,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => mockData.declineTrip(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => mockData.acceptTrip(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripDetail(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTripCard(BuildContext context, MockDataService mockData) {
    final trip = mockData.activeTrip!;
    final theme = Theme.of(context);

    String statusText = '';
    IconData statusIcon = Icons.info;
    Color statusColor = AppColors.info;

    switch (trip.status) {
      case TripStatus.accepted:
        statusText = 'Heading to pickup';
        statusIcon = Icons.directions_car;
        statusColor = AppColors.info;
        break;
      case TripStatus.driverArrived:
        statusText = 'Arrived at pickup';
        statusIcon = Icons.location_on;
        statusColor = AppColors.warning;
        break;
      case TripStatus.inProgress:
        statusText = 'Trip in progress';
        statusIcon = Icons.navigation;
        statusColor = AppColors.success;
        break;
      default:
        break;
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 100,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        color: statusColor,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(statusIcon, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                statusText,
                style: AppTextStyles.headline4.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                trip.dropoffLocation,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthService authService) {
    final theme = Theme.of(context);
    final user = authService.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.surface,
                  child: Text(
                    user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      fontSize: 24,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'User',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile & Stats'),
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await authService.logout();
              if (context.mounted) {
                context.go('/auth');
              }
            },
          ),
        ],
      ),
    );
  }
}

class GoogleMapsPainter extends CustomPainter {
  final bool isDark;

  GoogleMapsPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Background color like Google Maps
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F3F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw city blocks
    _drawCityBlocks(canvas, size);

    // Draw major roads
    _drawRoads(canvas, size);

    // Draw buildings/landmarks
    _drawBuildings(canvas, size);

    // Draw parks
    _drawParks(canvas, size);

    // Draw water features
    _drawWater(canvas, size);
  }

  void _drawCityBlocks(Canvas canvas, Size size) {
    final blockPaint = Paint()
      ..color = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8EAED)
      ..style = PaintingStyle.fill;

    // Create grid of city blocks
    const blockSize = 80.0;
    const streetWidth = 15.0;

    for (double x = 0; x < size.width; x += blockSize + streetWidth) {
      for (double y = 0; y < size.height; y += blockSize + streetWidth) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, blockSize, blockSize),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, blockPaint);
      }
    }
  }

  void _drawRoads(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF3A3A3A) : Colors.white
      ..style = PaintingStyle.fill;

    final roadStrokePaint = Paint()
      ..color = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFDADCE0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Horizontal roads
    for (double y = 40; y < size.height; y += 95) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 15),
        roadPaint,
      );
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        roadStrokePaint,
      );
      canvas.drawLine(
        Offset(0, y + 15),
        Offset(size.width, y + 15),
        roadStrokePaint,
      );
    }

    // Vertical roads
    for (double x = 40; x < size.width; x += 95) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 15, size.height),
        roadPaint,
      );
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        roadStrokePaint,
      );
      canvas.drawLine(
        Offset(x + 15, 0),
        Offset(x + 15, size.height),
        roadStrokePaint,
      );
    }

    // Draw road markings (dashed center lines)
    final dashPaint = Paint()
      ..color = isDark ? const Color(0xFF5A5A5A) : const Color(0xFFBDBDBD)
      ..strokeWidth = 2;

    for (double y = 47.5; y < size.height; y += 95) {
      for (double x = 0; x < size.width; x += 20) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x + 10, y),
          dashPaint,
        );
      }
    }

    for (double x = 47.5; x < size.width; x += 95) {
      for (double y = 0; y < size.height; y += 20) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + 10),
          dashPaint,
        );
      }
    }
  }

  void _drawBuildings(Canvas canvas, Size size) {
    final buildingPaint = Paint()
      ..color = isDark ? const Color(0xFF3F3F3F) : const Color(0xFFDADCE0)
      ..style = PaintingStyle.fill;

    final importantBuildingPaint = Paint()
      ..color = isDark ? const Color(0xFF4A5F7F) : const Color(0xFFD1C4B9)
      ..style = PaintingStyle.fill;

    // Some important buildings (like shopping centers, hospitals)
    final buildings = [
      Rect.fromLTWH(60, 60, 60, 60),
      Rect.fromLTWH(200, 100, 50, 70),
      Rect.fromLTWH(300, 250, 70, 50),
      Rect.fromLTWH(150, 350, 60, 60),
      Rect.fromLTWH(400, 150, 55, 55),
    ];

    for (final building in buildings) {
      if (building.width * building.height > 3000) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(building, const Radius.circular(2)),
          importantBuildingPaint,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(building, const Radius.circular(2)),
          buildingPaint,
        );
      }
    }
  }

  void _drawParks(Canvas canvas, Size size) {
    final parkPaint = Paint()
      ..color = isDark
        ? const Color(0xFF2D4A2B).withOpacity(0.7)
        : const Color(0xFFC8E6C9).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Draw some parks
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(250, 60, 70, 60),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(60, 200, 60, 80),
        const Radius.circular(8),
      ),
      parkPaint,
    );
  }

  void _drawWater(Canvas canvas, Size size) {
    final waterPaint = Paint()
      ..color = isDark
        ? const Color(0xFF1E3A5F).withOpacity(0.6)
        : const Color(0xFFB3E5FC).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw a river or water feature
    final path = Path();
    path.moveTo(size.width * 0.7, 0);
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.3,
      size.width * 0.8, size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.85, size.height * 0.8,
      size.width * 0.9, size.height,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, waterPaint);
  }

  @override
  bool shouldRepaint(GoogleMapsPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}