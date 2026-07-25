import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? iconColor;
  final bool showFrame;

  const AppLogo({
    super.key,
    this.size = 80.0,
    this.iconColor,
    this.showFrame = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showFrame) 
            Positioned.fill(
              child: CustomPaint(
                painter: _LogoFramePainter(),
              ),
            ),
          Icon(
            Icons.restaurant,
            color: iconColor ?? Colors.orange,
            size: size * 0.5,
          ),
        ],
      ),
    );
  }
}

class _LogoFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B5E3C)
      ..strokeWidth = size.width * 0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double padding = size.width * 0.12;
    final double cornerLen = size.width * 0.18;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(padding, padding + cornerLen)
        ..lineTo(padding, padding)
        ..lineTo(padding + cornerLen, padding),
      paint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - cornerLen, padding)
        ..lineTo(size.width - padding, padding)
        ..lineTo(size.width - padding, padding + cornerLen),
      paint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(padding, size.height - padding - cornerLen)
        ..lineTo(padding, size.height - padding)
        ..lineTo(padding + cornerLen, size.height - padding),
      paint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - padding - cornerLen, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding - cornerLen),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
