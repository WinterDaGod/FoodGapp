import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api/ai_vision_service.dart';
import '../models/recipe.dart';
import 'add_meal_screen.dart';
import 'widgets/app_loading.dart';
import 'widgets/app_toast.dart';

class AiVisionLogScreen extends StatefulWidget {
  const AiVisionLogScreen({super.key});

  @override
  State<AiVisionLogScreen> createState() => _AiVisionLogScreenState();
}

class _AiVisionLogScreenState extends State<AiVisionLogScreen> {
  final _picker = ImagePicker();
  final _visionService = AiVisionService();
  
  Uint8List? _imageBytes;
  bool _isAnalyzing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
        _analyzeImage();
      }
    } catch (e) {
      AppToast.show(context, message: 'Failed to pick image.', type: ToastType.error);
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final result = await _visionService.analyzeFoodImage(_imageBytes!);
      
      if (!mounted) return;

      if (result != null) {
        final recipe = Recipe(
          apiMealId: 'vision:${DateTime.now().millisecondsSinceEpoch}',
          name: result['foodName'] ?? 'Detected Meal',
          source: 'FoodGapp AI Vision',
          calories: _sumMacros(result['ingredients'], 'calories'),
          protein: _sumMacros(result['ingredients'], 'protein'),
          carbs: _sumMacros(result['ingredients'], 'carbs'),
          fat: _sumMacros(result['ingredients'], 'fat'),
          ingredients: (result['ingredients'] as List).map((i) => i['name'] as String).toList(),
          isVerified: true,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AddMealScreen(recipe: recipe)),
        );
      } else {
        setState(() => _isAnalyzing = false);
        AppToast.show(context, message: 'AI could not identify food. Please try a clearer photo.', type: ToastType.info);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        AppToast.show(context, message: 'Vision analysis failed.', type: ToastType.error);
      }
    }
  }

  double _sumMacros(dynamic ingredients, String key) {
    if (ingredients is! List) return 0.0;
    return ingredients.fold(0.0, (sum, item) => sum + (item[key] as num).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      appBar: AppBar(
        title: const Text('AI Vision Log'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Center(
        child: _isAnalyzing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLoading(size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'Identifying your food...',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analyzing portions and macros',
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black45),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOptionCard(
                    icon: Icons.camera_alt_outlined,
                    title: 'Take a Photo',
                    subtitle: 'Snap your plate for instant logging',
                    onTap: () => _pickImage(ImageSource.camera),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildOptionCard(
                    icon: Icons.photo_library_outlined,
                    title: 'Pick from Gallery',
                    subtitle: 'Choose an existing food photo',
                    onTap: () => _pickImage(ImageSource.gallery),
                    isDark: isDark,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.orangeAccent, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: isDark ? Colors.white10 : Colors.black12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
