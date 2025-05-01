import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:installed_apps/app_info.dart' as installed_app;
import 'package:installed_apps/installed_apps.dart';
import 'package:more_security/models/app_info.dart';
import 'package:permission_handler/permission_handler.dart';

class AppScannerService {
  static const String _isolatePortName = 'app_scanner_isolate';
  bool _isScanning = false;

  // Método para verificar permisos antes de escanear
  Future<bool> _checkPermissions() async {
    final status = await Permission.storage.status;
    if (status != PermissionStatus.granted) {
      final result = await Permission.storage.request();
      return result == PermissionStatus.granted;
    }
    return true;
  }

  // Método para obtener todas las aplicaciones instaladas usando Isolate
  Future<List<AppInfo>> getInstalledApps() async {
    if (_isScanning) {
      throw Exception('Un escaneo ya está en progreso');
    }

    // Verificar permisos primero
    final hasPermission = await _checkPermissions();
    if (!hasPermission) {
      throw Exception('Se requieren permisos para escanear aplicaciones');
    }

    try {
      _isScanning = true;

      // En una implementación real, usamos installed_apps para obtener las apps reales
      List<installed_app.AppInfo> installedApps =
          await InstalledApps.getInstalledApps(true, true);

      // Convertir a nuestro modelo
      List<AppInfo> appInfoList = [];
      for (var app in installedApps) {
        final permissions = await _getAppPermissions(
          app.packageName ?? "unknown",
        );
        final riskScore = _calculateRiskScore(permissions);

        appInfoList.add(
          AppInfo(
            packageName: app.packageName ?? 'unknown',
            appName: app.name ?? 'Unknown App',
            versionName: app.versionName ?? '1.0',
            versionCode: app.versionCode ?? 1,
            isSystemApp: app.packageName.contains('com.android') ?? false,
            iconPath: null, // No tenemos ícono
            installTime: DateTime.now().subtract(
              const Duration(days: 30),
            ), // No tenemos fecha real
            updateTime: DateTime.now().subtract(
              const Duration(days: 5),
            ), // No tenemos fecha real
            permissions: permissions,
            riskScore: riskScore,
          ),
        );
      }

      return appInfoList;
    } catch (e) {
      debugPrint('Error al escanear aplicaciones: $e');
      return []; // Devolver lista vacía en caso de error
    } finally {
      _isScanning = false;
    }
  }

  // Método para analizar una aplicación específica
  Future<AppInfo> analyzeApp(String packageName) async {
    // Verificar permisos primero
    final hasPermission = await _checkPermissions();
    if (!hasPermission) {
      throw Exception('Se requieren permisos para analizar aplicaciones');
    }

    try {
      final appInfoList = await getInstalledApps();
      final appInfo = appInfoList.firstWhere(
        (app) => app.packageName == packageName,
        orElse: () => throw Exception('Aplicación no encontrada: $packageName'),
      );

      return appInfo;
    } catch (e) {
      debugPrint('Error al analizar aplicación: $e');
      rethrow; // Propagar el error para manejo superior
    }
  }

  // Obtiene los permisos de una aplicación - en la implementación real esto usaría
  // una funcionalidad de Android para obtener los permisos reales
  static Future<List<String>> _getAppPermissions(String packageName) async {
    // En una implementación completa, esto debería obtener los permisos reales
    // usando Android PackageManager. Para simplificar, usamos una aproximación.
    await Future.delayed(const Duration(milliseconds: 200));

    if (packageName.contains('system')) {
      return ['android.permission.INTERNET'];
    } else if (packageName.contains('com.android')) {
      return [
        'android.permission.INTERNET',
        'android.permission.ACCESS_NETWORK_STATE',
      ];
    } else {
      return [
        'android.permission.INTERNET',
        'android.permission.CAMERA',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.READ_CONTACTS',
      ];
    }
  }

  // Calcula el nivel de riesgo basado en permisos
  static double _calculateRiskScore(List<String> permissions) {
    int dangerousPermissions = 0;

    for (final permission in permissions) {
      if (permission.contains('LOCATION') ||
          permission.contains('CAMERA') ||
          permission.contains('CONTACTS') ||
          permission.contains('SMS') ||
          permission.contains('CALL_LOG') ||
          permission.contains('RECORD_AUDIO')) {
        dangerousPermissions++;
      }
    }

    return dangerousPermissions * 2.0 + 1.0;
  }
}
