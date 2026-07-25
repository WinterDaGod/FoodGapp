import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fasting_session.dart';
import '../models/fasting_stage.dart';
import '../services/fasting_service.dart';
import '../services/app_events.dart';
import '../services/sound_service.dart';
import 'widgets/app_loading.dart';
import 'widgets/app_toast.dart';
import 'fasting_calendar_screen.dart';

class FastingTimerScreen extends StatefulWidget {
  const FastingTimerScreen({super.key});

  @override
  State<FastingTimerScreen> createState() => _FastingTimerScreenState();
}

class _FastingTimerScreenState extends State<FastingTimerScreen> {
  final _service = FastingService();
  FastingSession? _activeSession;
  List<FastingSession> _history = [];
  bool _isLoading = true;
  bool _showSetup = false;
  Timer? _timer;

  final List<Map<String, dynamic>> _presets = [
    {'label': '12:12', 'sub': 'Beginner', 'hours': 12, 'desc': '12h fast'},
    {'label': '14:10', 'sub': 'Moderate', 'hours': 14, 'desc': '14h fast'},
    {'label': '16:8', 'sub': 'Classic', 'hours': 16, 'desc': '16h fast'},
    {'label': '18:6', 'sub': 'Advanced', 'hours': 18, 'desc': '18h fast'},
    {'label': '20:4', 'sub': 'Warrior', 'hours': 20, 'desc': '20h fast'},
    {'label': '23:1', 'sub': 'OMAD', 'hours': 23, 'desc': '23h fast'},
    {'label': 'Open', 'sub': 'Resets on every meal', 'hours': 0, 'desc': 'No hour goal'},
  ];

  Map<String, dynamic>? _selectedPreset;
  DateTime _startTime = DateTime.now();
  String _repeatMode = 'No repeat';
  final Set<int> _selectedDays = {DateTime.now().weekday}; // Default to today

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTimer();
    AppEvents.instance.fastingChanged.addListener(_loadData);
  }

  @override
  void dispose() {
    _timer?.cancel();
    AppEvents.instance.fastingChanged.removeListener(_loadData);
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_activeSession != null && mounted) {
        setState(() {}); // Re-render for ticking clock
      }
    });
  }

  Future<void> _loadData() async {
    final active = await _service.getActiveSession();
    final history = await _service.getHistory();
    if (mounted) {
      setState(() {
        _activeSession = active;
        _history = history;
        _isLoading = false;
      });
    }
  }

  Future<void> _endFast() async {
    await _service.stopFast();
    
    SoundService.instance.playCelebration();
    
    _loadData();
  }

  void _showComingSoon(String feature) {
    AppToast.show(
      context,
      message: 'The $feature feature is coming soon!',
      title: 'Coming Soon',
      type: ToastType.info,
    );
  }

  void _showStageDetails(FastingStage stage) {
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.insights, color: Colors.greenAccent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    stage.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'About this stage',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              stage.description,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 16, height: 1.5),
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
                child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: AppLoading());

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _activeSession != null 
            ? _buildActiveFastUI() 
            : _showSetup 
              ? (_selectedPreset == null ? _buildSelectionUI() : _buildSetupUI())
              : _buildIdleUI(),
        ),
      ),
      bottomNavigationBar: _activeSession == null && !_showSetup 
        ? _buildStartFastButton(isDark) 
        : _activeSession != null 
          ? _buildEndFastButton(isDark) 
          : null,
    );
  }

  Widget _buildEndFastButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      color: Colors.transparent,
      child: ElevatedButton(
        onPressed: _endFast,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isDark ? const BorderSide(color: Colors.white12) : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: const Text('End fast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Fasting Timer', 
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
            style: IconButton.styleFrom(backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        _buildHeader(isDark),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Idle Timer Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: !isDark ? [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
                    ] : null,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'No active fast',
                        style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '00:00',
                        style: TextStyle(
                          fontSize: 64, 
                          fontWeight: FontWeight.bold, 
                          fontFamily: 'monospace',
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Start when you’re ready',
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                _buildHistoryHeader(),
                const SizedBox(height: 24),
                if (_history.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        'No history yet', 
                        style: TextStyle(color: isDark ? Colors.white10 : Colors.black12, fontWeight: FontWeight.bold)
                      ),
                    ),
                  )
                else
                  ..._history.map((h) => _buildHistoryItem(h, isDark)),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartFastButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      color: Colors.transparent,
      child: ElevatedButton(
        onPressed: () => setState(() => _showSetup = true),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isDark ? const BorderSide(color: Colors.white12) : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: const Text('Start a fast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildActiveFastUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final session = _activeSession!;
    final stage = session.currentStage;
    final timeFormat = DateFormat('h:mm a');
    final endTime = session.startTime.add(Duration(hours: session.targetHours));

    return Column(
      children: [
        _buildHeader(isDark),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Timer Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: !isDark ? [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
                    ] : null,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '${session.repeatMode != 'No repeat' ? 'Custom' : 'Beginner'} · ${session.targetHours}:12', // Placeholder label logic
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        session.formattedElapsed,
                        style: TextStyle(
                          fontSize: 64, // Slightly larger
                          fontWeight: FontWeight.bold, 
                          fontFamily: 'monospace',
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimeInfo('Started', timeFormat.format(session.startTime), isDark),
                          _buildTimeInfo('Ends', timeFormat.format(endTime), isDark),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Overall Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: session.progress,
                          minHeight: 12,
                          backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            session.timeRemaining,
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${(session.progress * 100).round()}%',
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Stage Button
                      InkWell(
                        onTap: () => _showStageDetails(stage),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stage ${stage.index} of 11',
                                    style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    stage.name,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                _buildHistoryHeader(),
                const SizedBox(height: 24),
                if (_history.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        'No history yet', 
                        style: TextStyle(color: isDark ? Colors.white10 : Colors.black12, fontWeight: FontWeight.bold)
                      ),
                    ),
                  )
                else
                  ..._history.map((h) => _buildHistoryItem(h, isDark)),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'History',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        Row(
          children: [
            _buildSmallIconButton(Icons.calendar_today, isDark, onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const FastingCalendarScreen()),
              );
            }),
            const SizedBox(width: 12),
            _buildSmallIconButton(Icons.add, isDark, onTap: () => _showComingSoon('Manual Log')),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeInfo(String label, String time, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
        const SizedBox(height: 4),
        Text(time, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
      ],
    );
  }

  Widget _buildSmallIconButton(IconData icon, bool isDark, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? Colors.white38 : Colors.black38, size: 20),
      ),
    );
  }

  Widget _buildHistoryItem(FastingSession h, bool isDark) {
    final dateStr = DateFormat('MMMM d — h:mm a').format(h.startTime);
    final duration = h.elapsedDuration;
    final durationStr = '${duration.inHours}h ${duration.inMinutes % 60}m';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ] : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              durationStr, 
              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${h.targetHours == 0 ? 'Open' : '${h.targetHours}:12'} Fast', 
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  dateStr, 
                  style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12)
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: isDark ? Colors.white10 : Colors.black12),
            onSelected: (val) {
              if (val == 'delete') {
                _showDeleteConfirmation(h);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(FastingSession h) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Delete Log?'),
        content: const Text('This will permanently remove this fasting session from your history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _service.deleteSession(h.id!);
              if (mounted) Navigator.pop(context);
              _loadData();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fasting Timer', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              IconButton(
                onPressed: () => setState(() {
                  _showSetup = false;
                  _selectedPreset = null;
                }),
                icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                style: IconButton.styleFrom(backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Choose a fasting window to start tracking.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final preset = _presets[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedPreset = preset;
                      _showSetup = true;
                    }),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        boxShadow: !isDark ? [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                        ] : null,
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(preset['label'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                              Text(preset['sub'], style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
                            ],
                          ),
                          const Spacer(),
                          Text(preset['desc'], style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 12),
                          Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final endTime = _startTime.add(Duration(hours: _selectedPreset!['hours']));
    final timeFormat = DateFormat('h:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fasting Timer', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              IconButton(
                onPressed: () => setState(() {
                  _showSetup = false;
                  _selectedPreset = null;
                }),
                icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                style: IconButton.styleFrom(backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_selectedPreset!['sub']} · ${_selectedPreset!['label']} · ${_selectedPreset!['desc']}', 
                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),
                Text('Start time', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceButton('Now', _isNow(), () => setState(() => _startTime = DateTime.now())),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildChoiceButton('Pick time', !_isNow(), () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_startTime));
                        if (picked != null) {
                          final now = DateTime.now();
                          setState(() => _startTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute));
                        }
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedPreset!['hours'] > 0)
                  Text(
                    'Ends around ${timeFormat.format(endTime)}', 
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w500, fontSize: 13)
                  ),
                const SizedBox(height: 32),
                Text('Repeat', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
                const SizedBox(height: 12),
                _buildRepeatButton('No repeat', 'One-time fast'),
                const SizedBox(height: 12),
                _buildRepeatButton('Every day', 'Auto-restart after eating window'),
                const SizedBox(height: 12),
                _buildRepeatButton('Custom', 'Choose which days to fast'),
                if (_repeatMode == 'Custom') ...[
                  const SizedBox(height: 24),
                  const Text('S', style: TextStyle(color: Colors.white38, fontSize: 14)), 
                  const SizedBox(height: 12),
                  _buildDaySelector(isDark),
                ],
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedPreset = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _service.startFast(
                      hours: _selectedPreset!['hours'],
                      startTime: _startTime,
                      repeatMode: _repeatMode,
                    );
                    _loadData();
                    setState(() => _showSetup = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF333333) : Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text('Start fast', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isNow() {
    return DateTime.now().difference(_startTime).inMinutes.abs() < 2;
  }

  Widget _buildDaySelector(bool isDark) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final weekday = index + 1;
        final isSelected = _selectedDays.contains(weekday);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              if (_selectedDays.length > 1) _selectedDays.remove(weekday);
            } else {
              _selectedDays.add(weekday);
            }
          }),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected 
                  ? (isDark ? const Color(0xFF333333) : Colors.black) 
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.greenAccent : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                days[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.black38),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildChoiceButton(String label, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)) 
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? (isDark ? Colors.white24 : Colors.black26) : (isDark ? Colors.transparent : Colors.black12)),
          boxShadow: !isSelected && !isDark ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Center(child: Text(label, style: TextStyle(color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white60 : Colors.black45), fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _buildRepeatButton(String label, String sub) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _repeatMode == label;
    return InkWell(
      onTap: () => setState(() => _repeatMode = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF333333) : Colors.black.withValues(alpha: 0.05)) 
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.greenAccent : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
          boxShadow: !isSelected && !isDark ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Column(
          children: [
            Text(
              label, 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: isDark ? Colors.white : Colors.black
              )
            ),
            const SizedBox(height: 4),
            Text(
              sub, 
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black45, 
                fontSize: 13
              )
            ),
          ],
        ),
      ),
    );
  }
}
