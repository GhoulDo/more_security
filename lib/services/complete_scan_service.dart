import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:more_security/models/app_info.dart';
import 'package:more_security/models/scanned_file.dart';
import 'package:more_security/models/vulnerability.dart';
import 'package:more_security/services/analytics_service.dart';
import 'package:more_security/services/app_scanner_service.dart';
import 'package:more_security/services/file_scanner_service.dart';
import 'package:more_security/services/vulnerability_scanner_service.dart';

class CompleteScanService {
  final AppScannerService _appScanner = AppScannerService();
  final VulnerabilityScannerService _vulnerabilityScanner =
      VulnerabilityScannerService();
  final FileScannerService _fileScanner = FileScannerService();

  bool _isScanning = false;
  final _progressController = StreamController<ScanProgress>.broadcast();

  // Stream para seguir el progreso del escaneo
  Stream<ScanProgress> get progressStream => _progressController.stream;

  // Iniciar un escaneo completo
  Future<CompleteScanResult> startCompleteScan() async {
    if (_isScanning) {
      throw Exception('Ya hay un escaneo en progreso');
    }

    try {
      _isScanning = true;
      AnalyticsService.startMeasuringAction('complete_scan');

      // Inicializar progreso
      _progressController.add(
        ScanProgress(
          stage: ScanStage.initializing,
          progress: 0.0,
          message: 'Iniciando escaneo completo...',
        ),
      );

      // Crear resultado vacío
      final result = CompleteScanResult(
        appResults: [],
        vulnerabilityResults: [],
        fileResults: [],
        startTime: DateTime.now(),
        endTime: null,
        overallSecurityScore: 0,
      );

      // Etapa 1: Escaneo de aplicaciones (30% del progreso total)
      _progressController.add(
        ScanProgress(
          stage: ScanStage.scanningApps,
          progress: 0.05,
          message: 'Analizando aplicaciones instaladas...',
        ),
      );

      result.appResults = await _appScanner.getInstalledApps();
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Evitar UI bloqueada

      _progressController.add(
        ScanProgress(
          stage: ScanStage.scanningApps,
          progress: 0.3,
          message: 'Análisis de aplicaciones completado',
        ),
      );

      // Etapa 2: Escaneo de vulnerabilidades (30% del progreso total)
      _progressController.add(
        ScanProgress(
          stage: ScanStage.scanningVulnerabilities,
          progress: 0.35,
          message: 'Buscando vulnerabilidades en el sistema...',
        ),
      );

      result.vulnerabilityResults =
          await _vulnerabilityScanner.scanForVulnerabilities();
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Evitar UI bloqueada

      _progressController.add(
        ScanProgress(
          stage: ScanStage.scanningVulnerabilities,
          progress: 0.6,
          message: 'Análisis de vulnerabilidades completado',
        ),
      );

      // Etapa 3: Escaneo de archivos (30% del progreso total)
      _progressController.add(
        ScanProgress(
          stage: ScanStage.scanningFiles,
          progress: 0.65,
          message: 'Analizando archivos en busca de malware...',
        ),
      );

      result.fileResults = await _fileScanner.scanFiles();
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Evitar UI bloqueada

      _progressController.add(
        ScanProgress(
          stage: ScanStage.scanningFiles,
          progress: 0.9,
          message: 'Análisis de archivos completado',
        ),
      );

      // Etapa 4: Finalizando y calculando puntuación
      _progressController.add(
        ScanProgress(
          stage: ScanStage.finishing,
          progress: 0.95,
          message: 'Calculando puntuación de seguridad...',
        ),
      );

      // Calcular puntuación general de seguridad
      result.overallSecurityScore = _calculateSecurityScore(result);
      result.endTime = DateTime.now();

      _progressController.add(
        ScanProgress(
          stage: ScanStage.complete,
          progress: 1.0,
          message: 'Escaneo completo finalizado',
        ),
      );

      AnalyticsService.endMeasuringAction('complete_scan');
      await AnalyticsService.trackScan('complete');

      return result;
    } catch (e) {
      debugPrint('Error en escaneo completo: $e');

      _progressController.add(
        ScanProgress(
          stage: ScanStage.error,
          progress: 0.0,
          message: 'Error durante el escaneo: ${e.toString()}',
        ),
      );

      rethrow;
    } finally {
      _isScanning = false;
    }
  }

  // Cálculo de la puntuación de seguridad general
  int _calculateSecurityScore(CompleteScanResult result) {
    // Factores de riesgo basados en resultados
    double appRiskFactor = 0;
    if (result.appResults.isNotEmpty) {
      double totalRisk = 0;
      for (var app in result.appResults) {
        totalRisk += app.riskScore;
      }
      appRiskFactor = totalRisk / result.appResults.length;
    }

    // Calcular factor de riesgo por vulnerabilidades
    int criticalVulnerabilities =
        result.vulnerabilityResults
            .where((v) => v.severity == SeverityLevel.critical)
            .length;
    int highVulnerabilities =
        result.vulnerabilityResults
            .where((v) => v.severity == SeverityLevel.high)
            .length;

    double vulnerabilityRiskFactor =
        criticalVulnerabilities * 10 + highVulnerabilities * 5;

    // Calcular factor de riesgo por archivos maliciosos
    int maliciousFiles =
        result.fileResults
            .where((f) => f.riskLevel == FileRiskLevel.malicious)
            .length;
    int suspiciousFiles =
        result.fileResults
            .where((f) => f.riskLevel == FileRiskLevel.suspicious)
            .length;

    double fileRiskFactor = maliciousFiles * 8 + suspiciousFiles * 3;

    // Calcular puntuación combinada (mayor es peor)
    double combinedRiskScore =
        appRiskFactor * 0.3 +
        vulnerabilityRiskFactor * 0.4 +
        fileRiskFactor * 0.3;

    // Convertir a una escala de 0-100 donde 100 es totalmente seguro
    int securityScore = 100 - min(combinedRiskScore.round(), 100);
    return max(securityScore, 0);
  }

  // Liberar recursos
  void dispose() {
    _progressController.close();
  }

  // Función auxiliar para obtener mínimo de dos números
  int min(int a, int b) => a < b ? a : b;

  // Función auxiliar para obtener máximo de dos números
  int max(int a, int b) => a > b ? a : b;
}

// Etapas del escaneo
enum ScanStage {
  initializing,
  scanningApps,
  scanningVulnerabilities,
  scanningFiles,
  finishing,
  complete,
  error,
}

// Clase para seguimiento del progreso
class ScanProgress {
  final ScanStage stage;
  final double progress; // 0.0 a 1.0
  final String message;

  ScanProgress({
    required this.stage,
    required this.progress,
    required this.message,
  });
}

// Clase para el resultado del escaneo completo
class CompleteScanResult {
  List<AppInfo> appResults;
  List<Vulnerability> vulnerabilityResults;
  List<ScannedFile> fileResults;
  final DateTime startTime;
  DateTime? endTime;
  int overallSecurityScore; // 0-100, donde 100 es completamente seguro

  CompleteScanResult({
    required this.appResults,
    required this.vulnerabilityResults,
    required this.fileResults,
    required this.startTime,
    this.endTime,
    required this.overallSecurityScore,
  });

  // Duración del escaneo
  Duration get duration {
    return endTime != null ? endTime!.difference(startTime) : Duration.zero;
  }

  // Estadísticas del escaneo
  Map<String, dynamic> get statistics {
    return {
      'appsScanned': appResults.length,
      'highRiskApps': appResults.where((app) => app.riskScore >= 7.0).length,
      'vulnerabilities': vulnerabilityResults.length,
      'criticalVulnerabilities':
          vulnerabilityResults
              .where((v) => v.severity == SeverityLevel.critical)
              .length,
      'filesScanned': fileResults.length,
      'maliciousFiles':
          fileResults
              .where((f) => f.riskLevel == FileRiskLevel.malicious)
              .length,
      'securityScore': overallSecurityScore,
      'scanDuration': duration.inSeconds,
    };
  }
}
