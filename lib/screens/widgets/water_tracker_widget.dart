import 'package:flutter/material.dart';
import '../../services/database_helper.dart';

class WaterTrackerWidget extends StatefulWidget {
  final String userId;
  final String date;

  const WaterTrackerWidget({
    super.key,
    required this.userId,
    required this.date,
  });

  @override
  State<WaterTrackerWidget> createState() => _WaterTrackerWidgetState();
}

class _WaterTrackerWidgetState extends State<WaterTrackerWidget> {
  int _currentAmount = 0;
  final int _goalAmount = 2500;
  final _db = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadWater();
  }

  @override
  void didUpdateWidget(WaterTrackerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _loadWater();
    }
  }

  Future<void> _loadWater() async {
    final amount = await _db.getWaterIntake(widget.userId, widget.date);
    if (mounted) {
      setState(() => _currentAmount = amount);
    }
  }

  void _updateAmount(int delta) async {
    final newAmount = (_currentAmount + delta).clamp(0, 10000);
    setState(() => _currentAmount = newAmount);
    await _db.updateWaterIntake(widget.userId, widget.date, newAmount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_currentAmount / _goalAmount).clamp(0.0, 1.0);
    
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hydration',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$_currentAmount',
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' / $_goalAmount ml',
                          style: TextStyle(
                            color: isDark ? Colors.white24 : Colors.black26,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _buildWaterIcon(progress, isDark),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildActionButton(Icons.remove, () => _updateAmount(-250), isDark),
              const SizedBox(width: 16),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 12,
                        backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              _buildActionButton(Icons.add, () => _updateAmount(250), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIcon(double progress, bool isDark) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: isDark ? 0.1 : 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: progress),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
          builder: (context, val, child) {
            return Transform.scale(
              scale: 0.9 + (val * 0.3),
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.blueAccent,
                      Colors.blueAccent.withValues(alpha: 0.2),
                    ],
                    stops: [val, val],
                  ).createShader(bounds);
                },
                child: const Icon(
                  Icons.water_drop, 
                  color: Colors.white, 
                  size: 28
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 20),
      ),
    );
  }
}
