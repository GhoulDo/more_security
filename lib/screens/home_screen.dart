import 'package:flutter/material.dart';
import 'package:more_security/providers/app_state_provider.dart';
import 'package:more_security/utils/permission_handler.dart';
import 'package:more_security/widgets/complete_scan_widget.dart';
import 'package:more_security/widgets/security_card.dart';
import 'package:more_security/widgets/security_status.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _requestingPermissions = false;

  @override
  void initState() {
    super.initState();
    // Solicitar permisos cuando la pantalla se inicia
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _requestingPermissions = true;
    });

    final permissionsGranted =
        await AppPermissionHandler.checkAndRequestBasicPermissions(context);

    setState(() {
      _requestingPermissions = false;
    });

    if (!permissionsGranted && mounted) {
      _showPermissionsNeededDialog();
    }
  }

  void _showPermissionsNeededDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Atención'),
          content: const Text(
            'Para proteger completamente su dispositivo, More Security necesita acceso a archivos y aplicaciones.\n\n'
            'Puede conceder estos permisos en cualquier momento desde el botón "Verificar permisos".',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Entendido'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Conceder ahora'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: 32, height: 32),
            const SizedBox(width: 8),
            const Text(
              'More Security',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
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
      body:
          _requestingPermissions
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.security, size: 80, color: Colors.purple),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Solicitando permisos necesarios...'),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estado de seguridad
                      Consumer<AppStateProvider>(
                        builder: (context, provider, child) {
                          return SecurityStatus(
                            securityLevel: provider.securityScore,
                          );
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
                      Row(
                        children: [
                          Image.asset(
                            'assets/icons/shield_check.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Protección del dispositivo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Tarjetas de seguridad usando IconData en lugar de rutas de assets
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
                        icon: Icons.warning,
                        color: Colors.amber,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/vulnerability_scanner',
                          );
                        },
                      ),

                      SecurityCard(
                        title: 'Escanear Archivos',
                        description:
                            'Analiza archivos para detectar malware y virus',
                        icon: Icons.folder,
                        color: Colors.green,
                        onTap: () {
                          Navigator.pushNamed(context, '/file_scanner');
                        },
                      ),

                      // Botón de pedir permisos explícitamente
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            openAppSettings();
                          },
                          icon: const Icon(Icons.settings_applications),
                          label: const Text('Verificar permisos'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
