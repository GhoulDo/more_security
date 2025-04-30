import 'package:flutter/material.dart';
import 'package:more_security/providers/app_state_provider.dart';
import 'package:more_security/widgets/complete_scan_widget.dart';
import 'package:more_security/widgets/security_card.dart';
import 'package:more_security/widgets/security_status.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'More Security',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navegar a la pantalla de configuración
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado de seguridad
              Consumer<AppStateProvider>(
                builder: (context, provider, child) {
                  return SecurityStatus(securityLevel: provider.securityScore);
                },
              ),

              const SizedBox(height: 20),

              // Tarjeta de escaneo completo
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CompleteScanWidget(),
                ),
              ),

              const SizedBox(height: 20),

              // Encabezado de secciones
              const Text(
                'Protección del dispositivo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              // Tarjetas de seguridad
              SecurityCard(
                title: 'Escanear Aplicaciones',
                description:
                    'Analiza las aplicaciones instaladas para detectar posibles amenazas',
                icon: Icons.apps,
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  Navigator.pushNamed(context, '/app_scanner');
                },
              ),

              SecurityCard(
                title: 'Vulnerabilidades',
                description:
                    'Busca vulnerabilidades en el sistema y aplicaciones',
                icon: Icons.security,
                color: Colors.amber,
                onTap: () {
                  Navigator.pushNamed(context, '/vulnerability_scanner');
                },
              ),

              SecurityCard(
                title: 'Escanear Archivos',
                description: 'Analiza archivos para detectar malware y virus',
                icon: Icons.folder,
                color: Colors.green,
                onTap: () {
                  Navigator.pushNamed(context, '/file_scanner');
                },
              ),

              const SizedBox(height: 20),

              // Estadísticas resumen
              const Text(
                'Estadísticas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildStatItem(
                        context,
                        Icons.apps_outlined,
                        'Aplicaciones analizadas',
                        '24',
                      ),
                      const Divider(),
                      _buildStatItem(
                        context,
                        Icons.warning_amber,
                        'Vulnerabilidades detectadas',
                        '3',
                      ),
                      const Divider(),
                      _buildStatItem(
                        context,
                        Icons.description,
                        'Archivos escaneados',
                        '156',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Último análisis
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Último escaneo completo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Hace 2 días'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Iniciar un escaneo completo
                          },
                          child: const Text('Iniciar escaneo completo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
