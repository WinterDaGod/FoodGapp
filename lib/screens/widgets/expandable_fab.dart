import 'package:flutter/material.dart';

@immutable
class ExpandableFab extends StatelessWidget {
  const ExpandableFab({
    super.key,
    required this.isOpen,
    required this.onTap,
    required this.distance,
    required this.children,
  });

  final bool isOpen;
  final VoidCallback onTap;
  final double distance;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 36,
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1), 
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Center(
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: isOpen ? 0.125 : 0, // Morph from + to x (45 degrees)
                  child: Icon(
                    Icons.add, 
                    color: isDark ? Colors.white : Colors.black, 
                    size: 32
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
