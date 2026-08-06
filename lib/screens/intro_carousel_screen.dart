import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';

class IntroCarouselScreen extends StatefulWidget {
  const IntroCarouselScreen({super.key});

  @override
  State<IntroCarouselScreen> createState() => _IntroCarouselScreenState();
}

class _IntroCarouselScreenState extends State<IntroCarouselScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_IntroPage> _pages = [
    const _IntroPage(
      title: 'Clinical Precision',
      description: 'Track more than just calories. Monitor Sodium, Fiber, Sugar, and Cholesterol with medical-grade accuracy.',
      icon: Icons.biotech_outlined,
      color: Color(0xFF006064), // Deep Teal
      accentColor: Colors.tealAccent,
    ),
    const _IntroPage(
      title: 'Magic AI Vision',
      description: 'The easiest way to log. Simply point your camera at your plate and let our AI handle the nutritional analysis.',
      icon: Icons.auto_awesome_outlined,
      color: Color(0xFF1A237E), // Indigo
      accentColor: Colors.blueAccent,
    ),
    const _IntroPage(
      title: 'RPG Progress',
      description: 'Turn your health journey into a game. Earn XP, level up, and unlock achievements for every healthy choice.',
      icon: Icons.shield_outlined,
      color: Color(0xFFE65100), // Deep Orange
      accentColor: Colors.orangeAccent,
    ),
  ];

  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);
    
    if (mounted) {
      // Direct navigation to WelcomeScreen, removing the carousel from history
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _pages[_currentPage].accentColor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dynamic Background Gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _pages[_currentPage].color,
                  Colors.black,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Particle/Glow effect (Simple built-in animation)
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withValues(alpha: 0.15),
              ),
            ),
          ),

          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon/Illustration Area
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, val, child) {
                        return Transform.scale(
                          scale: val,
                          child: Opacity(
                            opacity: val,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: page.accentColor.withValues(alpha: 0.2)),
                        ),
                        child: Icon(
                          page.icon,
                          size: 100,
                          color: page.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 64),
                    
                    // Text Content
                    Text(
                      page.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      page.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),

          // Footer Controls
          Positioned(
            bottom: 64,
            left: 32,
            right: 32,
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _pageController,
                  count: _pages.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: activeColor,
                    dotColor: Colors.white24,
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 4,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeIntro();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Start Journey' : 'Continue',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                if (_currentPage < _pages.length - 1)
                  TextButton(
                    onPressed: _completeIntro,
                    child: Text(
                      'Skip',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color accentColor;

  const _IntroPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.accentColor,
  });
}
