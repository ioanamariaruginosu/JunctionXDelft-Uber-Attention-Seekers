import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../services/mock_data_service.dart';
import '../services/auth_service.dart';
import '../services/maskot_ai_service.dart';
import '../utils/theme.dart';
import '../models/earnings_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _showStats = false;
  bool _maskotEnabled = true;

  @override
  Widget build(BuildContext context) {
    final mockData = context.watch<MockDataService>();
    final authService = context.watch<AuthService>();
    final maskotService = context.watch<MaskotAIService>();
    final theme = Theme.of(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontSize: 32,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Demo User',
                            style: AppTextStyles.headline4,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'demo@uber.com',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, color: AppColors.warning, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${user?.rating ?? 4.9}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.directions_car, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${user?.totalTrips ?? 342} trips',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Stats Summary
            _buildSummaryCards(mockData.todayEarnings),
            const SizedBox(height: 20),

            // AI Assistant Toggle
            Card(
              child: SwitchListTile(
                title: Text(
                  'Maskot AI Assistant',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text('Show helpful tips and earnings insights'),
                value: _maskotEnabled,
                onChanged: (value) {
                  setState(() {
                    _maskotEnabled = value;
                    maskotService.setEnabled(value);
                  });
                },
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _maskotEnabled ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_emotions,
                    color: _maskotEnabled ? Colors.amber : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Statistics Toggle
            Card(
              child: ListTile(
                title: Text(
                  'Detailed Statistics',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(_showStats ? 'Hide charts and analytics' : 'Show charts and analytics'),
                trailing: Icon(
                  _showStats ? Icons.expand_less : Icons.expand_more,
                  size: 28,
                ),
                onTap: () {
                  setState(() {
                    _showStats = !_showStats;
                  });
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),

            // Expandable Statistics Section
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildEarningsChart(mockData.todayEarnings),
                  const SizedBox(height: 20),
                  _buildEarningsBreakdown(mockData.todayEarnings),
                  const SizedBox(height: 20),
                  _buildHourlyEarningsChart(mockData.todayEarnings),
                  const SizedBox(height: 20),
                  _buildGoalsSection(mockData.todayEarnings),
                  const SizedBox(height: 20),
                  _buildRecentTrips(mockData),
                ],
              ),
              crossFadeState: _showStats ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(EarningsModel? earnings) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Today\'s Earnings',
            '\$${earnings?.totalEarnings.toStringAsFixed(2) ?? '0.00'}',
            Icons.attach_money,
            AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Trips Today',
            '${earnings?.tripsCompleted ?? 0}',
            Icons.directions_car,
            AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Per Hour',
            '\$${earnings?.earningsPerHour.toStringAsFixed(1) ?? '0.0'}',
            Icons.trending_up,
            AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsChart(EarningsModel? earnings) {
    if (earnings == null) return const SizedBox.shrink();

    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Breakdown',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: earnings.baseFare > 0 ? earnings.baseFare : 1,
                      title: 'Base',
                      color: AppColors.info,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: earnings.tips > 0 ? earnings.tips : 1,
                      title: 'Tips',
                      color: AppColors.success,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: earnings.bonuses > 0 ? earnings.bonuses : 1,
                      title: 'Bonus',
                      color: AppColors.warning,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: earnings.surgeEarnings > 0 ? earnings.surgeEarnings : 1,
                      title: 'Surge',
                      color: AppColors.error,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdown(EarningsModel? earnings) {
    if (earnings == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Breakdown',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBreakdownRow('Base Fare', earnings.baseFare, AppColors.info),
            _buildBreakdownRow('Tips', earnings.tips, AppColors.success),
            _buildBreakdownRow('Bonuses', earnings.bonuses, AppColors.warning),
            _buildBreakdownRow('Surge', earnings.surgeEarnings, AppColors.error),
            const Divider(height: 24),
            _buildBreakdownRow('Total', earnings.totalEarnings, Theme.of(context).colorScheme.primary, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: isTotal
                    ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
                    : AppTextStyles.bodyMedium,
              ),
            ],
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: isTotal
                ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)
                : AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyEarningsChart(EarningsModel? earnings) {
    if (earnings == null) return const SizedBox.shrink();

    final hourlyData = earnings.hourlyEarnings.entries.toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

    if (hourlyData.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hourly Earnings',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: hourlyData.isEmpty ? 100 : hourlyData.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < hourlyData.length) {
                            return Text(
                              '${hourlyData[value.toInt()].key}:00',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: hourlyData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value,
                          color: AppColors.success,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSection(EarningsModel? earnings) {
    final dailyGoal = 150.0;
    final weeklyGoal = 1000.0;
    final dailyProgress = (earnings?.totalEarnings ?? 0) / dailyGoal;
    final weeklyProgress = 0.65;

    return Column(
      children: [
        _buildGoalCard(
          'Daily Goal',
          earnings?.totalEarnings ?? 0,
          dailyGoal,
          dailyProgress,
          AppColors.info,
        ),
        const SizedBox(height: 16),
        _buildGoalCard(
          'Weekly Goal',
          650.0,
          weeklyGoal,
          weeklyProgress,
          AppColors.success,
        ),
      ],
    );
  }

  Widget _buildGoalCard(String title, double current, double target, double progress, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${current.toStringAsFixed(2)} / \$${target.toStringAsFixed(2)}',
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTrips(MockDataService mockData) {
    final trips = mockData.tripHistory.take(5).toList();

    if (trips.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.directions_car, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'No trips yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Trips',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...trips.map((trip) => Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.trip_origin, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.pickupLocation}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '→ ${trip.dropoffLocation}',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${trip.totalEarnings.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}