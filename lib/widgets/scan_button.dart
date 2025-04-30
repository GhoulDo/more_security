import 'package:flutter/material.dart';

class ScanButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;

  // Constructor con parámetros requeridos y opcionales
  const ScanButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Usando const donde sea posible para mejorar el rendimiento
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        // Usar el color del tema si no se proporciona uno específico
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.6),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        // Añadir una sombra sutil
        elevation: 2,
      ),
      // Usando Row para alinear icono y texto
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mostrar progreso o icono según el estado
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Icon(icon, size: 22),

          // Espacio entre icono/spinner y texto
          const SizedBox(width: 12),

          // El texto del botón
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
