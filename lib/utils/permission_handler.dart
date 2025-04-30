import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPermissionHandler {
  static const String _permissionRequestedKey = 'permission_requested';

  // Método para comprobar y solicitar permisos básicos con caché
  static Future<bool> checkAndRequestBasicPermissions(
    BuildContext context,
  ) async {
    // Permisos básicos necesarios para la aplicación
    final permissionsToCheck = [
      Permission.storage, // Para acceder a archivos
    ];

    try {
      // Verificar el estado de cada permiso
      Map<Permission, PermissionStatus> statuses = {};
      for (var permission in permissionsToCheck) {
        statuses[permission] = await permission.status;
      }

      // Si algún permiso no está concedido, solicitarlos todos juntos
      List<Permission> permissionsToRequest = [];
      for (var entry in statuses.entries) {
        if (entry.value != PermissionStatus.granted) {
          permissionsToRequest.add(entry.key);
        }
      }

      if (permissionsToRequest.isNotEmpty) {
        // Verificar si ya se mostró el diálogo explicativo antes
        final prefs = await SharedPreferences.getInstance();
        final permissionRequested =
            prefs.getBool(_permissionRequestedKey) ?? false;

        bool shouldProceed = true;
        if (!permissionRequested) {
          // Mostrar diálogo explicativo antes de solicitar permisos
          shouldProceed =
              await _showPermissionExplanationDialog(context) ?? false;
          await prefs.setBool(_permissionRequestedKey, true);
        }

        if (!shouldProceed) {
          return false;
        }

        // Solicitar los permisos necesarios
        Map<Permission, PermissionStatus> results = {};
        for (var permission in permissionsToRequest) {
          results[permission] = await permission.request();
        }

        // Verificar si todos fueron concedidos
        bool allGranted = true;
        bool hasPermanentlyDenied = false;

        for (var entry in results.entries) {
          if (entry.value != PermissionStatus.granted) {
            allGranted = false;
            if (entry.value == PermissionStatus.permanentlyDenied) {
              hasPermanentlyDenied = true;
            }
          }
        }

        if (!allGranted) {
          // Si algún permiso fue denegado permanentemente, mostrar diálogo para ir a configuración
          if (hasPermanentlyDenied) {
            await _showPermanentlyDeniedDialog(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Se requieren permisos para el funcionamiento completo',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return false;
        }

        return true;
      }

      // Todos los permisos ya estaban concedidos
      return true;
    } catch (e) {
      debugPrint('Error al manejar permisos: $e');
      return false;
    }
  }

  // Método para verificar permisos específicos según la tarea
  static Future<bool> checkTaskSpecificPermission(
    Permission permission,
    BuildContext context,
    String explanation,
  ) async {
    try {
      final status = await permission.status;

      if (status != PermissionStatus.granted) {
        // Mostrar explicación específica
        final shouldProceed =
            await _showCustomPermissionDialog(context, explanation) ?? false;

        if (!shouldProceed) {
          return false;
        }

        final result = await permission.request();

        if (result != PermissionStatus.granted) {
          if (result == PermissionStatus.permanentlyDenied) {
            await _showPermanentlyDeniedDialog(context);
          }
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error al verificar permiso específico: $e');
      return false;
    }
  }

  // Diálogo explicativo para permisos
  static Future<bool?> _showPermissionExplanationDialog(
    BuildContext context,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Permisos necesarios'),
          content: const Text(
            'Para que More Security pueda proteger su dispositivo, necesitamos acceder a sus archivos y aplicaciones instaladas. '
            'Todos los escaneos se realizan localmente en su dispositivo y respetan su privacidad.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Continuar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  // Diálogo personalizado para permisos específicos
  static Future<bool?> _showCustomPermissionDialog(
    BuildContext context,
    String explanation,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Permiso requerido'),
          content: Text(explanation),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Conceder'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  // Diálogo para permisos denegados permanentemente
  static Future<void> _showPermanentlyDeniedDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Permisos requeridos'),
          content: const Text(
            'Algunos permisos necesarios fueron denegados permanentemente. '
            'Por favor, habilítelos manualmente en la configuración de su dispositivo para que la aplicación funcione correctamente.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Ir a Configuración'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }
}
