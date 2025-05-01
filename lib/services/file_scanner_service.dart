import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/scanned_file.dart';

class FileScannerService {
  bool _isScanning = false;

  // Verificar permisos antes de escanear
  Future<bool> _checkPermissions() async {
    final status = await Permission.storage.status;
    if (status != PermissionStatus.granted) {
      final result = await Permission.storage.request();
      return result == PermissionStatus.granted;
    }
    return true;
  }

  // Método para escanear archivos del dispositivo
  Future<List<ScannedFile>> scanFiles() async {
    if (_isScanning) {
      throw Exception('Un escaneo ya está en progreso');
    }

    // Verificar permisos primero
    final hasPermission = await _checkPermissions();
    if (!hasPermission) {
      throw Exception('Se requieren permisos para escanear archivos');
    }

    try {
      _isScanning = true;

      // Obtener directorios comunes
      final downloadDir = await getExternalStorageDirectory();
      if (downloadDir == null) {
        throw Exception('No se pudo acceder al almacenamiento');
      }

      // Lista para almacenar resultados
      List<ScannedFile> results = [];

      // Escanear directorio de descargas
      await _scanDirectory(downloadDir.path, results);

      return results;
    } catch (e) {
      debugPrint('Error al escanear archivos: $e');
      return [];
    } finally {
      _isScanning = false;
    }
  }

  // Escanea un directorio recursivamente
  Future<void> _scanDirectory(String dirPath, List<ScannedFile> results) async {
    try {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) return;

      final entities = dir.listSync(recursive: false, followLinks: false);

      for (var entity in entities) {
        if (entity is File) {
          final scannedFile = await _analyzeFile(entity);
          if (scannedFile != null) {
            results.add(scannedFile);
          }
        } else if (entity is Directory) {
          // No escanear directorios del sistema o ocultos
          final dirName = entity.path.split('/').last;
          if (!dirName.startsWith('.') && !_isSystemDirectory(entity.path)) {
            await _scanDirectory(entity.path, results);
          }
        }
      }
    } catch (e) {
      debugPrint('Error al escanear directorio $dirPath: $e');
    }
  }

  // Analiza un archivo individual
  Future<ScannedFile?> _analyzeFile(File file) async {
    try {
      final path = file.path;
      final name = path.split('/').last;
      final extension =
          name.contains('.') ? name.split('.').last.toLowerCase() : '';

      // Ignorar archivos del sistema o muy pequeños
      if (name.startsWith('.') || file.lengthSync() < 100) {
        return null;
      }

      // Determinar nivel de riesgo basado en extensión y contenido
      final riskLevel = _determineRiskLevel(extension, file);
      final reasons = _analyzeFileContent(extension, file);
      String? detectionName;

      if (riskLevel == FileRiskLevel.malicious) {
        detectionName = 'Malicious.${extension.toUpperCase()}.Generic';
      } else if (riskLevel == FileRiskLevel.suspicious) {
        detectionName = null;
      }

      return ScannedFile(
        filePath: path,
        fileName: name,
        fileExtension: extension,
        fileSize: file.lengthSync(),
        lastModified: file.lastModifiedSync(),
        riskLevel: riskLevel,
        detectionName: detectionName,
        reasons: reasons,
      );
    } catch (e) {
      debugPrint('Error al analizar archivo: $e');
      return null;
    }
  }

  // Determina el nivel de riesgo de un archivo
  FileRiskLevel _determineRiskLevel(String extension, File file) {
    // Extensiones potencialmente peligrosas
    if (['exe', 'bat', 'apk', 'sh', 'js', 'vbs'].contains(extension)) {
      // Tamaño sospechoso para APKs
      if (extension == 'apk' && file.lengthSync() < 1024 * 1024) {
        return FileRiskLevel.suspicious;
      }

      // Verificar contenido sospechoso
      try {
        final content = file.readAsBytesSync().take(1024).toList();
        if (_containsMaliciousPatterns(content)) {
          return FileRiskLevel.malicious;
        }
      } catch (e) {
        // Si no podemos leer el archivo, marcarlo como sospechoso
        return FileRiskLevel.suspicious;
      }

      return FileRiskLevel.suspicious;
    }

    // Archivos de documentos comunes
    if ([
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
    ].contains(extension)) {
      try {
        final content = file.readAsBytesSync().take(1024).toList();
        if (_containsMaliciousPatterns(content)) {
          return FileRiskLevel.suspicious;
        }
      } catch (e) {
        return FileRiskLevel.unknown;
      }
    }

    // Archivos multimedia generalmente son seguros
    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'mp3',
      'mp4',
      'avi',
      'mov',
    ].contains(extension)) {
      return FileRiskLevel.safe;
    }

    // Archivos comprimidos - podrían contener cualquier cosa
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(extension)) {
      return FileRiskLevel.unknown;
    }

    // Por defecto, archivos desconocidos se consideran seguros
    return FileRiskLevel.safe;
  }

  // Analiza el contenido del archivo para generar razones
  List<String> _analyzeFileContent(String extension, File file) {
    List<String> reasons = [];

    // Razones basadas en extensión
    if (['exe', 'bat', 'sh'].contains(extension)) {
      reasons.add('Archivo ejecutable que podría contener código malicioso.');
    } else if (extension == 'apk') {
      reasons.add(
        'Aplicación Android que debería instalarse sólo desde fuentes confiables.',
      );
    } else if (['zip', 'rar', '7z'].contains(extension)) {
      reasons.add(
        'Archivo comprimido que podría contener cualquier tipo de archivo.',
      );
    }

    // Razones basadas en tamaño
    final size = file.lengthSync();
    if (size > 50 * 1024 * 1024) {
      reasons.add(
        'Archivo de gran tamaño (${(size / (1024 * 1024)).toStringAsFixed(1)} MB).',
      );
    } else if (size < 1024 && ['exe', 'apk'].contains(extension)) {
      reasons.add('Archivo ejecutable sospechosamente pequeño.');
    }

    // Si no hay razones específicas
    if (reasons.isEmpty) {
      if (_isRisky(extension)) {
        reasons.add(
          'Este tipo de archivo puede presentar riesgos de seguridad.',
        );
      } else {
        reasons.add('Archivo analizado sin amenazas detectadas.');
      }
    }

    return reasons;
  }

  // Verifica si un directorio es del sistema
  bool _isSystemDirectory(String path) {
    final systemDirs = ['Android', 'DCIM', '.thumbnails', 'system', 'data'];
    return systemDirs.any((dir) => path.contains('/$dir/'));
  }

  // Verifica patrones maliciosos en el contenido
  bool _containsMaliciousPatterns(List<int> content) {
    // Esto es una simplificación - en un escáner real se usarían
    // firmas de virus y análisis heurístico más sofisticado
    final contentStr = String.fromCharCodes(content);
    final maliciousPatterns = [
      'virus',
      'trojan',
      'hack',
      'exploit',
      'malware',
      '<script>',
      'CMD.EXE',
      'format C:',
      'system32',
    ];

    return maliciousPatterns.any(
      (pattern) => contentStr.toLowerCase().contains(pattern.toLowerCase()),
    );
  }

  // Verifica si la extensión es considerada riesgosa
  bool _isRisky(String extension) {
    return [
      'exe',
      'bat',
      'cmd',
      'sh',
      'js',
      'vbs',
      'ps1',
      'apk',
      'jar',
    ].contains(extension);
  }

  // Método para eliminar un archivo peligroso
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      await file.delete();
      return true;
    } catch (e) {
      debugPrint('Error al eliminar archivo: $e');
      return false;
    }
  }

  // Método para poner en cuarentena un archivo sospechoso
  Future<bool> quarantineFile(String filePath) async {
    try {
      final file = File(filePath);
      final quarantineDir = await _getQuarantineDir();
      final fileName = filePath.split('/').last;
      final quarantinePath = '${quarantineDir.path}/$fileName.quarantine';

      // "Cuarentena" simple - renombrar y mover
      await file.copy(quarantinePath);
      await file.delete();

      return true;
    } catch (e) {
      debugPrint('Error al poner en cuarentena: $e');
      return false;
    }
  }

  // Obtiene el directorio de cuarentena
  Future<Directory> _getQuarantineDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final quarantineDir = Directory('${appDir.path}/quarantine');

    if (!await quarantineDir.exists()) {
      await quarantineDir.create(recursive: true);
    }

    return quarantineDir;
  }
}
