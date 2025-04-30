import 'dart:async';

import '../models/scanned_file.dart';

class FileScannerService {
  // Método para escanear archivos del dispositivo
  Future<List<ScannedFile>> scanFiles() async {
    // En una implementación real, escanearíamos los archivos del dispositivo
    await Future.delayed(const Duration(seconds: 4));

    // Simulamos los resultados
    return [
      ScannedFile(
        filePath: '/storage/emulated/0/Download/document.pdf',
        fileName: 'document.pdf',
        fileExtension: 'pdf',
        fileSize: 2500000,
        lastModified: DateTime.now().subtract(const Duration(days: 5)),
        riskLevel: FileRiskLevel.safe,
        reasons: ['El archivo ha sido analizado y no contiene amenazas.'],
      ),
      ScannedFile(
        filePath: '/storage/emulated/0/Download/presentation.ppt',
        fileName: 'presentation.ppt',
        fileExtension: 'ppt',
        fileSize: 5000000,
        lastModified: DateTime.now().subtract(const Duration(days: 10)),
        riskLevel: FileRiskLevel.suspicious,
        reasons: [
          'El archivo contiene macros que podrían ser potencialmente peligrosas.',
        ],
      ),
      ScannedFile(
        filePath: '/storage/emulated/0/Download/unknown_app.apk',
        fileName: 'unknown_app.apk',
        fileExtension: 'apk',
        fileSize: 15000000,
        lastModified: DateTime.now().subtract(const Duration(days: 1)),
        riskLevel: FileRiskLevel.malicious,
        detectionName: 'Android.Trojan.FakeApp',
        reasons: [
          'El archivo contiene código malicioso.',
          'La aplicación solicita permisos excesivos.',
          'Intenta acceder a información sensible.',
        ],
      ),
      ScannedFile(
        filePath: '/storage/emulated/0/Pictures/image.jpg',
        fileName: 'image.jpg',
        fileExtension: 'jpg',
        fileSize: 1200000,
        lastModified: DateTime.now().subtract(const Duration(days: 20)),
        riskLevel: FileRiskLevel.safe,
        reasons: ['El archivo ha sido analizado y no contiene amenazas.'],
      ),
      ScannedFile(
        filePath: '/storage/emulated/0/Download/archive.zip',
        fileName: 'archive.zip',
        fileExtension: 'zip',
        fileSize: 8000000,
        lastModified: DateTime.now().subtract(const Duration(days: 3)),
        riskLevel: FileRiskLevel.unknown,
        reasons: [
          'El archivo está encriptado y no puede ser escaneado completamente.',
        ],
      ),
    ];
  }

  // Método para eliminar un archivo peligroso
  Future<bool> deleteFile(String filePath) async {
    // En una implementación real, eliminaríamos el archivo
    await Future.delayed(const Duration(seconds: 1));

    // Simulamos el resultado (éxito o fracaso)
    return true; // Simula éxito
  }

  // Método para poner en cuarentena un archivo sospechoso
  Future<bool> quarantineFile(String filePath) async {
    // En una implementación real, moveríamos el archivo a cuarentena
    await Future.delayed(const Duration(seconds: 1));

    // Simulamos el resultado (éxito o fracaso)
    return true; // Simula éxito
  }
}
