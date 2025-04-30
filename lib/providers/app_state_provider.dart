import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppStateProvider with ChangeNotifier {
  // Estados generales de la aplicación
  bool _isScanning = false;
  int _securityScore = 0;
  bool _isFirstRun = true;
  Map<String, dynamic> _lastScanResults = {};

  // Getters
  bool get isScanning => _isScanning;
  int get securityScore => _securityScore;
  bool get isFirstRun => _isFirstRun;
  Map<String, dynamic> get lastScanResults => _lastScanResults;

  // Constructor
  AppStateProvider() {
    _loadState();
  }

  // Cargar estado guardado
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _securityScore = prefs.getInt('security_score') ?? 75;
      _isFirstRun = prefs.getBool('is_first_run') ?? true;

      // Si hay resultados guardados, cargarlos
      final resultsJson = prefs.getString('last_scan_results');
      if (resultsJson != null) {
        // En una implementación real convertiríamos de JSON a Map
        _lastScanResults = {'timestamp': DateTime.now().toIso8601String()};
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar el estado: $e');
    }
  }

  // Guardar estado actual
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('security_score', _securityScore);
      await prefs.setBool('is_first_run', _isFirstRun);

      // En una implementación real, convertiríamos a JSON
      if (_lastScanResults.isNotEmpty) {
        await prefs.setString('last_scan_results', _lastScanResults.toString());
      }
    } catch (e) {
      debugPrint('Error al guardar el estado: $e');
    }
  }

  // Actualizar estado de escaneo
  void setScanning(bool scanning) {
    _isScanning = scanning;
    notifyListeners();
  }

  // Actualizar puntuación de seguridad
  void updateSecurityScore(int score) {
    _securityScore = score;
    _saveState();
    notifyListeners();
  }

  // Actualizar resultados de último escaneo
  void updateLastScanResults(String scanType, dynamic results) {
    _lastScanResults = {
      'type': scanType,
      'timestamp': DateTime.now().toIso8601String(),
      'results': results,
    };
    _saveState();
    notifyListeners();
  }

  // Marcar app como ya iniciada anteriormente
  void completeFirstRun() {
    _isFirstRun = false;
    _saveState();
    notifyListeners();
  }

  // Limpia la caché y datos guardados
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_scan_results');
      _lastScanResults = {};
      notifyListeners();
    } catch (e) {
      debugPrint('Error al limpiar la caché: $e');
    }
  }
}
