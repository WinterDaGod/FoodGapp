import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/user_profile.dart';
import '../models/weight_log.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/app_events.dart';

import 'onboarding_screen.dart';
import 'widgets/app_loading.dart';

class RegisterScreen extends StatefulWidget {
  final OnboardingData? onboardingData;

  const RegisterScreen({super.key, this.onboardingData});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _authService = AuthService();

  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await _authService.register(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!result.isSuccess) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = result.errorMessage;
        });
      }
      return;
    }

    // CRITICAL: We must save the profile data even if the widget is unmounting
    // because AuthGate will rebuild the app immediately upon user creation.
    final user = result.user!;
    final profile = UserProfile(
      userId: user.uid,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      gender: widget.onboardingData?.gender,
      activityLevel: widget.onboardingData?.activityLevel,
      healthGoal: widget.onboardingData?.fitnessGoal == 'Lose' ? 'Lose Weight' : 
                  widget.onboardingData?.fitnessGoal == 'Gain' ? 'Gain Weight/Muscle' : 'Maintain Weight',
      unitSystem: widget.onboardingData?.unitSystem ?? 'Metric',
      weightKg: widget.onboardingData?.currentWeight,
      heightCm: widget.onboardingData?.height,
      targetWeightKg: widget.onboardingData?.goalWeight,
      birthday: widget.onboardingData != null ? DateFormat('yyyy-MM-dd').format(widget.onboardingData!.birthday) : null,
      createdAt: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    
    await DatabaseHelper.instance.upsertUserProfile(profile);

    // Also log the initial weight as the starting point for the journey
    if (profile.weightKg != null) {
      await DatabaseHelper.instance.insertWeightLog(WeightLog(
        userId: user.uid,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        weightKg: profile.weightKg!,
      ));
    }

    AppEvents.instance.notifyProfileChanged();
    AppEvents.instance.notifyWeightChanged();

    // After database write is complete, we can clear the navigation if still mounted.
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildLabel('Full Name'),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Enter your name',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 20),
                _buildLabel('Email Address'),
                _buildTextField(
                  controller: _emailController,
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter your email';
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildLabel('Password'),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Min 8 chars, mixed case, numbers & symbols',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter a password';
                    if (value.length < 8) return 'Minimum 8 characters required';
                    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add at least one uppercase letter';
                    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Add at least one lowercase letter';
                    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add at least one number';
                    if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) return 'Add at least one special character';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildLabel('Confirm Password'),
                _buildTextField(
                  controller: _confirmController,
                  hint: 'Re-enter password',
                  icon: Icons.lock_reset_outlined,
                  obscureText: _obscurePassword,
                  validator: (value) => (value != _passwordController.text) ? 'Passwords do not match' : null,
                ),
                if (_error != null) _buildErrorBanner(),
                const SizedBox(height: 40),
                _buildRegisterButton(),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          const TextSpan(
                            text: 'Login',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(40),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
        ] : null,
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              Text('Start your fitness journey', style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black45)),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.person_add_alt_1, color: Colors.orange),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -40,
            child: Text('F', style: TextStyle(fontSize: 120, fontWeight: FontWeight.bold, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03))),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black26),
          border: InputBorder.none,
          icon: Icon(icon, color: isDark ? Colors.white38 : Colors.black38, size: 22),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isLoading
            ? AppLoading(size: 20, strokeWidth: 2, color: isDark ? Colors.black : Colors.white)
            : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
