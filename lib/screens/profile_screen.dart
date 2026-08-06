import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/user_profile.dart';
import '../models/weight_log.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/nutrition_feedback_service.dart';
import '../models/nutrition_target.dart';
import '../services/app_events.dart';
import '../services/unit_converter.dart';

import 'widgets/app_loading.dart';
import 'widgets/app_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class SelectionOption {
  final String title;
  final String description;

  const SelectionOption(this.title, this.description);
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = DatabaseHelper.instance;
  final _authService = AuthService();

  UserProfile? _profile;
  NutritionTarget? _targets;
  String _appVersion = '---';
  int _libraryCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    AppEvents.instance.profileChanged.addListener(_loadProfile);
  }

  @override
  void dispose() {
    AppEvents.instance.profileChanged.removeListener(_loadProfile);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final profile = await _db.getUserProfile(userId);
    final count = await _db.getFoodLibraryCount();
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;

    setState(() {
      _profile = profile;
      _libraryCount = count;
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      if (profile != null) {
        _targets = NutritionFeedbackService.buildTarget(profile);
      }
      _isLoading = false;
    });
  }

  Future<void> _editField(String label, String? currentValue, List<SelectionOption> options, Function(String) onSave, {bool showInfo = false, VoidCallback? onInfoTap}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      label, 
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : Colors.black
                      )
                    ),
                    if (showInfo) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onInfoTap,
                        child: Icon(Icons.info_outline, color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black26, size: 24),
                      ),
                    ],
                  ],
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
            const SizedBox(height: 32),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final opt = options[index];
                  final isSelected = opt.title == currentValue;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, opt.title),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? (isDark ? Colors.white24 : Colors.greenAccent) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                            width: 1.5,
                          ),
                          boxShadow: !isDark ? [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                          ] : null,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 24), // Offset for checkmark balance
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    opt.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.green : (isDark ? Colors.white : Colors.black),
                                    ),
                                  ),
                                  if (opt.description.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        opt.description,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black45,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 24,
                              child: isSelected 
                                ? const Icon(Icons.check, color: Colors.green, size: 20) 
                                : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (selected != null && selected != currentValue) {
      onSave(selected);
    }
  }

  Future<void> _showImperialHeightModal() async {
    if (_profile == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalInches = UnitConverter.cmToIn(_profile?.heightCm ?? 0.0);
    final feet = (totalInches / 12).floor();
    final inches = (totalInches % 12).round();
    
    final feetCtrl = TextEditingController(text: feet == 0 ? '' : feet.toString());
    final inchesCtrl = TextEditingController(text: inches == 0 ? '' : inches.toString());

    final result = await showModalBottomSheet<double>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24, left: 24, right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Height', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                  style: IconButton.styleFrom(backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildImperialInput('Feet', feetCtrl, isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildImperialInput('Inches', inchesCtrl, isDark)),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final f = int.tryParse(feetCtrl.text) ?? 0;
                      final i = double.tryParse(inchesCtrl.text) ?? 0.0;
                      Navigator.pop(context, UnitConverter.feetInchesToCm(f, i));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (result != null) {
      _saveProfile(_profile!.copyWith(heightCm: result));
    }
  }

  Widget _buildImperialInput(String label, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
            boxShadow: !isDark ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
            ] : null,
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Future<void> _editString(String label, String? currentValue, Function(String) onSave) async {
    final controller = TextEditingController(text: currentValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final value = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24, left: 24, right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label, 
                  style: TextStyle(
                    fontSize: 32, 
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
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
                boxShadow: !isDark ? [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                ] : null,
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black, 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (value != null && value.isNotEmpty) {
      onSave(value);
    }
  }

  Future<void> _editNumber(String label, String? currentValue, String unit, Function(double) onSave) async {
    final controller = TextEditingController(text: currentValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final value = await showModalBottomSheet<double>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24, left: 24, right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label, 
                  style: TextStyle(
                    fontSize: 32, 
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
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
                boxShadow: !isDark ? [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                ] : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black, 
                        fontSize: 24, 
                        fontWeight: FontWeight.bold
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Text(
                    unit, 
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (value != null) {
      onSave(value);
    }
  }

  Future<void> _showEditTargets() async {
    if (_profile == null || _targets == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final caloriesCtrl = TextEditingController(text: (_profile!.customCalories ?? _targets!.energyKcal).round().toString());
    final proteinCtrl = TextEditingController(text: (_profile!.customProtein ?? _targets!.proteinGrams.mid).round().toString());
    final carbsCtrl = TextEditingController(text: (_profile!.customCarbs ?? _targets!.carbsGrams.mid).round().toString());
    final fatCtrl = TextEditingController(text: (_profile!.customFat ?? _targets!.fatGrams.mid).round().toString());
    bool autoAdjust = _profile!.autoAdjust;

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24, left: 24, right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Targets', 
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildModalField('Calories (kcal)', caloriesCtrl, autoAdjust, isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildModalField('Protein (g)', proteinCtrl, autoAdjust, isDark)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildModalField('Carbs (g)', carbsCtrl, autoAdjust, isDark)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildModalField('Fats (g)', fatCtrl, autoAdjust, isDark)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Auto adjust', 
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.info_outline, color: isDark ? Colors.white38 : Colors.black26, size: 20),
                  const Spacer(),
                  Switch(
                    value: autoAdjust,
                    onChanged: (val) => setModalState(() => autoAdjust = val),
                    activeTrackColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _saveProfile(_profile!.copyWith(
                          customCalories: double.tryParse(caloriesCtrl.text),
                          customProtein: double.tryParse(proteinCtrl.text),
                          customCarbs: double.tryParse(carbsCtrl.text),
                          customFat: double.tryParse(fatCtrl.text),
                          autoAdjust: autoAdjust,
                        ));
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalField(String label, TextEditingController controller, bool disabled, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
            boxShadow: !isDark ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
            ] : null,
          ),
          child: TextField(
            controller: controller,
            enabled: !disabled,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: disabled ? (isDark ? Colors.white24 : Colors.black26) : (isDark ? Colors.white : Colors.black), 
              fontSize: 18, 
              fontWeight: FontWeight.bold
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editDate(String label, String? currentValue, Function(String) onSave) async {
    final initial = currentValue != null ? DateTime.tryParse(currentValue) ?? DateTime(2000) : DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.green,
            onPrimary: Colors.white,
            surface: Color(0xFF1E1E1E),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      onSave('${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  String _calculateAgeDisplay(String? birthday) {
    if (birthday == null) return 'Not set';
    try {
      final birthDate = DateTime.parse(birthday);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return '$age years old';
    } catch (_) {
      return 'Not set';
    }
  }

  Future<void> _saveProfile(UserProfile updated) async {
    await _db.upsertUserProfile(updated);
    AppEvents.instance.notifyProfileChanged();
    _loadProfile();
  }

  Future<void> _recalculateTargets() async {
    if (_profile == null) return;

    final recommended = NutritionFeedbackService.calculateRecommendedTarget(_profile);
    
    final updated = _profile!.copyWith(
      customCalories: recommended.energyKcal,
      customProtein: recommended.proteinGrams.mid,
      customCarbs: recommended.carbsGrams.mid,
      customFat: recommended.fatGrams.mid,
    );

    await _saveProfile(updated);

    if (mounted) {
      AppToast.show(
        context,
        message: 'Daily targets have been updated based on your current stats.',
        title: 'Recalculated',
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: AppLoading());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Text(
                'Personal Info', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildPersonalInfoSection(),
              const SizedBox(height: 24),
              Text(
                'Measurements', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildMeasurementsSection(),
              const SizedBox(height: 24),
              Text(
                'Daily Targets', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildDailyTargetsSection(),
              const SizedBox(height: 12),
              _buildTargetManagementButtons(),
              const SizedBox(height: 24),
              Text(
                'Customizations', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildCustomizationsSection(),
              const SizedBox(height: 24),
              Text(
                'Technical Information', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildTechnicalInfoSection(),
              const SizedBox(height: 32),
              _buildMaintenanceSection(),
              const SizedBox(height: 32),
              _buildComplianceSection(),
              const SizedBox(height: 32),
              _buildSignOutButton(),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Maintenance', 
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: !isDark ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
            ] : null,
          ),
          child: Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.delete_sweep_outlined,
                  iconColor: Colors.redAccent,
                  label: 'Danger Zone',
                  value: 'Clear all meal logs',
                  onTap: _showClearLogsConfirmation,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy & Security', 
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: !isDark ? [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
            ] : null,
          ),
          child: Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildInfoTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: Colors.blueAccent,
                  label: 'Privacy Center',
                  value: 'Data safety & permissions',
                  onTap: _showPrivacyCenter,
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.no_accounts_outlined,
                  iconColor: Colors.redAccent,
                  label: 'Delete Account',
                  value: 'Permanently remove all data',
                  onTap: _showDeleteAccountConfirmation,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPrivacyCenter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Safety', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 16),
            Text(
              'FoodGapp respects your privacy. We use Health Connect to sync your steps and active energy to provide a complete picture of your health. Your clinical data stays on your device.',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: Colors.green),
              title: const Text('Read Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => _showComingSoon('Privacy Policy URL'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
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

  void _showDeleteAccountConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text('Delete Account?', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text(
          'This will permanently delete your account and all your nutritional logs. This action cannot be undone and is required for Play Store compliance.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final userId = _authService.currentUser?.uid;
              if (userId != null) {
                // 1. Delete local SQLite data
                await _db.deleteUserAccount(userId);
                // 2. Delete Firebase Auth account
                final result = await _authService.deleteAccount();
                if (mounted) {
                  Navigator.pop(context);
                  if (result.isSuccess) {
                     AppToast.show(
                      context,
                      message: 'Your account has been deleted.',
                      title: 'Goodbye',
                      type: ToastType.info,
                    );
                  } else {
                    AppToast.show(
                      context,
                      message: result.errorMessage ?? 'Please re-login to delete.',
                      title: 'Action Required',
                      type: ToastType.error,
                    );
                  }
                }
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showClearLogsConfirmation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text('Clear All Logs?', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text(
          'This will permanently delete all your logged meals. This action cannot be undone.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _db.clearAllMealLogs();
              AppEvents.instance.notifyMealChanged();
              if (mounted) {
                Navigator.pop(context);
                AppToast.show(
                  context,
                  message: 'All meal logs have been cleared.',
                  title: 'Data Reset',
                  type: ToastType.success,
                );
              }
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _profile?.name ?? 'New User';
    final email = _profile?.email ?? 'No email set';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    String memberSince = 'Member';
    if (_profile?.createdAt != null) {
      try {
        final date = DateTime.parse(_profile!.createdAt!);
        memberSince = 'Member since ${DateFormat('MMMM yyyy').format(date)}';
      } catch (_) {}
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
        ] : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orangeAccent, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black45,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_outlined, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          memberSince,
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_profile?.healthGoal != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '🔥 ${_profile!.healthGoal}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ] : null,
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
          _buildInfoTile(
            icon: Icons.person_outline,
            iconColor: Colors.blueAccent,
            label: 'Display Name',
            value: _profile?.name ?? 'Not set',
            onTap: () => _editString('Display Name', _profile?.name, (val) {
              _saveProfile(_profile!.copyWith(name: val));
            }),
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.male,
            iconColor: const Color(0xFF9E85F0), // Lavender
            label: 'Gender',
            value: _profile?.gender ?? 'Not set',
            onTap: () => _editField('Gender', _profile?.gender, [
              const SelectionOption('Male', 'Biological male'),
              const SelectionOption('Female', 'Biological female'),
              const SelectionOption('Other', 'Prefer not to say'),
            ], (val) {
              _saveProfile(_profile!.copyWith(gender: val));
            }),
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.interests_outlined,
            iconColor: const Color(0xFF8CDFB3), // Mint
            label: 'Activity Level',
            value: _profile?.activityLevel ?? 'Not set',
            onTap: () => _editField('Activity Level', _profile?.activityLevel, [
              const SelectionOption('Sedentary', 'Little to no exercise · <5k steps'),
              const SelectionOption('Lightly Active', 'Exercises 1–3x a week · >5k steps'),
              const SelectionOption('Moderately Active', 'Exercises 3–4x a week · >7.5k steps'),
              const SelectionOption('Very Active', 'Exercises 5 days a week · >10k steps'),
              const SelectionOption('Extra Active', 'Exercises daily · >12k steps'),
            ], (val) {
              _saveProfile(_profile!.copyWith(activityLevel: val));
            }),
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.track_changes,
            iconColor: const Color(0xFFF09E85), // Coral
            label: 'Fitness Goal',
            value: _profile?.healthGoal ?? 'Not set',
            onTap: () => _editField('Fitness Goal', _profile?.healthGoal, [
              const SelectionOption('Lose Weight', 'Burn fat and improve definition'),
              const SelectionOption('Maintain Weight', 'Maintain your current physique'),
              const SelectionOption('Gain Weight/Muscle', 'Build strength and size'),
            ], (val) {
              _saveProfile(_profile!.copyWith(healthGoal: val));
            }),
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.star_border,
            iconColor: const Color(0xFFF0D685), // Yellow/Gold
            label: 'Goal Weight',
            value: UnitConverter.formatWeight(_profile?.targetWeightKg ?? 0.0, _profile?.unitSystem ?? 'Metric'),
            onTap: () {
              final system = _profile?.unitSystem ?? 'Metric';
              final currentValue = UnitConverter.fromMetric(_profile?.targetWeightKg ?? 0.0, system, 'weight');
              _editNumber('Goal Weight', currentValue.toStringAsFixed(1), system == 'Imperial' ? 'lbs' : 'kg', (val) {
                final metricVal = UnitConverter.toMetric(val, system, 'weight');
                _saveProfile(_profile!.copyWith(targetWeightKg: metricVal));
              });
            },
          ),
          if (_profile?.healthGoal != 'Maintain Weight') ...[
            _buildDivider(),
            _buildInfoTile(
              icon: Icons.speed,
              iconColor: const Color(0xFF85B3F0), // Blue
              label: 'Goal Pace',
              value: _profile?.goalPace ?? 'Not set',
              onTap: _showGoalPaceModal,
            ),
          ],
        ],
      ),
    ),
  );
}

  Future<void> _showGoalPaceModal() async {
    if (_profile == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLosing = _profile!.healthGoal == 'Lose Weight';
    final prefix = isLosing ? 'Lose' : 'Gain';
    
    final options = ['0.25', '0.5', '0.75', '1.0'];

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Goal Pace', 
                      style: TextStyle(
                        fontSize: 32, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : Colors.black
                      )
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.info_outline, color: isDark ? Colors.white24 : Colors.black26, size: 24),
                  ],
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
            const SizedBox(height: 32),
            ...options.map((val) {
              final title = '$prefix $val kg';
              final isSelected = _profile!.goalPace == '$title/week';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () {
                    _saveProfile(_profile!.copyWith(goalPace: '$title/week'));
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.greenAccent : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                        width: 1.5,
                      ),
                      boxShadow: !isDark ? [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                      ] : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'per week',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ] : null,
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildInfoTile(
            icon: Icons.straighten,
            iconColor: const Color(0xFFE0E0E0), // Neutral grey
            label: 'Height',
            value: UnitConverter.formatHeight(_profile?.heightCm ?? 0.0, _profile?.unitSystem ?? 'Metric'),
            onTap: () {
              final system = _profile?.unitSystem ?? 'Metric';
              if (system == 'Imperial') {
                _showImperialHeightModal();
              } else {
                final currentValue = UnitConverter.fromMetric(_profile?.heightCm ?? 0.0, system, 'height');
                _editNumber('Height', currentValue.toStringAsFixed(1), 'cm', (val) {
                  _saveProfile(_profile!.copyWith(heightCm: val));
                });
              }
            },
          ),
          _buildDivider(),
          _buildStartingWeightTile(),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.fitness_center,
            iconColor: const Color(0xFFE0E0E0), 
            label: 'Current Weight',
            value: UnitConverter.formatWeight(_profile?.weightKg ?? 0.0, _profile?.unitSystem ?? 'Metric'),
            onTap: () {
              final system = _profile?.unitSystem ?? 'Metric';
              final currentValue = UnitConverter.fromMetric(_profile?.weightKg ?? 0.0, system, 'weight');
              _editNumber('Weight', currentValue.toStringAsFixed(1), system == 'Imperial' ? 'lbs' : 'kg', (val) {
                final metricVal = UnitConverter.toMetric(val, system, 'weight');
                _saveProfile(_profile!.copyWith(weightKg: metricVal));
              });
            },
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.cake_outlined,
            iconColor: const Color(0xFFE0E0E0), 
            label: 'Birthday',
            value: _calculateAgeDisplay(_profile?.birthday),
            onTap: () => _editDate('Birthday', _profile?.birthday, (val) {
              _saveProfile(_profile!.copyWith(birthday: val));
            }),
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.balance,
            iconColor: const Color(0xFFE0E0E0), 
            label: 'Unit System',
            value: _profile?.unitSystem ?? 'Metric',
            onTap: () => _editField('Unit System', _profile?.unitSystem, [
              const SelectionOption('Metric', 'kg, cm, kcal'),
              const SelectionOption('Imperial', 'lbs, ft/in, kcal'),
            ], (val) {
              _saveProfile(_profile!.copyWith(unitSystem: val));
            }),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStartingWeightTile() {
    return FutureBuilder<double?>(
      future: _db.getStartingWeight(_authService.currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        final weight = snapshot.data ?? _profile?.weightKg ?? 0.0;
        final formatted = UnitConverter.formatWeight(weight, _profile?.unitSystem ?? 'Metric');
        
        return _buildInfoTile(
          icon: Icons.flag_outlined,
          iconColor: const Color(0xFFE0E0E0),
          label: 'Starting Weight',
          value: formatted,
          onTap: () {
             // Optional: Allow editing the first weight log if it was a mistake
             _showEditStartingWeightModal(weight);
          },
        );
      },
    );
  }

  Future<void> _showEditStartingWeightModal(double currentStart) async {
    final system = _profile?.unitSystem ?? 'Metric';
    final currentVal = UnitConverter.fromMetric(currentStart, system, 'weight');
    final controller = TextEditingController(text: currentVal.toStringAsFixed(1));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unit = system == 'Imperial' ? 'lbs' : 'kg';

    final newVal = await showModalBottomSheet<double>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24, left: 24, right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Starting Weight', 
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
            const SizedBox(height: 32),
            _buildInputContainer(
              isDark: isDark,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black, 
                        fontSize: 24, 
                        fontWeight: FontWeight.bold
                      ),
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  Text(
                    unit, 
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (newVal != null && _profile != null) {
      final metricVal = UnitConverter.toMetric(newVal, system, 'weight');
      // Update the oldest weight log entry
      final db = await _db.database;
      final userId = _profile!.userId;
      
      // Get the ID of the oldest entry
      final rows = await db.query('weight_log', where: 'user_id = ?', whereArgs: [userId], orderBy: 'date ASC', limit: 1);
      if (rows.isNotEmpty) {
        final id = rows.first['id'];
        await db.update('weight_log', {'weight_kg': metricVal}, where: 'id = ?', whereArgs: [id]);
      } else {
        // Fallback: insert if somehow missing
        await _db.insertWeightLog(WeightLog(userId: userId, date: _profile!.createdAt ?? '2024-01-01', weightKg: metricVal));
      }
      
      _loadProfile();
      AppEvents.instance.notifyWeightChanged();
    }
  }

  Widget _buildInputContainer({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? iconColor.withValues(alpha: 0.1) : iconColor.withValues(alpha: 0.15), 
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: isDark ? iconColor : iconColor.withValues(alpha: 0.8), size: 22),
      ),
      title: Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 13)),
      subtitle: Text(
        value, 
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black, 
          fontWeight: FontWeight.bold, 
          fontSize: 16,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black12, size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05), height: 1, indent: 64);
  }

  Widget _buildCustomizationsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ] : null,
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildInfoTile(
            icon: Icons.brightness_6_outlined,
            iconColor: Colors.grey,
            label: 'Theme',
            value: _profile?.themeMode ?? 'System',
            onTap: () => _editField('Theme', _profile?.themeMode, [
              const SelectionOption('System', 'Match device settings'),
              const SelectionOption('Light', 'Always light'),
              const SelectionOption('Dark', 'Always dark'),
            ], (val) {
              _saveProfile(_profile!.copyWith(themeMode: val));
            }),
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.visibility_outlined,
            iconColor: Colors.grey,
            label: 'Surplus',
            value: (_profile?.showSurplus ?? true) ? 'Shown' : 'Hidden',
            onTap: _showSurplusModal,
          ),
          _buildDivider(),
          _buildInfoTile(
            icon: Icons.percent_outlined,
            iconColor: Colors.grey,
            label: 'Macro Preset',
            value: _profile?.macroPreset ?? 'Default',
            onTap: _showMacroPresetModal,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTechnicalInfoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ] : null,
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildInfoTile(
              icon: Icons.info_outline,
              iconColor: Colors.deepPurpleAccent,
              label: 'App Version',
              value: _appVersion,
              onTap: () {}, // Info only
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSurplusModal() async {
    final bool current = _profile?.showSurplus ?? true;
    final String currentValue = current ? 'Shown' : 'Hidden';

    await _editField('Surplus', currentValue, [
      const SelectionOption('Shown', 'Show calories over your goal'),
      const SelectionOption('Hidden', 'Stop counter at daily limit'),
    ], (val) {
      _saveProfile(_profile!.copyWith(showSurplus: val == 'Shown'));
    }, showInfo: true, onInfoTap: _showSurplusInfo);
  }

  void _showSurplusInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Surplus', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              'When on, going over your calorie goal shows how far over you are, like calories over instead of stopping at your limit. When off, the app stays at your daily goal. Most people keep this off unless they want to see overages clearly.',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMacroPresetModal() async {
    await _editField('Macro Preset', _profile?.macroPreset, [
      const SelectionOption('Default', 'Goal-weight protein · 25% fat · rest carbs'),
      const SelectionOption('High-Protein', '40% protein · 30% carbs · 30% fat'),
      const SelectionOption('Keto', '30% protein · 5% carbs · 65% fat'),
      const SelectionOption('Low Carb', '40% protein · 20% carbs · 40% fat'),
      const SelectionOption('Custom', 'Set your own macro percentages'),
    ], (val) {
      if (val == 'Custom') {
        _showCustomMacroSplitModal();
      } else {
        _saveProfile(_profile!.copyWith(macroPreset: val));
        
        if (!(_profile?.autoAdjust ?? true)) {
          AppToast.show(
            context,
            message: 'Tap "Recalculate" to apply this preset to your targets.',
            title: 'Preset Changed',
            type: ToastType.info,
          );
        }
      }
    }, showInfo: true);
  }

  Future<void> _showCustomMacroSplitModal() async {
    if (_profile == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final proteinCtrl = TextEditingController(text: _profile!.customMacroProtein.round().toString());
    final carbsCtrl = TextEditingController(text: _profile!.customMacroCarbs.round().toString());
    final fatCtrl = TextEditingController(text: _profile!.customMacroFat.round().toString());
    
    int focusedField = 0; // 0: protein, 1: carbs, 2: fat

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final controllers = [proteinCtrl, carbsCtrl, fatCtrl];
          
          void onKeyTap(String key) {
            final controller = controllers[focusedField];
            if (key == 'back') {
              if (controller.text.isNotEmpty) {
                controller.text = controller.text.substring(0, controller.text.length - 1);
              }
            } else {
              if (controller.text.length < 3) {
                controller.text += key;
              }
            }
            setModalState(() {});
          }

          int total = (int.tryParse(proteinCtrl.text) ?? 0) + 
                      (int.tryParse(carbsCtrl.text) ?? 0) + 
                      (int.tryParse(fatCtrl.text) ?? 0);
          bool isValid = total == 100;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Custom macro split', 
                      style: TextStyle(
                        fontSize: 24, 
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
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: _buildMacroInputField('Protein (%)', proteinCtrl, focusedField == 0, isDark, () => setModalState(() => focusedField = 0))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMacroInputField('Carbs (%)', carbsCtrl, focusedField == 1, isDark, () => setModalState(() => focusedField = 1))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMacroInputField('Fat (%)', fatCtrl, focusedField == 2, isDark, () => setModalState(() => focusedField = 2))),
                  ],
                ),
                const SizedBox(height: 24),
                if (!isValid && (proteinCtrl.text.isNotEmpty || carbsCtrl.text.isNotEmpty || fatCtrl.text.isNotEmpty))
                  Text(
                    'Total: $total% (Must be 100%)',
                    style: TextStyle(color: total > 100 ? Colors.redAccent : Colors.orangeAccent, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 24),
                _buildCustomNumPad(isDark, onKeyTap),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isValid ? () {
                      _saveProfile(_profile!.copyWith(
                        macroPreset: 'Custom',
                        customMacroProtein: double.tryParse(proteinCtrl.text),
                        customMacroCarbs: double.tryParse(carbsCtrl.text),
                        customMacroFat: double.tryParse(fatCtrl.text),
                      ));
                      Navigator.pop(context);

                      if (!(_profile?.autoAdjust ?? true)) {
                        AppToast.show(
                          context,
                          message: 'Tap "Recalculate" to apply your custom split.',
                          title: 'Split Saved',
                          type: ToastType.info,
                        );
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isValid ? (isDark ? const Color(0xFF333333) : Colors.black) : (isDark ? Colors.white10 : Colors.black12),
                      foregroundColor: isValid ? Colors.white : (isDark ? Colors.white24 : Colors.black26),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildMacroInputField(String label, TextEditingController controller, bool isFocused, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isFocused ? Colors.greenAccent : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)), width: 1.5),
              boxShadow: !isDark ? [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
              ] : null,
            ),
            child: Center(
              child: Text(
                controller.text.isEmpty ? '0' : controller.text,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNumPad(bool isDark, Function(String) onKeyTap) {
    return Column(
      children: [
        for (var row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['', '0', 'back']])
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                for (var key in row)
                  Expanded(
                    child: key.isEmpty 
                      ? const SizedBox() 
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: InkWell(
                            onTap: () => onKeyTap(key),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                              ),
                              child: Center(
                                child: key == 'back' 
                                  ? Icon(Icons.backspace_outlined, color: isDark ? Colors.white : Colors.black)
                                  : Text(key, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDailyTargetsSection() {
    if (_targets == null) return const SizedBox();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildTargetCard('Calories', '${_targets!.energyKcal.round()}', 'kcal', Icons.local_fire_department, Colors.orangeAccent),
        _buildTargetCard('Protein', '${_targets!.proteinGrams.mid.round()}', 'g', Icons.restaurant, Colors.redAccent),
        _buildTargetCard('Carbs', '${_targets!.carbsGrams.mid.round()}', 'g', Icons.bakery_dining, Colors.blueAccent),
        _buildTargetCard('Fats', '${_targets!.fatGrams.mid.round()}', 'g', Icons.water_drop, Colors.greenAccent),
      ],
    );
  }

  Widget _buildTargetCard(String label, String value, String unit, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label, 
                style: TextStyle(
                  color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black45, 
                  fontSize: 14
                )
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.15), 
                  shape: BoxShape.circle
                ),
                child: Icon(icon, color: isDark ? color : color.withValues(alpha: 0.8), size: 14),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value, 
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black, 
                  fontSize: 24, 
                  fontWeight: FontWeight.bold
                )
              ),
              const SizedBox(width: 2),
              Text(
                unit, 
                style: TextStyle(
                  color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black26, 
                  fontSize: 14
                )
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetManagementButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showEditTargets,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Targets'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : Colors.black,
              side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _recalculateTargets,
            icon: const Icon(Icons.sync),
            label: const Text('Recalculate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : Colors.black,
              side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _authService.signOut(),
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}
