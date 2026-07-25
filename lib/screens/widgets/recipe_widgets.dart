import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import 'app_logo.dart';

class RecipeDiscoveryCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final VoidCallback onLog;
  final VoidCallback onAddToCart;
  final bool isSaved;

  const RecipeDiscoveryCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onSave,
    required this.onLog,
    required this.onAddToCart,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ] : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecipeImage(isDark),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      if (recipe.source == 'FoodGapp' || recipe.source == 'gemini')
                        _buildSourceBadge('Verified', Colors.blueAccent),
                      if (recipe.source == 'spoonacular' && recipe.isVerified)
                        _buildSourceBadge('USDA Verified', Colors.greenAccent),
                    ],
                  ),
                  if (recipe.aiReasoning != null) ...[
                    const SizedBox(height: 12),
                    _buildAiReasoning(recipe.aiReasoning!),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.calories?.round() ?? 0} calories',
                        style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildMacroRow(isDark),
                  const SizedBox(height: 16),
                  Text(
                    '${recipe.displayIngredientCount} ingredients · by ${recipe.author ?? recipe.source}',
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: isSaved ? Icons.bookmark : Icons.bookmark_outline,
                          label: isSaved ? 'Saved' : 'Save',
                          onTap: onSave,
                          isPrimary: false,
                          isDark: isDark,
                          color: isSaved ? Colors.orangeAccent : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: Icons.shopping_cart_outlined,
                          label: 'List',
                          onTap: onAddToCart,
                          isPrimary: false,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildQuickActionButton(
                          icon: Icons.add_circle_outline,
                          label: 'Log',
                          onTap: onLog,
                          isPrimary: true,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeImage(bool isDark) {
    if (recipe.imageUrl == null) {
      return Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Center(
          child: AppLogo(
            size: 60,
            iconColor: isDark ? Colors.white10 : Colors.black12,
            showFrame: true,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Image.network(
        recipe.imageUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      height: 180,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      child: const Icon(Icons.broken_image_outlined),
    );
  }

  Widget _buildSourceBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: color, size: 10),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAiReasoning(String reasoning) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reasoning,
              style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(bool isDark) {
    String format(double? val) => val != null ? '${val.round()}g' : '--';

    return Row(
      children: [
        _MacroIconValue(
          icon: Icons.restaurant,
          value: format(recipe.protein),
          color: Colors.redAccent,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _MacroIconValue(
          icon: Icons.bakery_dining,
          value: format(recipe.carbs),
          color: Colors.blueAccent,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _MacroIconValue(
          icon: Icons.water_drop,
          value: format(recipe.fat),
          color: Colors.greenAccent,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    required bool isDark,
    Color? color,
  }) {
    final iconColor = color ?? (isPrimary && !isDark ? Colors.greenAccent : (isPrimary ? Colors.white : (isDark ? Colors.white70 : Colors.black54)));
    final textColor = color ?? (isPrimary ? Colors.white : (isDark ? Colors.white : Colors.black87));

    return Material(
      color: isPrimary 
          ? (isDark ? const Color(0xFF333333) : Colors.black)
          : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5)),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                color: iconColor, 
                size: 18
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroIconValue extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final bool isDark;

  const _MacroIconValue({
    required this.icon,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: isDark ? color : color.withValues(alpha: 0.9), 
            fontWeight: FontWeight.bold, 
            fontSize: 14
          ),
        ),
      ],
    );
  }
}

class SegmentedTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SegmentedTab({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected 
                ? (isDark ? const Color(0xFF333333) : Colors.white) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected && !isDark ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))
            ] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? (isDark ? Colors.white : Colors.black) 
                    : (isDark ? Colors.white38 : Colors.black38),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
