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
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : Colors.black;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text('Settings', style: TextStyle(color: primaryColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
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
                  backgroundColor: primaryColor,
                  child: Text(
                    authService.currentUser?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(color: isDark ? Colors.black : Colors.white),
                  ),
                ),
                title: Text(
                  authService.currentUser?.fullName ?? 'User',
                  style: TextStyle(color: primaryColor),
                ),
                subtitle: Text(
                  authService.currentUser?.email ?? '',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                trailing: Icon(Icons.edit, color: primaryColor),
                onTap: () {},
              ),
            ],
            isDark,
            primaryColor,
            cardColor,
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Appearance',
            [
              ListTile(
                leading: Icon(Icons.dark_mode, color: primaryColor),
                title: Text('Dark Mode', style: TextStyle(color: primaryColor)),
                subtitle: Text(
                  themeProvider.themeMode == ThemeMode.system
                      ? 'System'
                      : themeProvider.themeMode == ThemeMode.dark
                      ? 'On'
                      : 'Off',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                trailing: PopupMenuButton<ThemeMode>(
                  onSelected: (mode) => themeProvider.setThemeMode(mode),
                  color: cardColor,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: ThemeMode.system,
                      child: Text('System', style: TextStyle(color: primaryColor)),
                    ),
                    PopupMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light', style: TextStyle(color: primaryColor)),
                    ),
                    PopupMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark', style: TextStyle(color: primaryColor)),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
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
                          style: AppTextStyles.bodyMedium.copyWith(color: primaryColor),
                        ),
                        Icon(Icons.arrow_drop_down, color: primaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            isDark,
            primaryColor,
            cardColor,
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Notifications',
            [
              SwitchListTile(
                secondary: Icon(Icons.notifications, color: primaryColor),
                title: Text('Push Notifications', style: TextStyle(color: primaryColor)),
                subtitle: Text(
                  'Receive alerts for trips and bonuses',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                value: _notifications,
                activeColor: primaryColor,
                onChanged: (value) => setState(() => _notifications = value),
              ),
              SwitchListTile(
                secondary: Icon(Icons.volume_up, color: primaryColor),
                title: Text('Sound Effects', style: TextStyle(color: primaryColor)),
                subtitle: Text(
                  'Play sounds for notifications',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                value: _soundEffects,
                activeColor: primaryColor,
                onChanged: _notifications ? (value) => setState(() => _soundEffects = value) : null,
              ),
              SwitchListTile(
                secondary: Icon(Icons.vibration, color: primaryColor),
                title: Text('Vibration', style: TextStyle(color: primaryColor)),
                subtitle: Text(
                  'Vibrate for important alerts',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                value: _vibration,
                activeColor: primaryColor,
                onChanged: _notifications ? (value) => setState(() => _vibration = value) : null,
              ),
              SwitchListTile(
                secondary: Icon(Icons.record_voice_over, color: primaryColor),
                title: Text('Voice Alerts', style: TextStyle(color: primaryColor)),
                subtitle: Text(
                  'Atlas speaks important updates',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                value: _voiceAlerts,
                activeColor: primaryColor,
                onChanged: (value) => setState(() => _voiceAlerts = value),
              ),
            ],
            isDark,
            primaryColor,
            cardColor,
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Atlas AI Settings',
            [
              ListTile(
                leading: Icon(Icons.assistant, color: primaryColor),
                title: Text('Atlas Personality', style: TextStyle(color: primaryColor)),
                subtitle: Text(
                  'Current: ${_atlasPersonality.substring(0, 1).toUpperCase()}${_atlasPersonality.substring(1)}',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => setState(() => _atlasPersonality = value),
                  color: cardColor,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'aggressive',
                      child: ListTile(
                        title: Text('Aggressive', style: TextStyle(color: primaryColor)),
                        subtitle: Text(
                          'Maximum earnings focus',
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'balanced',
                      child: ListTile(
                        title: Text('Balanced', style: TextStyle(color: primaryColor)),
                        subtitle: Text(
                          'Mix of earnings and wellness',
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'relaxed',
                      child: ListTile(
                        title: Text('Relaxed', style: TextStyle(color: primaryColor)),
                        subtitle: Text(
                          'Focus on driver wellness',
                          style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        ),
                        dense: true,
                      ),
                    ),
                  ],
                  child: Icon(Icons.arrow_forward_ios, color: primaryColor),
                ),
              ),
              SwitchListTile(
                secondary: Icon(Icons.free_breakfast, color: primaryColor),
                title: Text('Auto Break Reminders', style: TextStyle(color: primaryColor)),
                subtitle: Text(
                  'Suggest breaks every $_breakInterval hours',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                value: _autoBreaks,
                activeColor: primaryColor,
                onChanged: (value) => setState(() => _autoBreaks = value),
              ),
              if (_autoBreaks)
                ListTile(
                  leading: Icon(Icons.timer, color: primaryColor),
                  title: Text('Break Interval', style: TextStyle(color: primaryColor)),
                  subtitle: Text(
                    '$_breakInterval hours',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  trailing: SizedBox(
                    width: 150,
                    child: Slider(
                      value: _breakInterval.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      label: '$_breakInterval hours',
                      activeColor: primaryColor,
                      onChanged: (value) => setState(() => _breakInterval = value.round()),
                    ),
                  ),
                ),
            ],
            isDark,
            primaryColor,
            cardColor,
          ),
          const SizedBox(height: 16),
          _buildSection(
            'Goals',
            [
              ListTile(
                leading: Icon(Icons.flag, color: primaryColor),
                title: Text('Daily Earnings Goal', style: TextStyle(color: primaryColor)),
                subtitle: Text(
                  '\$${_dailyGoal.toStringAsFixed(0)}',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: _dailyGoal,
                    min: 50,
                    max: 500,
                    divisions: 45,
                    label: '\$${_dailyGoal.toStringAsFixed(0)}',
                    activeColor: primaryColor,
                    onChanged: (value) => setState(() => _dailyGoal = value),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.trending_up, color: primaryColor),
                title: Text('Weekly Earnings Goal', style: TextStyle(color: primaryColor)),
                subtitle: Text(
                  '\$${_weeklyGoal.toStringAsFixed(0)}',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: _weeklyGoal,
                    min: 500,
                    max: 3000,
                    divisions: 25,
                    label: '\$${_weeklyGoal.toStringAsFixed(0)}',
                    activeColor: primaryColor,
                    onChanged: (value) => setState(() => _weeklyGoal = value),
                  ),
                ),
              ),
            ],
            isDark,
            primaryColor,
            cardColor,
          ),
          const SizedBox(height: 16),
          _buildSection(
            'About',
            [
              ListTile(
                leading: Icon(Icons.info, color: primaryColor),
                title: Text('App Version', style: TextStyle(color: primaryColor)),
                subtitle: Text(
                  '1.0.0',
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
              ListTile(
                leading: Icon(Icons.description, color: primaryColor),
                title: Text('Terms of Service', style: TextStyle(color: primaryColor)),
                trailing: Icon(Icons.arrow_forward_ios, color: primaryColor),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.privacy_tip, color: primaryColor),
                title: Text('Privacy Policy', style: TextStyle(color: primaryColor)),
                trailing: Icon(Icons.arrow_forward_ios, color: primaryColor),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.help, color: primaryColor),
                title: Text('Help & Support', style: TextStyle(color: primaryColor)),
                trailing: Icon(Icons.arrow_forward_ios, color: primaryColor),
                onTap: () {},
              ),
            ],
            isDark,
            primaryColor,
            cardColor,
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
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              elevation: 0,
            ),
            child: const Text('Logout'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, bool isDark, Color primaryColor, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        Card(
          color: cardColor,
          elevation: isDark ? 2 : 1,
          child: Column(children: children),
        ),
      ],
    );
  }
}