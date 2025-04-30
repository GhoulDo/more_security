import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ErrorHandler {
  static const String _errorLogKey = 'error_log';
  static List<String> _errorLog = [];
  static bool _isInitialized = false;
  static late SharedPreferences _prefs;

  // Inicializa el manejador de errores
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Configurar manejo global de errores
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError('Flutter Error', details.exception, details.stack);

      if (kReleaseMode) {
        // En modo release, podríamos enviar el error a un servicio
        // como Firebase Crashlytics o similar
      }
    };

    // Manejar errores async no capturados
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError('Platform Error', error, stack);
      return true;
    };

    // Inicializar almacenamiento para logs
    _prefs = await SharedPreferences.getInstance();
    _loadErrorLog();

    _isInitialized = true;
  }

  // Registra un error en el log
  static void _logError(String type, dynamic error, StackTrace? stack) {
    final timestamp = DateTime.now().toIso8601String();
    final errorMessage =
        '$timestamp - $type: $error\n${stack.toString().substring(0, 500)}...';

    _errorLog.add(errorMessage);

    // Limitar el tamaño del log para no ocupar demasiado espacio
    if (_errorLog.length > 100) {
      _errorLog.removeAt(0);
    }

    // Guardar en storage
    _saveErrorLog();

    // Log para desarrollo
    debugPrint('ERROR CAPTURADO: $errorMessage');
  }

  // Guarda el log de errores en SharedPreferences
  static Future<void> _saveErrorLog() async {
    await _prefs.setStringList(_errorLogKey, _errorLog);
  }

  // Carga el log de errores desde SharedPreferences
  static void _loadErrorLog() {
    final savedLog = _prefs.getStringList(_errorLogKey);
    if (savedLog != null) {
      _errorLog = savedLog;
    }
  }

  // Limpia el log de errores
  static Future<void> clearErrorLog() async {
    _errorLog = [];
    await _prefs.remove(_errorLogKey);
  }

  // Obtiene el log de errores
  static List<String> getErrorLog() {
    return List.from(_errorLog);
  }

  // Construye un widget para mostrar cuando ocurre un error
  static Widget buildErrorWidget(
    BuildContext context,
    FlutterErrorDetails details,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Oops, algo salió mal',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'La aplicación encontró un problema inesperado.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  // Intenta regresar a la pantalla anterior
                  Navigator.canPop(context)
                      ? Navigator.pop(context)
                      : Navigator.pushReplacementNamed(context, '/');
                },
                child: const Text('Volver'),
              ),
              if (!kReleaseMode)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    details.exception.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
