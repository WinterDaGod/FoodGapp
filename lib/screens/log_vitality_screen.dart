import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vitality_log.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/app_events.dart';
import '../services/sound_service.dart';
import 'widgets/app_toast.dart';

class LogVitalityScreen extends StatefulWidget {
  const LogVitalityScreen({super.key});

  @override
  State<LogVitalityScreen> createState() => _LogVitalityScreenState();
}

class _LogVitalityScreenState extends State<LogVitalityScreen> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _noteController = TextEditingController();
  
  final _db = DatabaseHelper.instance;
  final _auth = AuthService();
  
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _glucoseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final sys = int.tryParse(_systolicController.text);
    final dia = int.tryParse(_diastolicController.text);
    final glu = double.tryParse(_glucoseController.text);

    if (sys == null && dia == null && glu == null) {
      AppToast.show(context, message: 'Please enter at least one reading.', type: ToastType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      final log = VitalityLog(
        userId: userId,
        date: dateStr,
        time: timeStr,
        systolic: sys,
        diastolic: dia,
        glucose: glu,
        note: _noteController.text.trim(),
      );

      await _db.insertVitalityLog(log);
      
      SoundService.instance.playSuccess();
      if (mounted) {
        AppToast.show(context, message: 'Vitality readings saved.', type: ToastType.success);
        AppEvents.instance.notifyProfileChanged(); // Reuse profile event to refresh progress
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Failed to save readings.', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Vitality Log', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateTimeSelectors(isDark),
            const SizedBox(height: 32),
            _buildSectionTitle('BLOOD PRESSURE', Icons.monitor_heart_outlined, Colors.redAccent),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildInput('Systolic', _systolicController, 'mmHg', isDark)),
                const SizedBox(width: 16),
                Expanded(child: _buildInput('Diastolic', _diastolicController, 'mmHg', isDark)),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('BLOOD GLUCOSE', Icons.bloodtype_outlined, Colors.orangeAccent),
            const SizedBox(height: 16),
            _buildInput('Reading', _glucoseController, 'mg/dL', isDark),
            const SizedBox(height: 32),
            _buildSectionTitle('NOTES', Icons.edit_note_outlined, Colors.blueAccent),
            const SizedBox(height: 16),
            _buildNoteInput(isDark),
            const SizedBox(height: 48),
            _buildSaveButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelectors(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(DateFormat('MMM d, yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () async {
              final time = await showTimePicker(context: context, initialTime: _selectedTime);
              if (time != null) setState(() => _selectedTime = time);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(_selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title, 
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: color.withValues(alpha: 0.8))
        ),
      ],
    );
  }

  Widget _buildInput(String label, TextEditingController controller, String unit, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                ),
              ),
              Text(unit, style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: _noteController,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Add a context (e.g. Morning reading)',
          hintStyle: TextStyle(color: isDark ? Colors.white10 : Colors.black12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Text('Save Readings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
