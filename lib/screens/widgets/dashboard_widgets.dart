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
    
    return Stack(
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
    );
  }
}

class CalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const CalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 3));

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = start.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          final dayName = _getDayName(date.weekday);

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: isSelected 
                    ? Border.all(color: isDark ? Colors.white24 : Colors.black.withValues(alpha: 0.05)) 
                    : null,
                boxShadow: isSelected && !isDark ? [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? (isDark ? Colors.white : Colors.black) 
                            : (isDark ? Colors.white12 : Colors.black12),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected 
                          ? (isDark ? Colors.white : Colors.black) 
                          : (isDark ? Colors.white38 : Colors.black38),
                      fontSize: 12,
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
        
        return Container(
          padding: EdgeInsets.all(isExtraSmall ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                activeColor.withValues(alpha: isDark ? 0.1 : 0.15),
                activeColor.withValues(alpha: isDark ? 0.02 : 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
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
                    fontSize: isExtraSmall ? 18 : 22, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Text(
                label, 
                style: TextStyle(
                  fontSize: isExtraSmall ? 10 : 12, 
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
                  size: isExtraSmall ? 40 : 50,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
