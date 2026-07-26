import 'dart:ui';
import 'package:flutter/material.dart';
import '../add_meal_screen.dart';
import '../recipe_search_screen.dart';
import '../meal_plan_screen.dart';
import '../shopping_list_screen.dart';
import 'describe_meal_modal.dart';
import 'app_toast.dart';

class QuickAddMenu extends StatefulWidget {
  final VoidCallback? onClose;

  const QuickAddMenu({super.key, this.onClose});

  @override
  State<QuickAddMenu> createState() => _QuickAddMenuState();
}

class _QuickAddMenuState extends State<QuickAddMenu> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Ultra-compact width for phone screens
          final double menuWidth = constraints.maxWidth > 600 ? 420 : constraints.maxWidth * 0.86;

          return Stack(
            children: [
              // Tap outside to close (Invisible layer)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (widget.onClose != null) widget.onClose!();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 105), // Float precisely above the FAB
                  child: GestureDetector(
                    onTap: () {}, // Absorb taps on the menu itself
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: menuWidth,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? const Color(0xFF1A1A1E).withValues(alpha: 0.8) 
                                : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(child: _buildHandle(isDark)),
                              const SizedBox(height: 12),
                              _buildHeader(context, isDark),
                              const SizedBox(height: 20),
                              _buildUnifiedGrid(context, isDark),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      width: 32,
      height: 3,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black12,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add to your day',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Choose how you'd like to log food.",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white30 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedGrid(BuildContext context, bool isDark) {
    final List<Widget> items = [
      _buildActionItem(
        context,
        icon: Icons.favorite_outline,
        label: 'Saved',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeSearchScreen())),
      ),
      _buildActionItem(
        context,
        icon: Icons.add_circle_outline,
        label: 'Log meal',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMealScreen())),
      ),
      _buildActionItem(
        context,
        icon: Icons.edit_outlined,
        label: 'Manual',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMealScreen())),
      ),
      _buildActionItem(
        context,
        icon: Icons.chat_bubble_outline,
        label: 'Describe',
        onTap: () => showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const DescribeMealModal(),
        ),
      ),
      _buildActionItem(
        context,
        icon: Icons.camera_alt_outlined,
        label: 'Photo',
        onTap: () => _showComingSoon(context, 'AI Photo Recognition'),
      ),
      _buildActionItem(
        context,
        icon: Icons.view_column_rounded,
        label: 'Scan',
        onTap: () => _showComingSoon(context, 'Barcode Scanner'),
      ),
      _buildActionItem(
        context,
        icon: Icons.auto_awesome_rounded,
        label: 'Planner',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPlanScreen())),
      ),
      _buildActionItem(
        context,
        icon: Icons.soup_kitchen_outlined,
        label: 'Recipes',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeSearchScreen())),
      ),
      _buildActionItem(
        context,
        icon: Icons.shopping_cart_outlined,
        label: 'List',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: items,
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            if (widget.onClose != null) widget.onClose!();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 18),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    AppToast.show(
      context,
      message: 'The $feature feature is coming soon!',
      title: 'Coming Soon',
      type: ToastType.info,
    );
  }
}
