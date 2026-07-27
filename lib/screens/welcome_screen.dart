import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
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
    _NutrientData(Icons.local_fire_department, Colors.orangeAccent),
    _NutrientData(Icons.restaurant, Colors.redAccent),
    _NutrientData(Icons.bakery_dining, Colors.blueAccent),
    _NutrientData(Icons.water_drop, Colors.greenAccent),
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
      backgroundColor: isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
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
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
        ] : null,
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
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Achieve your goal weight by tracking calories and macros every day',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_currentNutrientIndex),
              child: const _AnimatedNutrientCircle(
                size: 140,
              ),
            ),
          ),
          const SizedBox(height: 64),
          _buildGetStartedButton(context),
          const SizedBox(height: 24),
          _buildSignInLink(context),
        ],
      ),
    );
  }

  Widget _buildLogoIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildScanFrame(),
        const Icon(
          Icons.restaurant,
          color: Colors.orange,
          size: 40,
        ),
      ],
    );
  }

  Widget _buildScanFrame() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: _buildCorner(top: true, left: true)),
          Positioned(top: 0, right: 0, child: _buildCorner(top: true, left: false)),
          Positioned(bottom: 0, left: 0, child: _buildCorner(top: false, left: true)),
          Positioned(bottom: 0, right: 0, child: _buildCorner(top: false, left: false)),
        ],
      ),
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    const double size = 20.0;
    const double thickness = 6.0;
    const Color color = Color(0xFF8B5E3C);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          bottom: !top ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          left: left ? const BorderSide(color: color, width: thickness) : BorderSide.none,
          right: !left ? const BorderSide(color: color, width: thickness) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(8) : Radius.zero,
          topRight: top && !left ? const Radius.circular(8) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(8) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(8) : Radius.zero,
        ),
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
          backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
          foregroundColor: Colors.white,
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
          style: TextStyle(color: isDark ? Colors.white60 : Colors.black45, fontSize: 14),
          children: [
            const TextSpan(text: 'Already have an account? '),
            TextSpan(
              text: 'Sign In',
              style: TextStyle(
                color: isDark ? Colors.orangeAccent : Colors.green,
                fontWeight: FontWeight.bold,
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
              ),
              const TextSpan(text: ' and '),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, decoration: TextDecoration.underline),
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

  const _NutrientData(this.icon, this.color);
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
