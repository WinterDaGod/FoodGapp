import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fasting_session.dart';
import '../services/fasting_service.dart';
import 'widgets/app_loading.dart';

class FastingCalendarScreen extends StatefulWidget {
  const FastingCalendarScreen({super.key});

  @override
  State<FastingCalendarScreen> createState() => _FastingCalendarScreenState();
}

class _FastingCalendarScreenState extends State<FastingCalendarScreen> {
  final _service = FastingService();
  DateTime _focusedMonth = DateTime.now();
  List<FastingSession> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final history = await _service.getHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  void _prevMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
  });

  void _nextMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
  });

  void _jumpToToday() => setState(() {
    _focusedMonth = DateTime.now();
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF2EFE4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isLoading 
                ? const AppLoading() 
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildCalendarCard(isDark),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Fasting Calendar',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
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

  Widget _buildCalendarCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
        ] : null,
      ),
      child: Column(
        children: [
          _buildMonthNavigation(isDark),
          const SizedBox(height: 24),
          _buildWeekdayHeader(isDark),
          const SizedBox(height: 16),
          _buildCalendarGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation(bool isDark) {
    final monthStr = DateFormat('MMMM yyyy').format(_focusedMonth);
    return Row(
      children: [
        Expanded(
          child: Text(
            monthStr,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          ),
        ),
        IconButton(
          onPressed: _prevMonth,
          icon: Icon(Icons.chevron_left, color: isDark ? Colors.white60 : Colors.black45),
        ),
        TextButton(
          onPressed: _jumpToToday,
          child: Text('Today', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: Icon(Icons.chevron_right, color: isDark ? Colors.white60 : Colors.black45),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(bool isDark) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: [
        ...days.map((d) => Expanded(
          child: Center(
            child: Text(
              d,
              style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        )),
        const SizedBox(width: 48), // Space for "Week" column
      ],
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    
    // Day of week for the 1st (Mon=1, ..., Sun=7)
    int firstWeekday = firstDayOfMonth.weekday;
    
    // Previous month filler days
    final prevMonthLastDay = DateTime(_focusedMonth.year, _focusedMonth.month, 0).day;
    final List<Widget> dayWidgets = [];
    
    for (int i = firstWeekday - 1; i > 0; i--) {
      dayWidgets.add(_buildDayCell(prevMonthLastDay - i + 1, isCurrentMonth: false, isDark: isDark));
    }
    
    // Current month days
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, i);
      dayWidgets.add(_buildDayCell(i, date: date, isCurrentMonth: true, isDark: isDark));
    }
    
    // Next month filler days
    int remaining = 7 - (dayWidgets.length % 7);
    if (remaining < 7) {
      for (int i = 1; i <= remaining; i++) {
        dayWidgets.add(_buildDayCell(i, isCurrentMonth: false, isDark: isDark));
      }
    }

    // Split into weeks
    final List<Widget> weekRows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      final weekDays = dayWidgets.sublist(i, i + 7);
      
      // Calculate week stats (placeholder 0/7)
      weekRows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              ...weekDays,
              _buildWeekStatCard(isDark),
            ],
          ),
        ),
      );
    }

    return Column(children: weekRows);
  }

  Widget _buildDayCell(int day, {DateTime? date, bool isCurrentMonth = true, required bool isDark}) {
    bool hasFast = false;
    bool isToday = false;
    
    if (date != null) {
      isToday = DateUtils.isSameDay(date, DateTime.now());
      hasFast = _history.any((session) => DateUtils.isSameDay(session.startTime, date));
    }

    return Expanded(
      child: Center(
        child: Column(
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14, 
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday 
                    ? Colors.greenAccent 
                    : (isCurrentMonth ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white10 : Colors.black12)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasFast ? Colors.greenAccent : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  width: 2,
                ),
                color: hasFast ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStatCard(bool isDark) {
    return Container(
      width: 48,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
      ),
      child: const Center(
        child: Text(
          '0/7',
          style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: !isDark ? [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, -10))
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: () {}, // Share functionality placeholder
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
        child: const Text('Share', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
