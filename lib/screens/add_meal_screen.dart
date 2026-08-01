import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_log.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/app_events.dart';
import '../services/sound_service.dart';
import '../services/gamification_service.dart';
import 'widgets/add_ingredient_modal.dart';
import 'widgets/app_toast.dart';

class AddMealScreen extends StatefulWidget {
  final Recipe? recipe;
  final MealLog? existingLog;
  final String? initialName;
  final List<Ingredient>? initialIngredients;

  const AddMealScreen({
    super.key, 
    this.recipe, 
    this.existingLog,
    this.initialName,
    this.initialIngredients,
  });

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _sugarController = TextEditingController();
  final _sodiumController = TextEditingController();
  final _cholesterolController = TextEditingController();

  final List<Ingredient> _ingredients = [];
  int _servings = 1;
  bool _isMacrosView = false; 
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  double _baseCalories = 0;
  double _baseProtein = 0;
  double _baseCarbs = 0;
  double _baseFat = 0;
  double _baseFiber = 0;
  double _baseSugar = 0;
  double _baseSodium = 0;
  double _baseCholesterol = 0;

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      final r = widget.recipe!;
      _nameController.text = r.name;
      
      _baseCalories = r.calories ?? 0;
      _baseProtein = r.protein ?? 0;
      _baseCarbs = r.carbs ?? 0;
      _baseFat = r.fat ?? 0;
      _baseFiber = r.fiber ?? 0;
      _baseSugar = r.sugar ?? 0;
      _baseSodium = r.sodium ?? 0;
      _baseCholesterol = r.cholesterol ?? 0;

      _updateControllers();
      _isMacrosView = true;
    } else if (widget.initialIngredients != null) {
      _nameController.text = widget.initialName ?? '';
      _ingredients.addAll(widget.initialIngredients!);
      _calculateFromIngredients();
      _isMacrosView = false;
    } else if (widget.existingLog != null) {
      final log = widget.existingLog!;
      _nameController.text = log.foodName;

      _baseCalories = log.baseCalories ?? 0;
      _baseProtein = log.baseProtein ?? 0;
      _baseCarbs = log.baseCarbs ?? 0;
      _baseFat = log.baseFat ?? 0;
      _baseFiber = log.baseFiber ?? 0;
      _baseSugar = log.baseSugar ?? 0;
      _baseSodium = log.baseSodium ?? 0;
      _baseCholesterol = log.baseCholesterol ?? 0;

      if (log.ingredients != null) {
        _ingredients.addAll(log.ingredients!);
      }

      _updateControllers();

      if (_ingredients.isEmpty) {
        _caloriesController.text = log.calories?.round().toString() ?? '';
        _proteinController.text = log.protein?.round().toString() ?? '';
        _carbsController.text = log.carbs?.round().toString() ?? '';
        _fatController.text = log.fat?.round().toString() ?? '';
        _fiberController.text = log.fiber?.round().toString() ?? '';
        _sugarController.text = log.sugar?.round().toString() ?? '';
        _sodiumController.text = log.sodium?.round().toString() ?? '';
        _cholesterolController.text = log.cholesterol?.round().toString() ?? '';
      }

      _selectedDate = DateTime.tryParse(log.mealDate) ?? DateTime.now();
      if (log.mealTime != null) {
        try {
          final format = DateFormat.jm();
          final dt = format.parse(log.mealTime!);
          _selectedTime = TimeOfDay.fromDateTime(dt);
        } catch (_) {}
      }
      _isMacrosView = _ingredients.isEmpty;
    }
  }

  void _updateControllers() {
    _caloriesController.text = _baseCalories.round().toString();
    _proteinController.text = _baseProtein.round().toString();
    _carbsController.text = _baseCarbs.round().toString();
    _fatController.text = _baseFat.round().toString();
    _fiberController.text = _baseFiber.round().toString();
    _sugarController.text = _baseSugar.round().toString();
    _sodiumController.text = _baseSodium.round().toString();
    _cholesterolController.text = _baseCholesterol.round().toString();
  }

  void _calculateFromIngredients() {
    double totalCal = _baseCalories;
    double totalProtein = _baseProtein;
    double totalCarbs = _baseCarbs;
    double totalFat = _baseFat;
    double totalFiber = _baseFiber;
    double totalSugar = _baseSugar;
    double totalSodium = _baseSodium;
    double totalChol = _baseCholesterol;

    for (final ing in _ingredients) {
      totalCal += ing.calories;
      totalProtein += ing.protein;
      totalCarbs += ing.carbs;
      totalFat += ing.fat;
      totalFiber += ing.fiber;
      totalSugar += ing.sugar;
      totalSodium += ing.sodium;
      totalChol += ing.cholesterol;
    }

    setState(() {
      _caloriesController.text = (totalCal * _servings).round().toString();
      _proteinController.text = (totalProtein * _servings).round().toString();
      _carbsController.text = (totalCarbs * _servings).round().toString();
      _fatController.text = (totalFat * _servings).round().toString();
      _fiberController.text = (totalFiber * _servings).round().toString();
      _sugarController.text = (totalSugar * _servings).round().toString();
      _sodiumController.text = (totalSodium * _servings).round().toString();
      _cholesterolController.text = (totalChol * _servings).round().toString();
    });
  }

  void _showComingSoon(String feature) {
    AppToast.show(
      context,
      message: 'The $feature feature is coming soon!',
      title: 'Coming Soon',
      type: ToastType.info,
    );
  }

  Future<void> _showAddIngredientModal() async {
    final result = await showModalBottomSheet<Ingredient>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddIngredientModal(),
    );

    if (result != null && mounted) {
      setState(() {
        _ingredients.add(result);
        _calculateFromIngredients();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    _cholesterolController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = AuthService().currentUser?.uid;
    if (userId == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final timeStr = _selectedTime.format(context);

    final log = MealLog(
      id: widget.existingLog?.id,
      userId: userId,
      mealDate: dateStr,
      mealTime: timeStr,
      mealType: widget.existingLog?.mealType ?? 'Manual',
      foodName: _nameController.text.trim(),
      calories: double.tryParse(_caloriesController.text),
      protein: double.tryParse(_proteinController.text),
      carbs: double.tryParse(_carbsController.text),
      fat: double.tryParse(_fatController.text),
      fiber: double.tryParse(_fiberController.text),
      sugar: double.tryParse(_sugarController.text),
      sodium: double.tryParse(_sodiumController.text),
      cholesterol: double.tryParse(_cholesterolController.text),
      imageUrl: widget.recipe?.imageUrl ?? widget.existingLog?.imageUrl,
      apiMealId: widget.recipe?.apiMealId ?? widget.existingLog?.apiMealId,
      ingredients: _ingredients.isNotEmpty ? _ingredients : null,
      baseCalories: _baseCalories,
      baseProtein: _baseProtein,
      baseCarbs: _baseCarbs,
      baseFat: _baseFat,
      baseFiber: _baseFiber,
      baseSugar: _baseSugar,
      baseSodium: _baseSodium,
      baseCholesterol: _baseCholesterol,
    );

    if (widget.existingLog != null) {
      await DatabaseHelper.instance.upsertMealLog(log); 
    } else {
      await DatabaseHelper.instance.insertMealLog(log);
      await GamificationService.instance.addXp(50);
      await GamificationService.instance.unlockAchievement('first_meal');
    }

    SoundService.instance.playSuccess();
    AppEvents.instance.notifyMealChanged();

    if (mounted) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        message: widget.existingLog != null ? 'Changes saved to your log.' : 'Successfully added to your dashboard.',
        title: widget.existingLog != null ? 'Meal Updated' : 'Meal Logged',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text('Meal name', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
                      const SizedBox(height: 8),
                      _buildTextField(_nameController, 'Meal name'),
                      const SizedBox(height: 24),
                      _buildToggle(),
                      const SizedBox(height: 24),
                      if (_isMacrosView) _buildMacrosGrid() else _buildIngredientsView(),
                      const SizedBox(height: 32),
                      Text('Photo (optional)', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _showComingSoon('Take Photo'),
                              borderRadius: BorderRadius.circular(20),
                              child: _buildActionButton(Icons.camera_alt_outlined, 'Take Photo'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _showComingSoon('Upload Photo'),
                              borderRadius: BorderRadius.circular(20),
                              child: _buildActionButton(Icons.file_upload_outlined, 'Upload Photo'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildInfoTile('Date', DateFormat('MMMM d, yyyy').format(_selectedDate), Icons.calendar_today, _pickDate)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildInfoTile('Time', _selectedTime.format(context), Icons.access_time, _pickTime)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Manual Entry', 
            style: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white : Colors.black
            )
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black26),
          border: InputBorder.none,
        ),
        validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE0E0E0).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isMacrosView = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isMacrosView ? (isDark ? const Color(0xFF333333) : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: !_isMacrosView && !isDark ? [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    'Ingredients', 
                    style: TextStyle(
                      color: !_isMacrosView ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white38 : Colors.black38),
                      fontWeight: !_isMacrosView ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    )
                  )
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isMacrosView = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isMacrosView ? (isDark ? const Color(0xFF333333) : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _isMacrosView && !isDark ? [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    'Macros', 
                    style: TextStyle(
                      color: _isMacrosView ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white38 : Colors.black38),
                      fontWeight: _isMacrosView ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    )
                  )
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double totalWeight = 0;
    for (final ing in _ingredients) {
      totalWeight += ing.amount;
    }
    totalWeight *= _servings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total servings', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)),
            Text('Total weight: ${totalWeight.round()} g', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        _buildServingsSelector(),
        const SizedBox(height: 24),
        Text('Ingredients', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
        const SizedBox(height: 12),
        ..._ingredients.asMap().entries.map((entry) => _buildIngredientItem(entry.value, entry.key)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showAddIngredientModal,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 1.5),
              boxShadow: !isDark ? [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
              ] : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: isDark ? Colors.white : Colors.black, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Add ingredients', 
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 15
                  )
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServingsSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              if (_servings > 1) {
                setState(() => _servings--);
                _calculateFromIngredients();
              }
            },
            icon: Icon(Icons.remove, color: isDark ? Colors.white70 : Colors.black54, size: 20),
          ),
          Text(
            '$_servings', 
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black, 
              fontSize: 20, 
              fontWeight: FontWeight.bold
            )
          ),
          IconButton(
            onPressed: () {
              setState(() => _servings++);
              _calculateFromIngredients();
            },
            icon: Icon(Icons.add, color: isDark ? Colors.white70 : Colors.black54, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(Ingredient ing, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${ing.amount.round()}', 
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black, 
                fontWeight: FontWeight.bold,
                fontSize: 16
              )
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ing.name, 
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 16
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ing.isVerified || ing.source == 'FoodGapp') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, color: Colors.greenAccent, size: 8),
                            const SizedBox(width: 3),
                            Text(
                              ing.source == 'USDA' ? 'USDA' : 'Verified', 
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${ing.unit} · ${ing.calories.round()} kcal', 
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _ingredients.removeAt(index);
                _calculateFromIngredients();
              });
            },
            icon: Icon(Icons.delete_outline, color: isDark ? Colors.white24 : Colors.black26, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMacroInput('Calories (kcal)', _caloriesController, 'Calories')),
            const SizedBox(width: 12),
            Expanded(child: _buildMacroInput('Protein (g)', _proteinController, 'Protein')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMacroInput('Carbs (g)', _carbsController, 'Carbs')),
            const SizedBox(width: 12),
            Expanded(child: _buildMacroInput('Fats (g)', _fatController, 'Fats')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMacroInput('Fiber (g)', _fiberController, 'Fiber')),
            const SizedBox(width: 12),
            Expanded(child: _buildMacroInput('Sugar (g)', _sugarController, 'Sugar')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMacroInput('Sodium (mg)', _sodiumController, 'Sodium')),
            const SizedBox(width: 12),
            Expanded(child: _buildMacroInput('Cholesterol (mg)', _cholesterolController, 'Cholesterol')),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroInput(String label, TextEditingController controller, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
            boxShadow: !isDark ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
            ] : null,
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 20),
          const SizedBox(width: 10),
          Text(
            label, 
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black, 
              fontWeight: FontWeight.bold,
              fontSize: 14
            )
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
              boxShadow: !isDark ? [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
              ] : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value, 
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black, 
                      fontWeight: FontWeight.bold,
                      fontSize: 15
                    ), 
                    overflow: TextOverflow.ellipsis
                  )
                ),
                Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, -5))
        ] : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : Colors.black,
                side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.black,
                foregroundColor: isDark ? Colors.white : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), 
                  side: isDark ? const BorderSide(color: Colors.white24, width: 1.5) : BorderSide.none
                ),
                elevation: 0,
              ),
              child: const Text('Add meal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }
}
