import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'onboarding_screen.dart';
import 'widgets/app_loading.dart';
import 'widgets/app_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await _authService.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (result.isSuccess) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _isLoading = false;
        _error = result.errorMessage;
      });
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _authService.sendPasswordResetEmail(email);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      AppToast.show(
        context,
        message: 'Check your inbox for instructions.',
        title: 'Reset Link Sent',
        type: ToastType.success,
      );
    } else {
      setState(() => _error = result.errorMessage);
    }
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                Text('Email Address', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter your email' : null,
                ),
                const SizedBox(height: 16),
                Text('Password', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: isDark ? Colors.white38 : Colors.black38, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? 'Enter your password' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _forgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                    ),
                  ),
                ),
                if (_error != null) _buildErrorBanner(),
                const SizedBox(height: 24),
                _buildLoginButton(),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _goToRegister,
                    style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white70 : Colors.black87),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black38, fontSize: 14),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: 'Register',
                            style: TextStyle(color: isDark ? Colors.greenAccent : Colors.green[700], fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
              Text('Welcome Back', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              Text('Sign in to continue', style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black45)),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.restaurant_menu, color: Colors.green),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black26, fontSize: 15),
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, color: isDark ? Colors.white38 : Colors.black38, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildLoginButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isLoading
            ? const AppLoading(size: 20, strokeWidth: 2, color: Colors.black)
            : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
