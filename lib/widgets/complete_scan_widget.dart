import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:more_security/providers/app_state_provider.dart';
import 'package:more_security/services/complete_scan_service.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

class CompleteScanWidget extends StatefulWidget {
  const CompleteScanWidget({super.key});

  @override
  State<CompleteScanWidget> createState() => _CompleteScanWidgetState();
}

class _CompleteScanWidgetState extends State<CompleteScanWidget>
    with SingleTickerProviderStateMixin {
  final CompleteScanService _scanService = CompleteScanService();
  bool _isScanning = false;
  ScanProgress? _currentProgress;
  CompleteScanResult? _result;
  late AnimationController _animationController;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scanService.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _showResults = false;
      _result = null;
    });

    try {
      // Escuchar el progreso del escaneo
      _scanService.progressStream.listen((progress) {
        setState(() {
          _currentProgress = progress;
        });

        if (progress.stage == ScanStage.complete) {
          _animationController.forward();
        }
      });

      // Iniciar el escaneo
      final result = await _scanService.startCompleteScan();

      setState(() {
        _result = result;
        _isScanning = false;

        // Actualizar el proveedor de estado con los nuevos resultados
        final provider = Provider.of<AppStateProvider>(context, listen: false);
        provider.updateSecurityScore(result.overallSecurityScore);
        provider.updateLastScanResults('complete', result.statistics);
      });

      // Mostrar resultados después de la animación
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) {
          setState(() {
            _showResults = true;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al escanear: $e')));
    }
  }

  String _getScanStageText(ScanStage stage) {
    switch (stage) {
      case ScanStage.initializing:
        return 'Iniciando';
      case ScanStage.scanningApps:
        return 'Escaneando aplicaciones';
      case ScanStage.scanningVulnerabilities:
        return 'Verificando vulnerabilidades';
      case ScanStage.scanningFiles:
        return 'Analizando archivos';
      case ScanStage.finishing:
        return 'Finalizando';
      case ScanStage.complete:
        return '¡Completado!';
      case ScanStage.error:
        return 'Error';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF06D6A0); // Verde
    if (score >= 60) return const Color(0xFF90BE6D); // Verde claro
    if (score >= 40) return const Color(0xFFFFB703); // Amarillo
    if (score >= 20) return const Color(0xFFF8961E); // Naranja
    return const Color(0xFFE63946); // Rojo
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isScanning || (_result != null && !_showResults)) ...[
          // Indicador de progreso y animación
          CircularPercentIndicator(
            radius: 70.0,
            lineWidth: 12.0,
            percent: _currentProgress?.progress ?? 0,
            center:
                _currentProgress?.stage == ScanStage.complete
                    ? AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + _animationController.value * 0.3,
                          child: Opacity(
                            opacity: _animationController.value,
                            child: Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    )
                    : Text(
                      '${((_currentProgress?.progress ?? 0) * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            progressColor: Theme.of(context).primaryColor,
            backgroundColor: Colors.grey[300]!,
            animateFromLastPercent: true,
            animation: true,
          ),

          const SizedBox(height: 16),

          Text(
            _getScanStageText(
              _currentProgress?.stage ?? ScanStage.initializing,
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            _currentProgress?.message ?? 'Preparando escaneo...',
            textAlign: TextAlign.center,
          ),

          if (_currentProgress?.stage == ScanStage.complete)
            Lottie.asset(
              'assets/animations/complete.json',
              width: 200,
              height: 200,
              repeat: false,
              controller: _animationController,
            ),
        ],

        if (!_isScanning && _result == null) ...[
          // Estado inicial - Botón para iniciar escaneo
          Lottie.asset(
            'assets/animations/security_check.json',
            width: 200,
            height: 200,
          ),

          const SizedBox(height: 16),

          const Text(
            'Escaneo Completo',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Analice su dispositivo en busca de aplicaciones maliciosas, vulnerabilidades y archivos sospechosos.',
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _startScan,
            icon: const Icon(Icons.security),
            label: const Text('Iniciar Escaneo Completo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],

        if (!_isScanning && _result != null && _showResults) ...[
          // Resultados del escaneo
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularPercentIndicator(
                    radius: 60.0,
                    lineWidth: 10.0,
                    percent: _result!.overallSecurityScore / 100,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_result!.overallSecurityScore}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(
                              _result!.overallSecurityScore,
                            ),
                          ),
                        ),
                        const Text('puntos', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    progressColor: _getScoreColor(
                      _result!.overallSecurityScore,
                    ),
                    backgroundColor: Colors.grey[300]!,
                    animation: true,
                    animationDuration: 1500,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _result!.overallSecurityScore >= 80
                        ? 'Tu dispositivo está seguro'
                        : _result!.overallSecurityScore >= 60
                        ? 'Tu dispositivo está bastante seguro'
                        : _result!.overallSecurityScore >= 40
                        ? 'Tu dispositivo necesita atención'
                        : 'Tu dispositivo está en riesgo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(_result!.overallSecurityScore),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Resultados del escaneo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 16),

                  _buildStatRow(
                    Icons.apps,
                    'Aplicaciones de alto riesgo',
                    '${_result!.statistics['highRiskApps']}/${_result!.statistics['appsScanned']}',
                    _result!.statistics['highRiskApps'] > 0
                        ? Colors.orange
                        : Colors.green,
                  ),

                  const SizedBox(height: 8),

                  _buildStatRow(
                    Icons.warning,
                    'Vulnerabilidades críticas',
                    '${_result!.statistics['criticalVulnerabilities']}',
                    _result!.statistics['criticalVulnerabilities'] > 0
                        ? Colors.red
                        : Colors.green,
                  ),

                  const SizedBox(height: 8),

                  _buildStatRow(
                    Icons.description,
                    'Archivos maliciosos',
                    '${_result!.statistics['maliciousFiles']}/${_result!.statistics['filesScanned']}',
                    _result!.statistics['maliciousFiles'] > 0
                        ? Colors.red
                        : Colors.green,
                  ),

                  const SizedBox(height: 8),

                  _buildStatRow(
                    Icons.timer,
                    'Duración del escaneo',
                    '${_result!.statistics['scanDuration']} seg',
                    Colors.blue,
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _startScan,
                          child: const Text('Repetir escaneo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Navegar a la pantalla de resultados detallados
                            // Navigator.pushNamed(context, '/scan_details', arguments: _result);
                          },
                          child: const Text('Ver detalles'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String title, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
