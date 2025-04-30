import 'dart:math' as math;

import 'package:flutter/material.dart';

class SecurityStatus extends StatelessWidget {
  final int securityLevel;

  const SecurityStatus({super.key, required this.securityLevel})
    : assert(securityLevel >= 0 && securityLevel <= 100);

  Color _getStatusColor() {
    if (securityLevel >= 75) return const Color(0xFF06D6A0); // Verde
    if (securityLevel >= 50) return const Color(0xFFFFB703); // Amarillo
    return const Color(0xFFE63946); // Rojo
  }

  String _getStatusText() {
    if (securityLevel >= 75) return 'Seguro';
    if (securityLevel >= 50) return 'Atención';
    return 'En riesgo';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: SecurityGaugePainter(
                    securityLevel: securityLevel,
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        securityLevel >= 75
                            ? 'Tu dispositivo está bien protegido'
                            : securityLevel >= 50
                            ? 'Tu dispositivo necesita atención'
                            : 'Tu dispositivo está en riesgo',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: securityLevel / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
              borderRadius: BorderRadius.circular(5),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class SecurityGaugePainter extends CustomPainter {
  final int securityLevel;
  final Color color;

  SecurityGaugePainter({required this.securityLevel, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final backgroundPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8;

    final foregroundPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 8;

    // Dibuja el arco de fondo
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      math.pi * 0.8,
      math.pi * 1.4,
      false,
      backgroundPaint,
    );

    // Dibuja el arco de progreso
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      math.pi * 0.8,
      math.pi * 1.4 * (securityLevel / 100),
      false,
      foregroundPaint,
    );

    // Añade el texto del porcentaje
    final textStyle = TextStyle(
      color: color,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(text: '$securityLevel%', style: textStyle);

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();

    final textOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
