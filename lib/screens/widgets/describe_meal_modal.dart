import 'package:flutter/material.dart';
import '../../services/api/foodgapp_ai_service.dart';
import '../../models/ingredient.dart';
import '../add_meal_screen.dart';
import 'app_toast.dart';

class DescribeMealModal extends StatefulWidget {
  const DescribeMealModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DescribeMealModal(),
    );
  }

  @override
  State<DescribeMealModal> createState() => _DescribeMealModalState();
}

class _DescribeMealModalState extends State<DescribeMealModal> {
  final _controller = TextEditingController();
  final _ai = FoodGappAiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await _ai.parseMealDescription(text);
      
      if (result == null || result['ingredients'] == null) {
        if (mounted) {
          AppToast.show(
            context,
            message: "I couldn't identify any food in that description. Please try being more specific.",
            type: ToastType.error,
          );
        }
      } else {
        final String foodName = result['foodName'] ?? 'AI Described Meal';
        final List<dynamic> ingList = result['ingredients'];
        final ingredients = ingList.map((i) => Ingredient.fromMap(i as Map<String, dynamic>)).toList();

        if (mounted) {
          Navigator.pop(context); // Close modal
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddMealScreen(
                initialName: foodName,
                initialIngredients: ingredients,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: "AI parsing failed. Please try again or use Manual Entry.",
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 32, left: 32, right: 32,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Description',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: isDark ? Colors.white30 : Colors.black26),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Describe what you ate in plain English. Our AI will handle the rest.',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            ),
            child: TextField(
              controller: _controller,
              maxLines: 4,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'e.g. I had two scrambled eggs with a slice of cheese and a cup of coffee...',
                hintStyle: TextStyle(color: isDark ? Colors.white10 : Colors.black12),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _parse,
              icon: _isLoading 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome, size: 20),
              label: Text(
                _isLoading ? 'Analyzing...' : 'Magic Log', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.blueAccent : Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
