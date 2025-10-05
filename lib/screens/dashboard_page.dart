import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/mock_data_service.dart';
import '../services/maskot_ai_service.dart';
import '../services/notification_service.dart';
import '../models/trip_model.dart';
import '../utils/maskot_speech_bubble.dart';
import '../widgets/mascot_widget.dart';
import '../widgets/map_widget.dart';
import '../widgets/popup_system.dart';
import '../utils/theme.dart';
import '../widgets/slide_to_go_online.dart';
import '../widgets/weather_widget.dart';
import 'package:uber_copilot/widgets/map_widget.dart' as map_widget;
import 'package:uber_copilot/widgets/weather_widget.dart' as weather_widget;
import '../widgets/map_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _pulseController;
  late AnimationController _counterController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _counterAnimation;
  

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _counterController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _counterAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _counterController, curve: Curves.easeOut),
    );

    // Initialize backend-powered session state (no local timers, no auto-start)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      final userId = auth.currentUser?.id ?? 'demo';

      context.read<NotificationService>().initRestTimer(
        userId: userId,
        demoMode: false,           // no frontend minute ticking
        demoSecondsPerMinute: 1,   // ignored when demoMode=false
      );

      _counterController.forward();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _counterController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      final session = context.read<NotificationService>();
      if (session.activeSession) {
        context.read<NotificationService>().stopRestSession();
        context.read<MockDataService>().goOffline();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final mockData = context.watch<MockDataService>();
    final maskotService = context.watch<MaskotAIService>();
    final session = context.watch<NotificationService>();

    double mascotSize = MediaQuery.of(context).size.width * 0.15;
    double mascotBottom = 100;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, authService),
      body: Stack(
        children: [
          _buildMapInterface(),
          _buildTopBar(context, authService, mockData),
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 0,
            right: 0,
            child: PhoneDemandCard(
              userType: 'food',               // or from user settings
              cityId: 4,                      // your driver’s city
              at: DateTime.now(),             // optional; defaults to now()
              //at: DateTime.parse("2023-01-16T19:00:00Z")
            ),
          ),
          if (mockData.currentTripRequest != null) _buildTripRequestCard(context, mockData, maskotService, session),
          if (mockData.activeTrip != null) _buildActiveTripCard(context, mockData),
          const MascotWidget(),
          PopupSystem(mascotSize: mascotSize, mascotBottom: mascotBottom),

          // Bottom online/offline slider wired ONLY to backend state
          SlideToGoOnline(
            isOnline: session.activeSession, // starts false unless server says active
            onChanged: (goOnline) async {
              if (goOnline) {
                await context.read<NotificationService>().startRestSession();  // POST /hours/start
                context.read<MockDataService>().goOnline(); // ADD THIS
              } else {
                await context.read<NotificationService>().stopRestSession();   // POST /hours/stop
                context.read<MockDataService>().goOffline();
              }
              // UI derives from session.activeSession
            },
          ),
          // Positioned(
          //   top: 50,
          //   left: 20,
          //   child: WeatherWidget()
          // ),
        ],
      ),
    );
  }

  Widget _buildMapInterface() {
    return RealMapWidget();
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
            Positioned(
              left: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF1F1F1F)
                      : Colors.white,
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
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _counterAnimation,
                builder: (context, child) {
                  // rest of your code
                  final earnings = mockData.todayEarnings?.totalEarnings ?? 0;
                  final displayEarnings = earnings * _counterAnimation.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
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

            // Centered earnings and weather
            Center(
              child: Column(
                children: [
                  // Earnings
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
                  const SizedBox(height: 8),
                  WeatherWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripRequestCard(BuildContext context, MockDataService mockData, MaskotAIService maskotService, NotificationService session) {
    final trip = mockData.currentTripRequest!;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 100,
      left: 16,
      right: 16,
      bottom: session.activeSession ? 100 : 160, // use backend state
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
                    _buildTripDetail(Icons.attach_money, '\$${trip.totalEarnings.toStringAsFixed(2)}'),
                    _buildTripDetail(Icons.straighten, '${trip.distance.toStringAsFixed(1)} mi'),
                    _buildTripDetail(Icons.schedule, '${trip.estimatedDuration.inMinutes} min'),
                    if (trip.surge > 1.0) _buildTripDetail(Icons.bolt, '${trip.surge.toStringAsFixed(1)}x'),
                  ],
                ),
                const SizedBox(height: 16),

                MaskotSpeechBubble(trip: trip, maskotService: maskotService),

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
                        onPressed: () {
                          mockData.acceptTrip();
                          // NEW: accepting a new trip clears rest pins
                          context.read<NotificationService>().hideRestPinsAndReset();
                        },
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
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
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
              Text(statusText, style: AppTextStyles.headline4.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              Text(trip.dropoffLocation, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
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
      child: Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F1F1F)
            : Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    child: Text(
                      user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'User',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.7)
                          : Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.dashboard,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(
                Icons.person,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              title: const Text('Profile & Stats'),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
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
      ),
    );
  }
}

