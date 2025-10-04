import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _soundEffects = false;
  bool _vibration = true;
  bool _autoBreaks = true;
  bool _voiceAlerts = false;
  int _breakInterval = 3;
  String _atlasPersonality = 'balanced';
  double _dailyGoal = 150.0;
  double _weeklyGoal = 1000.0;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Profile',
            [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    authService.currentUser?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(color: theme.colorScheme.onPrimary),
                  ),
                ),
                title: Text(authService.currentUser?.fullName ?? 'User'),
                subtitle: Text(authService.currentUser?.email ?? ''),
                trailing: const Icon(Icons.edit),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Appearance',
            [
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                subtitle: Text(
                  themeProvider.themeMode == ThemeMode.system
                      ? 'System'
                      : themeProvider.themeMode == ThemeMode.dark
                          ? 'On'
                          : 'Off',
                ),
                trailing: PopupMenuButton<ThemeMode>(
                  onSelected: (mode) => themeProvider.setThemeMode(mode),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    const PopupMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    const PopupMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          themeProvider.themeMode == ThemeMode.system
                              ? 'System'
                              : themeProvider.themeMode == ThemeMode.dark
                                  ? 'Dark'
                                  : 'Light',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Notifications',
            [
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive alerts for trips and bonuses'),
                value: _notifications,
                onChanged: (value) => setState(() => _notifications = value),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up),
                title: const Text('Sound Effects'),
                subtitle: const Text('Play sounds for notifications'),
                value: _soundEffects,
                onChanged: _notifications ? (value) => setState(() => _soundEffects = value) : null,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate for important alerts'),
                value: _vibration,
                onChanged: _notifications ? (value) => setState(() => _vibration = value) : null,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.record_voice_over),
                title: const Text('Voice Alerts'),
                subtitle: const Text('Atlas speaks important updates'),
                value: _voiceAlerts,
                onChanged: (value) => setState(() => _voiceAlerts = value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Atlas AI Settings',
            [
              ListTile(
                leading: const Icon(Icons.assistant),
                title: const Text('Atlas Personality'),
                subtitle: Text('Current: ${_atlasPersonality.substring(0, 1).toUpperCase()}${_atlasPersonality.substring(1)}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => setState(() => _atlasPersonality = value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'aggressive',
                      child: ListTile(
                        title: Text('Aggressive'),
                        subtitle: Text('Maximum earnings focus'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'balanced',
                      child: ListTile(
                        title: Text('Balanced'),
                        subtitle: Text('Mix of earnings and wellness'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'relaxed',
                      child: ListTile(
                        title: Text('Relaxed'),
                        subtitle: Text('Focus on driver wellness'),
                        dense: true,
                      ),
                    ),
                  ],
                  child: const Icon(Icons.arrow_forward_ios),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.free_breakfast),
                title: const Text('Auto Break Reminders'),
                subtitle: Text('Suggest breaks every $_breakInterval hours'),
                value: _autoBreaks,
                onChanged: (value) => setState(() => _autoBreaks = value),
              ),
              if (_autoBreaks)
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Break Interval'),
                  subtitle: Text('$_breakInterval hours'),
                  trailing: SizedBox(
                    width: 150,
                    child: Slider(
                      value: _breakInterval.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      label: '$_breakInterval hours',
                      onChanged: (value) => setState(() => _breakInterval = value.round()),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Goals',
            [
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Daily Earnings Goal'),
                subtitle: Text('\$${_dailyGoal.toStringAsFixed(0)}'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: _dailyGoal,
                    min: 50,
                    max: 500,
                    divisions: 45,
                    label: '\$${_dailyGoal.toStringAsFixed(0)}',
                    onChanged: (value) => setState(() => _dailyGoal = value),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('Weekly Earnings Goal'),
                subtitle: Text('\$${_weeklyGoal.toStringAsFixed(0)}'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: _weeklyGoal,
                    min: 500,
                    max: 3000,
                    divisions: 25,
                    label: '\$${_weeklyGoal.toStringAsFixed(0)}',
                    onChanged: (value) => setState(() => _weeklyGoal = value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            'About',
            [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                context.go('/auth');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}