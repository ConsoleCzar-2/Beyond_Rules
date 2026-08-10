import 'package:flutter/material.dart';

class ChartPainter extends CustomPainter {
  final Color color;

  ChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Simple wavy line
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.3,
      size.width * 0.5, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.8,
      size.width, size.height * 0.4,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
