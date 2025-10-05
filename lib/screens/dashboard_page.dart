import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../services/mock_data_service.dart';
import '../services/demand_service.dart';
import '../services/maskot_ai_service.dart';
import '../services/notification_service.dart';
import '../models/trip_model.dart';
import '../widgets/mascot_widget.dart';
import '../widgets/map_widget.dart';
import '../widgets/popup_system.dart';
import '../utils/theme.dart';
import '../widgets/slide_to_go_online.dart';

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
      context.read<DemandService>().refresh();
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
  final maskotService = context.watch<MaskotAIService>();
    final demandService = context.watch<DemandService>();
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, authService),
      body: Stack(
        children: [
          _buildMapInterface(),
          _buildTopBar(context, authService, mockData),
          if (mockData.currentTripRequest == null && mockData.activeTrip == null)
            _buildDemandCard(context, demandService),
          if (mockData.currentTripRequest != null) _buildTripRequestCard(context, mockData, maskotService),
          if (mockData.activeTrip != null) _buildActiveTripCard(context, mockData),
          const MascotWidget(), // change icon

          // Add the slide to go online widget
          SlideToGoOnline(
            isOnline: mockData.isOnline,
            onChanged: (value) {
              if (value) {
                mockData.goOnline();
              } else {
                mockData.goOffline();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDemandCard(BuildContext context, DemandService demandService) {
    final theme = Theme.of(context);
    final DemandZoneSnapshot? now = demandService.currentZoneDemand;
    final DemandZoneSnapshot? next = demandService.nextZoneDemand;
    final bool isLoading = demandService.isLoading;
    final String? error = demandService.error;
    final DateTime? updatedAt = demandService.current?.generatedAt;
    final List<String> zoneOptions = <String>['A', 'B', 'C'];

    final String? updatedLabel =
        updatedAt != null ? DateFormat('HH:mm').format(updatedAt) : null;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 88,
      left: 16,
      right: 16,
      child: Card(
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Demand summary',
                    style: AppTextStyles.headline4,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: isLoading ? null : () => demandService.refresh(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Zone',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: demandService.zone,
                      items: zoneOptions
                          .map((zone) => DropdownMenuItem<String>(
                                value: zone,
                                child: Text('Zone ' + zone),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          demandService.zone = value;
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const Center(
                  child: SizedBox(
                    height: 32,
                    width: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                )
              else if (error != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unable to load demand right now.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDemandTile(
                            context,
                            'Now',
                            now,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDemandTile(
                            context,
                            'Next 2h',
                            next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _nextTwoHoursMessage(next),
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (updatedLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Updated at ' + updatedLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
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

  Widget _buildDemandTile(
    BuildContext context,
    String label,
    DemandZoneSnapshot? snapshot,
  ) {
    final theme = Theme.of(context);
    final bool hasData = snapshot != null;
    final String levelText =
        hasData ? _formatLevel(snapshot!.level) : 'No data';
    final Color levelColor =
        _levelColor(hasData ? snapshot!.level : null, theme);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: levelColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            levelText,
            style: AppTextStyles.headline4.copyWith(color: levelColor),
          ),
          if (hasData)
            Text(
              'Score ' + snapshot!.score.toStringAsFixed(2),
              style: AppTextStyles.caption.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }

  String _nextTwoHoursMessage(DemandZoneSnapshot? snapshot) {
    if (snapshot == null) {
      return 'No forecast available for the next 2 hours.';
    }
    final String action = snapshot.action.trim();
    if (action.isEmpty) {
      return 'Stay flexible over the next 2 hours.';
    }
    final String sentence =
        action.substring(0, 1).toUpperCase() + action.substring(1);
    if (sentence.endsWith('.')) {
      return 'Next 2h tip: ' + sentence;
    }
    return 'Next 2h tip: ' + sentence + '.';
  }

  String _formatLevel(String? level) {
    final String value = (level ?? '').toLowerCase();
    if (value == 'high') {
      return 'High';
    }
  if (value == 'med' || value == 'medium') {
      return 'Medium';
    }
    if (value == 'low') {
      return 'Low';
    }
    if (value.isEmpty) {
      return 'No data';
    }
    return value.substring(0, 1).toUpperCase() + value.substring(1);
  }

  Color _levelColor(String? level, ThemeData theme) {
    final String value = (level ?? '').toLowerCase();
    if (value == 'high') {
      return AppColors.demandHigh;
    }
  if (value == 'med' || value == 'medium') {
      return AppColors.demandMedium;
    }
    if (value == 'low') {
      return AppColors.demandLow;
    }
    return theme.colorScheme.primary;
  }


  Widget _buildMapInterface() {
    return const RealMapWidget();
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
        child: Stack(
          children: [
            // Menu button on the left
            Positioned(
              left: 0,
              child: Positioned(
                left: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu),
                    color: theme.colorScheme.primary,
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ),
              ),
            ),

            // Centered earnings
            Center(
              child: AnimatedBuilder(
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
                      mainAxisSize: MainAxisSize.min,
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
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTripRequestCard(BuildContext context, MockDataService mockData, MaskotAIService maskotService) {
    final trip = mockData.currentTripRequest!;
    final theme = Theme.of(context);

    // Kick off analysis (async) to populate maskotService.currentSuggestion
    maskotService.analyzeTripRequest(trip);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 100,
      left: 16,
      right: 16,
      bottom: mockData.isOnline ? 100 : 160,
      child: SingleChildScrollView(
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
                  if (maskotService.currentSuggestion != null) ...[
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
                              maskotService.currentSuggestion!.split('\n').first,
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
