import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:installed_apps/app_info.dart' as installed_app;
import 'package:installed_apps/installed_apps.dart';
import 'package:more_security/models/app_info.dart';

class AppScannerService {
  static const String _isolatePortName = 'app_scanner_isolate';
  bool _isScanning = false;

  // Método para obtener todas las aplicaciones instaladas usando Isolate
  Future<List<AppInfo>> getInstalledApps() async {
    if (_isScanning) {
      throw Exception('Un escaneo ya está en progreso');
    }

    try {
      _isScanning = true;

      // En una implementación real, usamos un Isolate para no bloquear la UI
      return await compute(_scanInstalledApps, null);
    } catch (e) {
      debugPrint('Error al escanear aplicaciones: $e');
      return []; // Devolver lista vacía en caso de error
    } finally {
      _isScanning = false;
    }
  }

  // Método para analizar una aplicación específica
  Future<AppInfo> analyzeApp(String packageName) async {
    try {
      final appInfoList = await getInstalledApps();
      final appInfo = appInfoList.firstWhere(
        (app) => app.packageName == packageName,
        orElse: () => throw Exception('Aplicación no encontrada: $packageName'),
      );

      // Análisis detallado de la aplicación usando Isolate
      return await compute(_detailedAppAnalysis, appInfo);
    } catch (e) {
      debugPrint('Error al analizar aplicación: $e');
      rethrow; // Propagar el error para manejo superior
    }
  }

  // Función para usar en Isolate - escanea las aplicaciones instaladas
  static Future<List<AppInfo>> _scanInstalledApps(void _) async {
    try {
      List<installed_app.AppInfo> installedApps =
          await InstalledApps.getInstalledApps(true, true);

      return installedApps.map((app) => _convertToAppInfo(app)).toList();
    } catch (e) {
      debugPrint('Error en Isolate al escanear aplicaciones: $e');
      return [];
    }
  }

  // Función para usar en Isolate - análisis detallado de una app
  static Future<AppInfo> _detailedAppAnalysis(AppInfo appInfo) async {
    try {
      // Aquí iría el código real de análisis detallado
      // Por ahora, simulamos un análisis

      final permissions = await _getAppPermissions(appInfo.packageName);

      // Calculamos el riesgo basado en los permisos
      final riskScore = _calculateRiskScore(permissions);

      return AppInfo(
        packageName: appInfo.packageName,
        appName: appInfo.appName,
        versionName: appInfo.versionName,
        versionCode: appInfo.versionCode,
        isSystemApp: appInfo.isSystemApp,
        iconPath: appInfo.iconPath,
        installTime: appInfo.installTime,
        updateTime: appInfo.updateTime,
        permissions: permissions,
        riskScore: riskScore,
      );
    } catch (e) {
      debugPrint('Error en análisis detallado: $e');
      rethrow;
    }
  }

  // Convierte AppInfo de installed_apps a nuestro modelo AppInfo
  static AppInfo _convertToAppInfo(installed_app.AppInfo app) {
    // El cálculo del riesgo sería más complejo en una implementación real
    final riskScore =
        app.packageName.contains('system')
            ? 2.0
            : (app.packageName.contains('com.android')
                ? 3.5
                : _randomRiskScore());

    return AppInfo(
      packageName: app.packageName ?? 'unknown',
      appName: app.name ?? 'Unknown App',
      versionName: app.versionName ?? '1.0',
      versionCode: app.versionCode ?? 1,
      isSystemApp: app.packageName.contains('com.android') ?? false,
      iconPath: null, // En una implementación real, obtendríamos el ícono
      installTime: DateTime.now().subtract(const Duration(days: 30)),
      updateTime: DateTime.now().subtract(const Duration(days: 5)),
      permissions: [], // Se llenaría en un análisis detallado
      riskScore: riskScore,
    );
  }

  // Obtiene los permisos de una aplicación
  static Future<List<String>> _getAppPermissions(String packageName) async {
    // En una implementación real, obtendríamos los permisos reales
    // Por ahora, simulamos algunos permisos típicos
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

  // Genera un valor aleatorio para la simulación
  static double _randomRiskScore() {
    return (DateTime.now().millisecond % 10) / 10 * 9 + 1;
  }
}
