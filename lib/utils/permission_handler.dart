import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPermissionHandler {
  static const String _permissionRequestedKey = 'permission_requested';

  // Método para comprobar y solicitar permisos básicos con caché
  static Future<bool> checkAndRequestBasicPermissions(
    BuildContext context,
  ) async {
    // Lista completa de permisos necesarios para la aplicación
    final permissionsToCheck = [
      Permission.storage, // Para acceder a archivos
      Permission.manageExternalStorage, // Necesario en Android 11+
      Permission.photos, // Acceso a galería
      Permission.requestInstallPackages, // Para verificar instalaciones
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

        // Solicitar los permisos uno por uno para mejor control
        bool allGranted = true;
        bool hasPermanentlyDenied = false;

        for (var permission in permissionsToRequest) {
          final status = await permission.request();

          if (status != PermissionStatus.granted) {
            allGranted = false;

            if (status == PermissionStatus.permanentlyDenied) {
              hasPermanentlyDenied = true;
              // Ir a configuración inmediatamente por cada permiso denegado permanentemente
              if (await _showPermissionDeniedDialog(context, permission)) {
                await openAppSettings();
              }
              return false; // Interrumpir el proceso si un permiso es permanentemente denegado
            } else if (status == PermissionStatus.denied) {
              // Para permisos denegados pero no permanentemente, mostrar información
              _showPermissionRequiredSnackbar(context, permission);
            }
          }
        }

        // Si algún permiso no se concedió, pero no es permanente, mostrar mensaje general
        if (!allGranted && !hasPermanentlyDenied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Se requieren permisos para el funcionamiento completo',
                ),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Configuración',
                  onPressed: () async {
                    await openAppSettings();
                  },
                ),
              ),
            );
          }
          return false;
        }

        return allGranted;
      }

      // Todos los permisos ya estaban concedidos
      return true;
    } catch (e) {
      debugPrint('Error al manejar permisos: $e');
      return false;
    }
  }

  // Mostrar información sobre el permiso específico requerido
  static void _showPermissionRequiredSnackbar(
    BuildContext context,
    Permission permission,
  ) {
    String permissionName = _getPermissionFriendlyName(permission);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('El permiso de $permissionName es necesario'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Conceder',
          onPressed: () async {
            await permission.request();
          },
        ),
      ),
    );
  }

  // Obtener nombre amigable para el permiso
  static String _getPermissionFriendlyName(Permission permission) {
    if (permission == Permission.storage) return 'almacenamiento';
    if (permission == Permission.manageExternalStorage)
      return 'administrar archivos';
    if (permission == Permission.photos) return 'fotos';
    if (permission == Permission.requestInstallPackages)
      return 'instalar aplicaciones';
    return 'aplicación';
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
            'Todos los escaneos se realizan localmente en su dispositivo y respetan su privacidad.\n\n'
            'Por favor, conceda todos los permisos solicitados para una experiencia completa.',
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

  // Diálogo para permisos denegados específicos
  static Future<bool> _showPermissionDeniedDialog(
    BuildContext context,
    Permission permission,
  ) async {
    String permissionName = _getPermissionFriendlyName(permission);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Permiso requerido'),
              content: Text(
                'El permiso de $permissionName es necesario para que la aplicación funcione correctamente.\n\n'
                'Por favor, active este permiso en la configuración de su dispositivo.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Más tarde'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Ir a Configuración'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
