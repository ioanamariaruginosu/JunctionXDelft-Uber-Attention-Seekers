import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/rest_timer_service.dart';
import '../utils/validators.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  final _registerLicenseController = TextEditingController();

  VehicleType _selectedVehicleType = VehicleType.car;
  bool _acceptTerms = false;
  bool _showLoginPassword = false;
  bool _showRegisterPassword = false;
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _registerPasswordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    _registerLicenseController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength = Validators.getPasswordStrength(_registerPasswordController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primary;
    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.assistant_navigation,
                  size: 80,
                  color: primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  Constants.appName,
                  style: AppTextStyles.headline1.copyWith(
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  Constants.tagline,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.lightSurface : AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius - 4),
                    ),
                    labelColor: isDark ? AppColors.primary : AppColors.primaryDark,
                    unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                    labelStyle: AppTextStyles.button,
                    tabs: const [
                      Tab(text: 'Login'),
                      Tab(text: 'Register'),
                    ],
                    onTap: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 32),
                if (_tabController.index == 0)
                  _buildLoginForm(context, authService, isDark, primaryColor)
                else
                  _buildRegisterForm(context, authService, isDark, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthService authService, bool isDark, Color primaryColor) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: 'Email or Phone',
              labelStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
              floatingLabelStyle: TextStyle(color: primaryColor),
              prefixIcon: Icon(
                Icons.person_outline,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                size: 22,
              ),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: 1,
                ),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email or phone';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: !_showLoginPassword,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
              floatingLabelStyle: TextStyle(color: primaryColor),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showLoginPassword ? Icons.visibility_off : Icons.visibility,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                onPressed: () => setState(() => _showLoginPassword = !_showLoginPassword),
              ),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: 1,
                ),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Forgot Password?',
                style: TextStyle(color: primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (authService.error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(color: AppColors.error),
              ),
              child: Text(
                authService.error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ElevatedButton(
            onPressed: authService.isLoading
                ? null
                : () async {
              if (_loginFormKey.currentState!.validate()) {
                final success = await authService.login(
                  _loginEmailController.text,
                  _loginPasswordController.text,
                );
                if (success && context.mounted) {
                  context.go('/dashboard');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: isDark ? AppColors.primary : AppColors.primaryDark,
              minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              elevation: 0,
            ),
            child: authService.isLoading
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? AppColors.primary : AppColors.primaryDark,
              ),
            )
                : const Text('Login'),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Don\'t have an account? ',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              GestureDetector(
                onTap: () => _tabController.animateTo(1),
                child: Text(
                  'Register',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () async {
              await authService.login('demo@uber.com', 'password');
              // Schedule demo take-a-break after ~1 minute of going online
              try {
                final restTimer = context.read<RestTimerService>();
                restTimer.scheduleDemoTakeBreak(seconds: 60);
              } catch (_) {
                // RestTimerService may not be available in some test contexts
              }
              if (context.mounted) {
                context.go('/dashboard');
              }
            },
            child: Text(
              'Skip Login (Demo Mode)',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, AuthService authService, bool isDark, Color primaryColor) {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _registerNameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            validator: Validators.name,
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _registerEmailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _registerPhoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<VehicleType>(
            value: _selectedVehicleType,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
            ),
            dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightBackground,
            decoration: InputDecoration(
              labelText: 'Vehicle Type',
              labelStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
              floatingLabelStyle: TextStyle(color: primaryColor),
              prefixIcon: Icon(
                Icons.directions_car_outlined,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                size: 22,
              ),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: primaryColor,
                  width: 2,
                ),
              ),
            ),
            items: VehicleType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type.toString().split('.').last.toUpperCase(),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedVehicleType = value);
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _registerLicenseController,
            label: 'Driver\'s License / ID Number',
            icon: Icons.badge_outlined,
            validator: Validators.licenseNumber,
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerPasswordController,
            obscureText: !_showRegisterPassword,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
              floatingLabelStyle: TextStyle(color: primaryColor),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showRegisterPassword ? Icons.visibility_off : Icons.visibility,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
                onPressed: () => setState(() => _showRegisterPassword = !_showRegisterPassword),
              ),
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: 1,
                ),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.error,
                  width: 2,
                ),
              ),
            ),
            validator: Validators.password,
          ),
          if (_registerPasswordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPasswordStrengthIndicator(isDark),
          ],
          const SizedBox(height: 16),
          _buildTextField(
            controller: _registerConfirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (value) => Validators.confirmPassword(value, _registerPasswordController.text),
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _acceptTerms,
                onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                activeColor: primaryColor,
                checkColor: isDark ? AppColors.primary : AppColors.primaryDark,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                  child: Text(
                    'I accept the Terms & Conditions',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: authService.isLoading || !_acceptTerms
                ? null
                : () async {
              if (_registerFormKey.currentState!.validate()) {
                final success = await authService.register(
                  fullName: _registerNameController.text,
                  email: _registerEmailController.text,
                  phoneNumber: _registerPhoneController.text,
                  password: _registerPasswordController.text,
                  vehicleType: _selectedVehicleType,
                  licenseNumber: _registerLicenseController.text,
                );
                if (success && context.mounted) {
                  context.go('/dashboard');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: isDark ? AppColors.primary : AppColors.primaryDark,
              minimumSize: const Size.fromHeight(AppConstants.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              elevation: 0,
              disabledBackgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
            ),
            child: authService.isLoading
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? AppColors.primary : AppColors.primaryDark,
              ),
            )
                : const Text('Register'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        floatingLabelStyle: TextStyle(color: primaryColor),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
          size: 22,
        ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: primaryColor,
            width: 2,
          ),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordStrengthIndicator(bool isDark) {
    final strengthText = Validators.getPasswordStrengthText(_passwordStrength);
    final strengthColor = _getPasswordStrengthColor(_passwordStrength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            6,
                (index) => Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: index < _passwordStrength
                      ? strengthColor
                      : (isDark ? Colors.grey[800] : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Password Strength: $strengthText',
          style: TextStyle(
            fontSize: 12,
            color: strengthColor,
          ),
        ),
      ],
    );
  }

  Color _getPasswordStrengthColor(int strength) {
    if (strength <= 2) return Colors.red;
    if (strength <= 4) return Colors.orange;
    return Colors.green;
  }
}