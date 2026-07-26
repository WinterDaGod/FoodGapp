import 'package:flutter/material.dart';

class NutrientCircle extends StatelessWidget {
  final double progress;
  final IconData icon;
  final Color color;
  final double size;

  const NutrientCircle({
    super.key,
    required this.progress,
    required this.icon,
    required this.color,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? color.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.01, 1.0), // Show a tiny bit even if 0 for "gauge" look
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Icon(icon, color: color, size: size * 0.4),
        ],
      ),
    );
  }
}

class CalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Map<String, double> dailyCalorieProgress;

  const CalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.dailyCalorieProgress = const {},
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 3));

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final date = start.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          final isFuture = date.isAfter(now) && !DateUtils.isSameDay(date, now);
          final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final progress = dailyCalorieProgress[dateStr] ?? 0.0;
          final dayName = _getDayName(date.weekday);

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 54,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDateCircle(date, isSelected, isFuture, progress, isDark),
                  const SizedBox(height: 6),
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected 
                          ? (isDark ? Colors.blueAccent : Colors.blue) 
                          : (isDark ? Colors.white38 : Colors.black38),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateCircle(DateTime date, bool isSelected, bool isFuture, double progress, bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isFuture 
          ? null // We use custom paint or specific border for future
          : Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isFuture)
            CustomPaint(
              size: const Size(44, 44),
              painter: DashedCirclePainter(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)
              ),
            ),
          if (!isFuture && progress > 0)
            SizedBox(
              width: 40,
              height: 40,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value,
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(
                      progress >= 1.0 ? Colors.greenAccent : Colors.greenAccent.withValues(alpha: 0.7)
                    ),
                    backgroundColor: Colors.transparent,
                    strokeCap: StrokeCap.round,
                  );
                },
              ),
            ),
          Text(
            '${date.day}',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}

class MacroCardSmall extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final IconData icon;
  final Color color;
  final bool isOver;

  const MacroCardSmall({
    super.key,
    required this.label,
    required this.value,
    required this.progress,
    required this.icon,
    required this.color,
    this.isOver = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isOver ? Colors.redAccent : color;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isExtraSmall = constraints.maxWidth < 100;
        
        return RepaintBoundary(
          child: Container(
            padding: EdgeInsets.all(isExtraSmall ? 10 : 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  activeColor.withValues(alpha: isDark ? 0.1 : 0.15),
                  activeColor.withValues(alpha: isDark ? 0.02 : 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? activeColor.withValues(alpha: 0.1) : activeColor.withValues(alpha: 0.05)),
              boxShadow: !isDark ? [
                BoxShadow(color: activeColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
              ] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value, 
                    style: TextStyle(
                      fontSize: isExtraSmall ? 16 : 20, 
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Text(
                  label, 
                  style: TextStyle(
                    fontSize: isExtraSmall ? 9 : 11, 
                    color: isDark ? activeColor : activeColor.withValues(alpha: 0.8),
                    fontWeight: isDark ? FontWeight.normal : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Center(
                  child: NutrientCircle(
                    progress: progress,
                    icon: icon,
                    color: activeColor,
                    size: isExtraSmall ? 35 : 45,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const double dashWidth = 3;
    const double dashSpace = 3;
    double startAngle = 0;

    while (startAngle < 2 * 3.14159) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        dashWidth / radius,
        false,
        paint,
      );
      startAngle += (dashWidth + dashSpace) / radius;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
