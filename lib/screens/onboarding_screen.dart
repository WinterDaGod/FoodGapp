import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'register_screen.dart';
import 'welcome_screen.dart';
import '../services/unit_converter.dart';

class OnboardingData {
  String gender = 'Male';
  String activityLevel = 'Moderately Active';
  String fitnessGoal = 'Maintain';
  String unitSystem = 'Metric';
  double currentWeight = 65.0;
  double height = 170.0;
  double goalWeight = 65.0;
  DateTime birthday = DateTime(2000, 1, 1);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 1;
  final int _totalSteps = 8;
  final OnboardingData _data = OnboardingData();

  final TextEditingController _weightController = TextEditingController(text: '65');
  final TextEditingController _heightController = TextEditingController(text: '170');
  final TextEditingController _feetController = TextEditingController(text: '5');
  final TextEditingController _inchesController = TextEditingController(text: '7');
  final TextEditingController _goalWeightController = TextEditingController(text: '65');

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _goalWeightController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Sync numeric data whenever moving forward from an input step
    if (_currentStep == 5) {
      final val = double.tryParse(_weightController.text) ?? _data.currentWeight;
      _data.currentWeight = UnitConverter.toMetric(val, _data.unitSystem, 'weight');
    }
    if (_currentStep == 6) {
      if (_data.unitSystem == 'Metric') {
        final val = double.tryParse(_heightController.text) ?? _data.height;
        _data.height = UnitConverter.toMetric(val, _data.unitSystem, 'height');
      } else {
        final f = int.tryParse(_feetController.text) ?? 5;
        final i = double.tryParse(_inchesController.text) ?? 7.0;
        _data.height = UnitConverter.feetInchesToCm(f, i);
      }
    }
    if (_currentStep == 7) {
      final val = double.tryParse(_goalWeightController.text) ?? _data.goalWeight;
      _data.goalWeight = UnitConverter.toMetric(val, _data.unitSystem, 'weight');
    }

    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    } else {
      _finish();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        // If we can't pop (e.g. came from Intro Carousel via pushReplacement),
        // go to the Welcome Screen as the safe fallback.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    }
  }

  void _finish() {
    // Collect final numeric data with conversion
    final cw = double.tryParse(_weightController.text) ?? 65.0;
    _data.currentWeight = UnitConverter.toMetric(cw, _data.unitSystem, 'weight');
    
    if (_data.unitSystem == 'Metric') {
      final h = double.tryParse(_heightController.text) ?? 170.0;
      _data.height = UnitConverter.toMetric(h, _data.unitSystem, 'height');
    } else {
      final f = int.tryParse(_feetController.text) ?? 5;
      final i = double.tryParse(_inchesController.text) ?? 7.0;
      _data.height = UnitConverter.feetInchesToCm(f, i);
    }
    
    final gw = double.tryParse(_goalWeightController.text) ?? 65.0;
    _data.goalWeight = UnitConverter.toMetric(gw, _data.unitSystem, 'weight');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(onboardingData: _data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildMainCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
        ] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressBar(),
          const SizedBox(height: 24),
          Text(
            'Step $_currentStep of $_totalSteps',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildStepContent(),
          const SizedBox(height: 48),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 6,
          width: (MediaQuery.of(context).size.width - 112) * (_currentStep / _totalSteps),
          decoration: BoxDecoration(
            color: Colors.greenAccent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1: return _buildGenderStep();
      case 2: return _buildActivityStep();
      case 3: return _buildGoalStep();
      case 4: return _buildUnitStep();
      case 5: return _buildWeightStep();
      case 6: return _buildHeightStep();
      case 7: return _buildGoalWeightStep();
      case 8: return _buildBirthdayStep();
      default: return const SizedBox();
    }
  }

  Widget _buildGenderStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 32),
        _buildSelectionCard('Male', isSelected: _data.gender == 'Male', onTap: () => setState(() => _data.gender = 'Male')),
        const SizedBox(height: 12),
        _buildSelectionCard('Female', isSelected: _data.gender == 'Female', onTap: () => setState(() => _data.gender = 'Female')),
      ],
    );
  }

  Widget _buildActivityStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Activity Level', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 32),
        _buildSelectionCard('Sedentary', subLabel: 'Little to no exercise · <5k steps', isSelected: _data.activityLevel == 'Sedentary', onTap: () => setState(() => _data.activityLevel = 'Sedentary')),
        const SizedBox(height: 12),
        _buildSelectionCard('Lightly Active', subLabel: 'Exercises 1–3x a week · >5k steps', isSelected: _data.activityLevel == 'Lightly Active', onTap: () => setState(() => _data.activityLevel = 'Lightly Active')),
        const SizedBox(height: 12),
        _buildSelectionCard('Moderately Active', subLabel: 'Exercises 3–4x a week · >7.5k steps', isSelected: _data.activityLevel == 'Moderately Active', onTap: () => setState(() => _data.activityLevel = 'Moderately Active')),
        const SizedBox(height: 12),
        _buildSelectionCard('Active', subLabel: 'Exercises 5 days a week · >10k steps', isSelected: _data.activityLevel == 'Active', onTap: () => setState(() => _data.activityLevel = 'Active')),
        const SizedBox(height: 12),
        _buildSelectionCard('Very Active', subLabel: 'Exercises daily · >12k steps', isSelected: _data.activityLevel == 'Very Active', onTap: () => setState(() => _data.activityLevel = 'Very Active')),
      ],
    );
  }

  Widget _buildGoalStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fitness Goal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 32),
        _buildSelectionCard('Lose', isSelected: _data.fitnessGoal == 'Lose', onTap: () => setState(() => _data.fitnessGoal = 'Lose')),
        const SizedBox(height: 12),
        _buildSelectionCard('Maintain', isSelected: _data.fitnessGoal == 'Maintain', onTap: () => setState(() => _data.fitnessGoal = 'Maintain')),
        const SizedBox(height: 12),
        _buildSelectionCard('Gain', isSelected: _data.fitnessGoal == 'Gain', onTap: () => setState(() => _data.fitnessGoal = 'Gain')),
      ],
    );
  }

  Widget _buildUnitStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unit System', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 32),
        _buildSelectionCard('Metric', subLabel: 'kg · cm', isSelected: _data.unitSystem == 'Metric', onTap: () => setState(() => _data.unitSystem = 'Metric')),
        const SizedBox(height: 12),
        _buildSelectionCard('Imperial', subLabel: 'lbs · in', isSelected: _data.unitSystem == 'Imperial', onTap: () => setState(() => _data.unitSystem = 'Imperial')),
      ],
    );
  }

  Widget _buildWeightStep() {
    return _buildInputStep('Current Weight', _weightController, _data.unitSystem == 'Metric' ? 'Current weight (kg)' : 'Current weight (lbs)');
  }

  Widget _buildHeightStep() {
    if (_data.unitSystem == 'Metric') {
      return _buildInputStep('Height', _heightController, 'Height (cm)');
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Height', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _buildImperialInputOnboarding('Feet', _feetController, isDark)),
            const SizedBox(width: 16),
            Expanded(child: _buildImperialInputOnboarding('Inches', _inchesController, isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildImperialInputOnboarding(String label, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border: !isDark ? Border.all(color: Colors.black.withValues(alpha: 0.05)) : null,
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalWeightStep() {
    return _buildInputStep('Goal Weight', _goalWeightController, _data.unitSystem == 'Metric' ? 'Goal weight (kg)' : 'Goal weight (lbs)');
  }

  Widget _buildBirthdayStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Birthday', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 32),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
              border: !isDark ? Border.all(color: Colors.black.withValues(alpha: 0.05)) : null,
            ),
            child: Center(
              child: Text(
                DateFormat('MMMM d, yyyy').format(_data.birthday),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputStep(String title, TextEditingController controller, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 24),
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border: !isDark ? Border.all(color: Colors.black.withValues(alpha: 0.05)) : null,
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard(String label, {String? subLabel, required bool isSelected, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF444444) : Colors.greenAccent.withValues(alpha: 0.1)) 
              : (isDark ? const Color(0xFF333333) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.greenAccent : (isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.05)), 
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label, 
              style: TextStyle(
                color: isSelected ? (isDark ? Colors.greenAccent : Colors.green[700]) : (isDark ? Colors.white : Colors.black87), 
                fontSize: 18, 
                fontWeight: FontWeight.bold
              )
            ),
            if (subLabel != null)
              Text(subLabel, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _prevStep,
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isDark ? const BorderSide(color: Colors.white10) : BorderSide.none,
              ),
              elevation: 0,
            ),
            child: Text(_currentStep == _totalSteps ? 'Finish Setup' : 'Continue', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime tempDate = _data.birthday;

    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 350,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Birthday',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white : Colors.black
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Done', 
                      style: TextStyle(
                        color: Colors.greenAccent, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      )
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _data.birthday,
                    minimumYear: 1900,
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (DateTime newDate) {
                      tempDate = newDate;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    setState(() => _data.birthday = tempDate);
  }
}
