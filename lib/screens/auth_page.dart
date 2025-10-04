import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
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

    return Scaffold(
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
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  Constants.appName,
                  style: AppTextStyles.headline1.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  Constants.tagline,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(4),
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius - 4),
                    ),
                    labelStyle: AppTextStyles.button,
                    tabs: [
                      Tab(
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: _tabController.index == 0
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Register',
                          style: TextStyle(
                            color: _tabController.index == 1
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                    onTap: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: _tabController.index == 0 ? 400 : 600,
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildLoginForm(context, authService),
                      _buildRegisterForm(context, authService),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthService authService) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email or Phone',
              prefixIcon: Icon(Icons.person_outline),
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
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_showLoginPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showLoginPassword = !_showLoginPassword),
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
              child: const Text('Forgot Password?'),
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
                style: TextStyle(color: AppColors.error),
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
            child: authService.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
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
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              GestureDetector(
                onTap: () => _tabController.animateTo(1),
                child: Text(
                  'Register',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () async {
              // Quick demo login
              await authService.login('demo@uber.com', 'password');
              if (context.mounted) {
                context.go('/dashboard');
              }
            },
            child: Text(
              'Skip Login (Demo Mode)',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, AuthService authService) {
    final theme = Theme.of(context);

    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _registerNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: Validators.name,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: Validators.email,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: Validators.phone,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<VehicleType>(
            value: _selectedVehicleType,
            decoration: const InputDecoration(
              labelText: 'Vehicle Type',
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
            items: VehicleType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.toString().split('.').last.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedVehicleType = value);
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerLicenseController,
            decoration: const InputDecoration(
              labelText: 'Driver\'s License / ID Number',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: Validators.licenseNumber,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerPasswordController,
            obscureText: !_showRegisterPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_showRegisterPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showRegisterPassword = !_showRegisterPassword),
              ),
            ),
            validator: Validators.password,
          ),
          if (_registerPasswordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPasswordStrengthIndicator(),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerConfirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) => Validators.confirmPassword(value, _registerPasswordController.text),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _acceptTerms,
                onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                activeColor: theme.colorScheme.primary,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                  child: Text(
                    'I accept the Terms & Conditions',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
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
            child: authService.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Register'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
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
                  color: index < _passwordStrength ? strengthColor : Colors.grey[300],
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