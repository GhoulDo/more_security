import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static const String _appOpenCountKey = 'app_open_count';
  static const String _scanCountKey = 'scan_count';
  static const String _lastSessionTimeKey = 'last_session_time';

  static bool _isInitialized = false;
  static late SharedPreferences _prefs;
  // Eliminamos la variable no utilizada y usamos un mapa para almacenar todo
  static final Map<String, dynamic> _analytics = {
    'actionTimes': <String, int>{}, // Tiempos de ejecución de acciones
    'screenDurations':
        <String, int>{}, // Duración de visualización de pantallas
    'errorCount': 0, // Contador de errores
  };

  // Inicializar el servicio de analíticas
  static Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _trackAppOpen();

    _isInitialized = true;
  }

  // Registra apertura de la app
  static void _trackAppOpen() {
    final currentCount = _prefs.getInt(_appOpenCountKey) ?? 0;
    _prefs.setInt(_appOpenCountKey, currentCount + 1);
    _prefs.setString(_lastSessionTimeKey, DateTime.now().toIso8601String());
  }

  // Registra un escaneo
  static Future<void> trackScan(String scanType) async {
    final scanKey = '${_scanCountKey}_$scanType';
    final currentCount = _prefs.getInt(scanKey) ?? 0;
    await _prefs.setInt(scanKey, currentCount + 1);
  }

  // Comienza a medir el tiempo de una acción
  static void startMeasuringAction(String actionName) {
    _analytics['actionTimes'][actionName] =
        DateTime.now().millisecondsSinceEpoch;
  }

  // Finaliza la medición y registra el tiempo
  static void endMeasuringAction(String actionName) {
    final startTime = _analytics['actionTimes'][actionName] as int?;
    if (startTime != null) {
      final duration = DateTime.now().millisecondsSinceEpoch - startTime;
      debugPrint('Performance: $actionName tomó $duration ms');

      // Almacenar el tiempo para análisis posterior
      if (!_analytics.containsKey('performanceData')) {
        _analytics['performanceData'] = <String, List<int>>{};
      }

      if (!_analytics['performanceData'].containsKey(actionName)) {
        _analytics['performanceData'][actionName] = <int>[];
      }

      _analytics['performanceData'][actionName].add(duration);
      _analytics['actionTimes'].remove(actionName);
    }
  }

  // Registrar un error para análisis
  static void trackError(String errorType, String errorMessage) {
    _analytics['errorCount'] = (_analytics['errorCount'] as int) + 1;

    if (!_analytics.containsKey('errors')) {
      _analytics['errors'] = <Map<String, String>>[];
    }

    _analytics['errors'].add({
      'type': errorType,
      'message': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Obtiene el observador de navegación para analíticas
  static NavigatorObserver getNavigationObserver() {
    return _AnalyticsNavigatorObserver();
  }

  // Obtener estadísticas de uso
  static Future<Map<String, dynamic>> getUsageStats() async {
    final stats = {
      'appOpenCount': _prefs.getInt(_appOpenCountKey) ?? 0,
      'appScanCount': _prefs.getInt('${_scanCountKey}_app') ?? 0,
      'fileScanCount': _prefs.getInt('${_scanCountKey}_file') ?? 0,
      'vulnerabilityScanCount':
          _prefs.getInt('${_scanCountKey}_vulnerability') ?? 0,
      'completeScanCount': _prefs.getInt('${_scanCountKey}_complete') ?? 0,
      'lastSession': _prefs.getString(_lastSessionTimeKey) ?? 'Nunca',
      'errorCount': _analytics['errorCount'],
    };

    // Añadir datos de rendimiento si existen
    if (_analytics.containsKey('performanceData')) {
      final performanceData =
          _analytics['performanceData'] as Map<String, List<int>>;

      // Calcular tiempos promedio para diferentes acciones
      final averages = <String, double>{};
      performanceData.forEach((key, times) {
        if (times.isNotEmpty) {
          final sum = times.reduce((a, b) => a + b);
          averages[key] = sum / times.length;
        }
      });

      stats['averagePerformance'] = averages;
    }

    return stats;
  }
}

// Observador para registrar cambios de pantallas
class _AnalyticsNavigatorObserver extends NavigatorObserver {
  final Map<String, int> _screenEntryTimes = {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _trackScreenView(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _trackScreenExit(route);
    _trackScreenView(previousRoute);
    super.didPop(route, previousRoute);
  }

  void _trackScreenView(Route<dynamic>? route) {
    if (route != null && route.settings.name != null) {
      final screenName = route.settings.name!;
      _screenEntryTimes[screenName] = DateTime.now().millisecondsSinceEpoch;
      debugPrint('Screen viewed: $screenName');
    }
  }

  void _trackScreenExit(Route<dynamic> route) {
    if (route.settings.name != null) {
      final screenName = route.settings.name!;
      final entryTime = _screenEntryTimes[screenName];

      if (entryTime != null) {
        final viewTime = DateTime.now().millisecondsSinceEpoch - entryTime;
        debugPrint('Screen $screenName viewed for ${viewTime}ms');

        // Aquí podríamos almacenar estos datos en la estructura _analytics
        // para un análisis más completo del uso de la aplicación
        if (!AnalyticsService._analytics.containsKey('screenDurations')) {
          AnalyticsService._analytics['screenDurations'] =
              <String, List<int>>{};
        }

        if (!AnalyticsService._analytics['screenDurations'].containsKey(
          screenName,
        )) {
          AnalyticsService._analytics['screenDurations'][screenName] = <int>[];
        }

        AnalyticsService._analytics['screenDurations'][screenName].add(
          viewTime,
        );
        _screenEntryTimes.remove(screenName);
      }
    }
  }
}
