import 'package:flutter/material.dart';

import '../models/scanned_file.dart';
import '../services/file_scanner_service.dart';
import '../utils/permission_handler.dart';

class FileScannerScreen extends StatefulWidget {
  const FileScannerScreen({super.key});

  @override
  State<FileScannerScreen> createState() => _FileScannerScreenState();
}

class _FileScannerScreenState extends State<FileScannerScreen> {
  final FileScannerService _scannerService = FileScannerService();
  bool _isScanning = false;
  bool _hasScanned = false;
  List<ScannedFile> _scannedFiles = [];

  Future<void> _startScan() async {
    // Verificar permisos primero
    final permissionsGranted =
        await AppPermissionHandler.checkAndRequestBasicPermissions(context);
    if (!permissionsGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se requieren permisos para escanear archivos'),
          ),
        );
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _scannedFiles = [];
    });

    try {
      final results = await _scannerService.scanFiles();
      setState(() {
        _scannedFiles = results;
        _hasScanned = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al escanear archivos: $e')));
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _deleteFile(String filePath) async {
    try {
      final success = await _scannerService.deleteFile(filePath);

      if (success) {
        setState(() {
          _scannedFiles.removeWhere((file) => file.filePath == filePath);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo eliminado correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el archivo')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el archivo: $e')),
      );
    }
  }

  Future<void> _quarantineFile(String filePath) async {
    try {
      final success = await _scannerService.quarantineFile(filePath);

      if (success) {
        setState(() {
          final index = _scannedFiles.indexWhere(
            (file) => file.filePath == filePath,
          );
          if (index >= 0) {
            // Actualizar el estado del archivo para indicar que está en cuarentena
            // En una implementación real, probablemente tendríamos un campo "isQuarantined"
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo puesto en cuarentena')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo poner el archivo en cuarentena'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al poner el archivo en cuarentena: $e')),
      );
    }
  }

  String _formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icons/file.png',
              width: 24,
              height: 24,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            const Text('Escáner de Archivos'),
          ],
        ),
      ),
      body:
          _isScanning
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/malware_detection.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Escaneando archivos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buscando archivos maliciosos y peligrosos...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : !_hasScanned
              ? _buildInitialView()
              : _buildResultsView(),
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/malware_detection.png',
            width: 140,
            height: 140,
          ),
          const SizedBox(height: 24),
          const Text(
            'Escáner de Archivos',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Busca archivos peligrosos y malware en tu dispositivo para mantenerlo seguro.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _startScan,
            icon: Image.asset(
              'assets/icons/scan.png',
              width: 24,
              height: 24,
              color: Colors.white,
            ),
            label: const Text('Iniciar escaneo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    // Agrupar por nivel de riesgo
    final maliciousFiles =
        _scannedFiles
            .where((file) => file.riskLevel == FileRiskLevel.malicious)
            .toList();
    final suspiciousFiles =
        _scannedFiles
            .where((file) => file.riskLevel == FileRiskLevel.suspicious)
            .toList();
    final safeFiles =
        _scannedFiles
            .where((file) => file.riskLevel == FileRiskLevel.safe)
            .toList();
    final unknownFiles =
        _scannedFiles
            .where((file) => file.riskLevel == FileRiskLevel.unknown)
            .toList();

    return Column(
      children: [
        // Resumen
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen del escaneo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        'Total',
                        _scannedFiles.length.toString(),
                        Colors.blue,
                      ),
                      _buildStatColumn(
                        'Malicioso',
                        maliciousFiles.length.toString(),
                        Colors.red,
                      ),
                      _buildStatColumn(
                        'Sospechoso',
                        suspiciousFiles.length.toString(),
                        Colors.orange,
                      ),
                      _buildStatColumn(
                        'Seguro',
                        safeFiles.length.toString(),
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Lista de archivos
        Expanded(
          child: DefaultTabController(
            length: 4,
            child: Column(
              children: [
                Material(
                  color: Theme.of(context).cardColor,
                  child: TabBar(
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: "Malicioso (${maliciousFiles.length})"),
                      Tab(text: "Sospechoso (${suspiciousFiles.length})"),
                      Tab(text: "Seguro (${safeFiles.length})"),
                      Tab(text: "Desconocido (${unknownFiles.length})"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab de archivos maliciosos
                      _buildFilesList(maliciousFiles, true),

                      // Tab de archivos sospechosos
                      _buildFilesList(suspiciousFiles, true),

                      // Tab de archivos seguros
                      _buildFilesList(safeFiles, false),

                      // Tab de archivos desconocidos
                      _buildFilesList(unknownFiles, false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilesList(List<ScannedFile> files, bool showActions) {
    if (files.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron archivos en esta categoría',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: files.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final file = files[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(file.riskColor).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                file.riskLevel == FileRiskLevel.malicious
                    ? 'assets/icons/malware.png'
                    : file.riskLevel == FileRiskLevel.suspicious
                    ? 'assets/icons/warning.png'
                    : file.riskLevel == FileRiskLevel.safe
                    ? 'assets/icons/safe.png'
                    : 'assets/icons/file.png',
                color: Color(file.riskColor),
                width: 30,
                height: 30,
              ),
            ),
            title: Text(
              file.fileName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatFileSize(file.fileSize)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Color(file.riskColor).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getRiskLevelText(file.riskLevel),
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(file.riskColor),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (file.detectionName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Detección: ${file.detectionName}',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteFile(file.filePath),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Eliminar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _quarantineFile(file.filePath),
                          icon: const Icon(Icons.shield, size: 16),
                          label: const Text('Cuarentena'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            onTap: () {
              // Mostrar detalles del archivo
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text(file.fileName),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Ubicación'),
                              subtitle: Text(file.filePath),
                              dense: true,
                            ),
                            ListTile(
                              title: const Text('Tamaño'),
                              subtitle: Text(_formatFileSize(file.fileSize)),
                              dense: true,
                            ),
                            ListTile(
                              title: const Text('Última modificación'),
                              subtitle: Text(_formatDate(file.lastModified)),
                              dense: true,
                            ),
                            ListTile(
                              title: const Text('Nivel de riesgo'),
                              subtitle: Text(_getRiskLevelText(file.riskLevel)),
                              dense: true,
                            ),
                            const Divider(),
                            const Text(
                              'Detalles del análisis:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...file.reasons.map(
                              (reason) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• '),
                                    Expanded(child: Text(reason)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                        if (showActions) ...[
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteFile(file.filePath);
                            },
                            child: const Text('Eliminar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _quarantineFile(file.filePath);
                            },
                            child: const Text('Cuarentena'),
                          ),
                        ],
                      ],
                    ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getIconForFileType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'apk':
        return Icons.android;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getRiskLevelText(FileRiskLevel riskLevel) {
    switch (riskLevel) {
      case FileRiskLevel.safe:
        return 'Seguro';
      case FileRiskLevel.suspicious:
        return 'Sospechoso';
      case FileRiskLevel.malicious:
        return 'Malicioso';
      case FileRiskLevel.unknown:
        return 'Desconocido';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
