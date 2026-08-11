import 'package:flutter/material.dart';

class HealthDisclosureModal extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const HealthDisclosureModal({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  static void show(BuildContext context, {required VoidCallback onAccept, required VoidCallback onDecline}) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HealthDisclosureModal(onAccept: onAccept, onDecline: onDecline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(32, 32, 32, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2), 
            blurRadius: 20, 
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.health_and_safety_outlined, color: Colors.blueAccent, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'Data Safety Disclosure',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To provide accurate clinical feedback, FoodGapp requests access to your Health Connect data.',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            _buildBulletItem(
              'Steps & Activity', 
              'Used to calculate your daily energy expenditure against your clinical targets.',
              isDark
            ),
            _buildBulletItem(
              'Active Calories', 
              'Helps adjust your macro requirements in real-time based on physical demand.',
              isDark
            ),
            const SizedBox(height: 24),
            Text(
              'Your data is processed locally on this device and is never sold or shared with third parties.',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDecline();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text('Not Now', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onAccept();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Accept & Sync', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletItem(String title, String desc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.4),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
