import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'legal_content_screen.dart';
import 'widgets/dashboard_widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentNutrientIndex = 0;
  Timer? _timer;

  static const List<_NutrientData> _nutrients = [
    _NutrientData(Icons.local_fire_department, Colors.orangeAccent, 'Energy'),
    _NutrientData(Icons.restaurant, Colors.redAccent, 'Protein'),
    _NutrientData(Icons.bakery_dining, Colors.blueAccent, 'Carbs'),
    _NutrientData(Icons.water_drop, Colors.greenAccent, 'Hydration'),
  ];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentNutrientIndex = (_currentNutrientIndex + 1) % _nutrients.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2EFE4),
      body: Stack(
        children: [
          // Background Gradient subtle
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark ? Colors.black : const Color(0xFFF2EFE4),
                    isDark ? const Color(0xFF121212) : Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildMainCard(context),
                    const SizedBox(height: 48),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 30, offset: const Offset(0, 15))
        ] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
        ],
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogoIcon(),
          const SizedBox(height: 24),
          Text(
            'foodgapp',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Achieve your goal weight with clinical-grade tracking and AI insights.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 56),
          
          // Refined Nutrient Animation
          SizedBox(
            height: 180,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              switchInCurve: Curves.elasticOut,
              switchOutCurve: Curves.easeInBack,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_currentNutrientIndex),
                child: Column(
                  children: [
                    const _AnimatedNutrientCircle(size: 140),
                    const SizedBox(height: 12),
                    Text(
                      _nutrients[_currentNutrientIndex].label.toUpperCase(),
                      style: TextStyle(
                        color: _nutrients[_currentNutrientIndex].color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 56),
          _buildGetStartedButton(context),
          const SizedBox(height: 24),
          _buildSignInLink(context),
        ],
      ),
    );
  }

  Widget _buildLogoIcon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.restaurant_rounded,
        color: Colors.orange,
        size: 32,
      ),
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Get started',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSignInLink(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 14),
          children: [
            const TextSpan(text: 'Already have an account? '),
            TextSpan(
              text: 'Sign In',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12),
            children: [
              const TextSpan(text: 'By continuing, you agree to our '),
              TextSpan(
                text: 'Terms of Use',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LegalContentScreen(contentType: LegalContentType.terms)),
                  ),
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LegalContentScreen(contentType: LegalContentType.privacy)),
                  ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _NutrientData {
  final IconData icon;
  final Color color;
  final String label;

  const _NutrientData(this.icon, this.color, this.label);
}

class _AnimatedNutrientCircle extends StatelessWidget {
  final double size;

  const _AnimatedNutrientCircle({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_WelcomeScreenState>()!;
    final nutrient = _WelcomeScreenState._nutrients[state._currentNutrientIndex];

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 2500),
      curve: Curves.easeInOutQuart,
      builder: (context, value, child) {
        return NutrientCircle(
          progress: value,
          icon: nutrient.icon,
          color: nutrient.color,
          size: size,
        );
      },
    );
  }
}
