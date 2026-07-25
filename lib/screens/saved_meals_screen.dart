import 'package:flutter/material.dart';
import '../models/saved_meal.dart';
import '../models/recipe.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import 'recipe_detail_screen.dart';
import 'widgets/app_loading.dart';

class SavedMealsScreen extends StatefulWidget {
  const SavedMealsScreen({super.key});

  @override
  State<SavedMealsScreen> createState() => _SavedMealsScreenState();
}

class _SavedMealsScreenState extends State<SavedMealsScreen> {
  final _db = DatabaseHelper.instance;
  final _auth = AuthService();
  late Future<List<SavedMeal>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final userId = _auth.currentUser?.uid ?? '';
    _future = _db.getSavedMeals(userId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      appBar: AppBar(
        title: const Text('Favorite Recipes'),
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<SavedMeal>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading();
          }
          final meals = snapshot.data ?? [];
          if (meals.isEmpty) {
            return const Center(child: Text('No saved recipes yet.'));
          }
          return ListView.builder(
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              return ListTile(
                leading: meal.imageUrl != null
                    ? Image.network(meal.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.restaurant),
                title: Text(meal.mealName ?? 'Untitled'),
                onTap: () {
                  // We convert SavedMeal back to a skeleton Recipe so Detail screen can fetch nutrition if needed
                  final recipe = Recipe(
                    apiMealId: meal.apiMealId ?? '',
                    name: meal.mealName ?? 'Untitled',
                    source: meal.apiMealId?.startsWith('spoonacular') == true ? 'spoonacular' : 'themealdb',
                    imageUrl: meal.imageUrl,
                  );
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
