import 'package:flutter/material.dart';

import '../models/app_info.dart';
import '../services/app_scanner_service.dart';

class AppScannerScreen extends StatefulWidget {
  const AppScannerScreen({super.key});

  @override
  State<AppScannerScreen> createState() => _AppScannerScreenState();
}

class _AppScannerScreenState extends State<AppScannerScreen> {
  final AppScannerService _scannerService = AppScannerService();
  bool _isLoading = false;
  List<AppInfo> _appsList = [];

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apps = await _scannerService.getInstalledApps();
      setState(() {
        _appsList = apps;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar aplicaciones: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner de Aplicaciones'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadApps),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Escaneando aplicaciones...'),
                  ],
                ),
              )
              : Column(
                children: [
                  // Estadísticas resumen
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              context,
                              'Total',
                              _appsList.length.toString(),
                              Colors.blue,
                            ),
                            _buildStatColumn(
                              context,
                              'Alto Riesgo',
                              _appsList
                                  .where((app) => app.riskScore >= 7.0)
                                  .length
                                  .toString(),
                              Colors.red,
                            ),
                            _buildStatColumn(
                              context,
                              'Riesgo Medio',
                              _appsList
                                  .where(
                                    (app) =>
                                        app.riskScore >= 3.0 &&
                                        app.riskScore < 7.0,
                                  )
                                  .length
                                  .toString(),
                              Colors.amber,
                            ),
                            _buildStatColumn(
                              context,
                              'Seguras',
                              _appsList
                                  .where((app) => app.riskScore < 3.0)
                                  .length
                                  .toString(),
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Filtro
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar aplicaciones',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                      onChanged: (value) {
                        // Implementar búsqueda
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Lista de aplicaciones
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _appsList.length,
                      itemBuilder: (context, index) {
                        final app = _appsList[index];
                        return AppItem(app: app);
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
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

class AppItem extends StatelessWidget {
  final AppInfo app;

  const AppItem({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(app.riskColor).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.android, color: Color(app.riskColor), size: 30),
        ),
        title: Text(
          app.appName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.packageName),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Color(app.riskColor).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Riesgo: ${app.riskLevel}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(app.riskColor),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            // Mostrar detalles de la app
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AppDetailsSheet(app: app),
            );
          },
        ),
      ),
    );
  }
}

class AppDetailsSheet extends StatelessWidget {
  final AppInfo app;

  const AppDetailsSheet({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // App header
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(app.riskColor).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.android,
                      color: Color(app.riskColor),
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.appName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          app.packageName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Risk level
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(app.riskColor).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      app.riskScore >= 7.0
                          ? Icons.warning
                          : app.riskScore >= 3.0
                          ? Icons.info
                          : Icons.check_circle,
                      color: Color(app.riskColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nivel de riesgo: ${app.riskLevel}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(app.riskColor),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            app.riskScore >= 7.0
                                ? 'Esta aplicación representa un riesgo alto para su privacidad y seguridad.'
                                : app.riskScore >= 3.0
                                ? 'Esta aplicación tiene algunos permisos que podrían comprometer su privacidad.'
                                : 'Esta aplicación parece segura para usar.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // App details
              const Text(
                'Detalles de la aplicación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDetailItem('Versión', app.versionName),
                    _buildDetailItem(
                      'Es aplicación de sistema',
                      app.isSystemApp ? 'Sí' : 'No',
                    ),
                    _buildDetailItem(
                      'Fecha de instalación',
                      _formatDate(app.installTime),
                    ),
                    _buildDetailItem(
                      'Última actualización',
                      _formatDate(app.updateTime),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Permisos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...app.permissions.map(
                      (perm) => _buildPermissionItem(perm),
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Acción para desinstalar/deshabilitar
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Desinstalar aplicación'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String permission) {
    // Simplificar nombre del permiso
    final simplifiedName = permission.split('.').last;

    // Determinar si el permiso es sensible
    final isSensitive =
        permission.contains('LOCATION') ||
        permission.contains('CAMERA') ||
        permission.contains('CONTACTS') ||
        permission.contains('RECORD_AUDIO') ||
        permission.contains('SMS') ||
        permission.contains('CALL');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isSensitive ? Icons.warning : Icons.check,
            color: isSensitive ? Colors.amber : Colors.green,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              simplifiedName,
              style: TextStyle(color: isSensitive ? Colors.amber[700] : null),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
