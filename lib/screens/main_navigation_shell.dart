import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'widgets/expandable_fab.dart';
import 'widgets/quick_add_menu.dart';
import 'widgets/app_toast.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;
  bool _isQuickAddOpen = false;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _toggleQuickAdd() {
    setState(() => _isQuickAddOpen = !_isQuickAddOpen);
  }

  void _onItemTapped(int index) {
    if (_isQuickAddOpen) {
      setState(() => _isQuickAddOpen = false);
    }
    if (_selectedIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_isQuickAddOpen) {
      setState(() => _isQuickAddOpen = false);
      return false;
    }
    final isFirstRouteInCurrentTab = !await _navigatorKeys[_selectedIndex].currentState!.maybePop();
    if (isFirstRouteInCurrentTab) {
      if (_selectedIndex != 0) {
        setState(() {
          _selectedIndex = 0;
        });
        return false;
      }
    }
    return isFirstRouteInCurrentTab;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          // System back button handling
        }
      },
      child: Stack(
        children: [
          Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildNavigator(0, const HomeScreen()),
                _buildNavigator(1, const ProgressScreen()),
                _buildNavigator(2, const ProfileScreen()),
              ],
            ),
            extendBody: true,
            bottomNavigationBar: _buildBottomNav(),
          ),
          // Blur Overlay
          if (_isQuickAddOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleQuickAdd,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          // Quick Add Menu
          AnimatedSlide(
            offset: _isQuickAddOpen ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _isQuickAddOpen 
                ? QuickAddMenu(onClose: _toggleQuickAdd) 
                : const SizedBox.shrink(),
            ),
          ),
          _buildGlobalFab(),
        ],
      ),
    );
  }

  Widget _buildNavigator(int index, Widget rootPage) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => rootPage,
          settings: settings,
        );
      },
    );
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 100,
      padding: const EdgeInsets.only(left: 32, right: 32, bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))
        ] : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(Icons.home_outlined, _selectedIndex == 0, onTap: () => _onItemTapped(0)),
          _buildNavItem(Icons.trending_up_rounded, _selectedIndex == 1, onTap: () => _onItemTapped(1)),
          const SizedBox(width: 48), // Space for centered FAB
          _buildNavItem(Icons.group_outlined, false, onTap: () => _showComingSoon('Community')),
          _buildNavItem(Icons.person_outline_rounded, _selectedIndex == 2, onTap: () => _onItemTapped(2)),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, {required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Icon(
        icon,
        color: isActive 
            ? (isDark ? Colors.white : Colors.black) 
            : (isDark ? Colors.white24 : Colors.black12),
        size: 32,
      ),
    );
  }

  Widget _buildGlobalFab() {
    return ExpandableFab(
      isOpen: _isQuickAddOpen,
      onTap: _toggleQuickAdd,
      distance: 80,
      children: [],
    );
  }

  void _showComingSoon(String feature) {
    AppToast.show(
      context,
      message: 'The $feature feature is coming soon!',
      title: 'Coming Soon',
      type: ToastType.info,
    );
  }
}
