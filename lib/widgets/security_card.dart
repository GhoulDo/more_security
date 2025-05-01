import 'package:flutter/material.dart';

class SecurityCard extends StatelessWidget {
  final String title;
  final String description;
  final dynamic icon; // Puede ser String (ruta de asset) o IconData
  final Color color;
  final VoidCallback onTap;

  const SecurityCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildIcon(color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // Método para manejar diferentes tipos de iconos
  Widget _buildIcon(Color color) {
    if (icon is String) {
      // Es una ruta de asset, intentar cargarla
      try {
        return Image.asset(
          icon as String,
          width: 28,
          height: 28,
          color: color,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              _getDefaultIcon(title.toLowerCase()),
              color: color,
              size: 28,
            );
          },
        );
      } catch (e) {
        return Icon(
          _getDefaultIcon(title.toLowerCase()),
          color: color,
          size: 28,
        );
      }
    } else if (icon is IconData) {
      // Es un IconData, usarlo directamente
      return Icon(icon as IconData, color: color, size: 28);
    } else {
      // Tipo no compatible, usar icono predeterminado
      return Icon(_getDefaultIcon(title.toLowerCase()), color: color, size: 28);
    }
  }

  // Determinar un ícono predeterminado según el título
  IconData _getDefaultIcon(String title) {
    if (title.contains('aplicaci')) return Icons.apps;
    if (title.contains('vulnerabil')) return Icons.warning;
    if (title.contains('archivo')) return Icons.folder;
    if (title.contains('escan')) return Icons.search;
    if (title.contains('segur')) return Icons.security;
    return Icons.shield;
  }
}
