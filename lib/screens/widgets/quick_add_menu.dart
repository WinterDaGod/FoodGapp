import 'package:flutter/material.dart';
import '../add_meal_screen.dart';
import '../recipe_search_screen.dart';
import '../meal_log_screen.dart';
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
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate proportioned width (max 550px for tablet, 92% for phone)
          final double menuWidth = constraints.maxWidth > 600 ? 550 : constraints.maxWidth * 0.92;
          
          // Calculate item height based on childAspectRatio (0.8) and colCount (3)
          // (Width per col) / aspect = height
          final double colWidth = (menuWidth - 48) / 3; // Subtract internal padding
          final double itemHeight = colWidth / 0.8;
          final double pageViewHeight = (itemHeight * 2) + 48; // 2 rows + spacing

          return Center(
            child: Container(
              width: menuWidth,
              margin: const EdgeInsets.only(bottom: 120), // Clear the centered FAB
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151518) : const Color(0xFFF2EFE4),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHandle(isDark),
                  const SizedBox(height: 16),
                  _buildHeader(context, isDark),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: pageViewHeight,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (idx) => setState(() => _currentPage = idx),
                      children: [
                        _buildGridPage(context, isDark, 0),
                        _buildGridPage(context, isDark, 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPageIndicator(isDark),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildHandle(bool isDark) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black12,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADD',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: isDark ? Colors.white30 : Colors.black38,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Quick Add',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridPage(BuildContext context, bool isDark, int pageIndex) {
    final List<Widget> items = [
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
        icon: Icons.edit_outlined,
        label: 'Manual',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMealScreen())),
      ),
      _buildActionItem(
        context,
        icon: Icons.soup_kitchen_outlined,
        label: 'Recipes',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeSearchScreen())),
      ),
      _buildActionItem(
        context,
        icon: Icons.history,
        label: 'Recent',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealLogScreen())),
      ),
      _buildActionItem(
        context,
        icon: Icons.favorite_outline,
        label: 'Saved',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeSearchScreen())),
      ),
      _buildActionItem(
        context,
        icon: Icons.auto_awesome_rounded,
        label: 'Planner',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPlanScreen())),
      ),
      _buildActionItem(
        context,
        icon: Icons.shopping_cart_outlined,
        label: 'List',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
      ),
    ];

    final start = pageIndex * 6;
    final end = (start + 6).clamp(0, items.length);
    final pageItems = items.sublist(start, end);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 24, // More space between rows
      crossAxisSpacing: 12,
      childAspectRatio: 0.8, // Adjusted to fit label comfortably below circle
      children: pageItems,
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
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        final isSelected = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isSelected ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isSelected ? Colors.greenAccent : (isDark ? Colors.white10 : Colors.black12),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
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
